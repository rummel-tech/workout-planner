import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class HealthSyncResult {
  final int inserted;
  final int total;
  final List<String> errors;
  bool get success => errors.isEmpty;
  const HealthSyncResult({required this.inserted, required this.total, required this.errors});
}

class HealthSync {
  final String userId;
  final String baseUrl;
  final int batchSize;
  HealthSync({required this.userId, this.baseUrl = 'http://localhost:8000', this.batchSize = 100});

  Future<bool> ensurePermissions() async {
    try {
      final channel = MethodChannel('healthkit_bridge');
      final granted = await channel.invokeMethod('requestPermissions');
      return granted == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchList(String method) async {
    final channel = MethodChannel('healthkit_bridge');
    final result = await channel.invokeMethod(method);
    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    return [];
  }

  String _iso(num seconds) => DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round(), isUtc: true).toIso8601String();

  List<Map<String, dynamic>> _transform({
    required List<Map<String, dynamic>> workouts,
    required List<Map<String, dynamic>> heartRate,
    required List<Map<String, dynamic>> hrv,
    required List<Map<String, dynamic>> restingHr,
    required List<Map<String, dynamic>> sleep,
  }) {
    final samples = <Map<String, dynamic>>[];
    for (final w in workouts) {
      final start = _iso((w['start'] ?? 0) as num);
      final end = _iso((w['end'] ?? 0) as num);
      final uuid = w['uuid'];
      final distance = (w['distance'] ?? 0).toDouble();
      final calories = (w['calories'] ?? 0).toDouble();
      if (distance > 0) {
        samples.add({
          'user_id': userId,
          'sample_type': 'workout_distance',
          'value': distance,
          'unit': 'm',
          'start_time': start,
          'end_time': end,
          'source_app': 'apple.health',
          'source_uuid': uuid,
        });
      }
      if (calories > 0) {
        samples.add({
          'user_id': userId,
          'sample_type': 'workout_calories',
          'value': calories,
          'unit': 'kcal',
          'start_time': start,
          'end_time': end,
          'source_app': 'apple.health',
          'source_uuid': uuid,
        });
      }
    }
    for (final hr in heartRate) {
      samples.add({
        'user_id': userId,
        'sample_type': 'heart_rate',
        'value': (hr['value'] ?? 0).toDouble(),
        'unit': 'bpm',
        'start_time': _iso((hr['start'] ?? 0) as num),
        'end_time': _iso((hr['end'] ?? 0) as num),
        'source_app': hr['source'] ?? 'apple.health',
        'source_uuid': hr['uuid'],
      });
    }
    for (final s in hrv) {
      samples.add({
        'user_id': userId,
        'sample_type': 'hrv',
        'value': (s['value'] ?? 0).toDouble(),
        'unit': 'ms',
        'start_time': _iso((s['start'] ?? 0) as num),
        'end_time': _iso((s['end'] ?? 0) as num),
        'source_app': s['source'] ?? 'apple.health',
        'source_uuid': s['uuid'],
      });
    }
    for (final r in restingHr) {
      samples.add({
        'user_id': userId,
        'sample_type': 'resting_hr',
        'value': (r['value'] ?? 0).toDouble(),
        'unit': 'bpm',
        'start_time': _iso((r['start'] ?? 0) as num),
        'end_time': _iso((r['end'] ?? 0) as num),
        'source_app': r['source'] ?? 'apple.health',
        'source_uuid': r['uuid'],
      });
    }
    for (final sl in sleep) {
      samples.add({
        'user_id': userId,
        'sample_type': 'sleep_stage',
        'value': (sl['value'] ?? 0).toDouble(),
        'unit': 'code',
        'start_time': _iso((sl['start'] ?? 0) as num),
        'end_time': _iso((sl['end'] ?? 0) as num),
        'source_app': sl['source'] ?? 'apple.health',
        'source_uuid': sl['uuid'],
      });
    }
    return samples;
  }

  Future<int> _ingestChunk(List<Map<String, dynamic>> chunk) async {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$baseUrl/health/samples'));
    final body = json.encode({'samples': chunk});
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(body));
    final response = await request.close();
    final respBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      final data = json.decode(respBody);
      final inserted = data['inserted'];
      if (inserted is int) return inserted;
      if (inserted is num) return inserted.toInt();
      return chunk.length;
    }
    throw Exception('Ingest failed ${response.statusCode}: $respBody');
  }

  Future<HealthSyncResult> perform() async {
    // Skip HealthKit permission gating on non-iOS platforms (e.g., Android/web/dev env)
    bool granted = true;
    if (Platform.isIOS) {
      granted = await ensurePermissions();
      if (!granted) {
        return const HealthSyncResult(inserted: 0, total: 0, errors: ['HealthKit permissions denied']);
      }
    }
    try {
      final workouts = await _fetchList('fetchWorkouts');
      final heartRate = await _fetchList('fetchHeartRate');
      final hrv = await _fetchList('fetchHRV');
      final resting = await _fetchList('fetchRestingHeartRate');
      final sleep = await _fetchList('fetchSleep');
      final samples = _transform(
          workouts: workouts,
          heartRate: heartRate,
          hrv: hrv,
          restingHr: resting,
          sleep: sleep);
      int inserted = 0;
      final errors = <String>[];
      for (var i = 0; i < samples.length; i += batchSize) {
        final chunk = samples.sublist(i, i + batchSize > samples.length ? samples.length : i + batchSize);
        try {
          inserted += await _ingestChunk(chunk);
        } catch (e) {
          errors.add(e.toString());
        }
      }
      return HealthSyncResult(inserted: inserted, total: samples.length, errors: errors);
    } catch (e) {
      return HealthSyncResult(inserted: 0, total: 0, errors: [e.toString()]);
    }
  }
}