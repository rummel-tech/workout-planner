import 'dart:async';
import 'package:collection/collection.dart';
import 'healthkit_bridge.dart';
import 'health_api_service.dart';

/// HealthSyncManager gathers HealthKit samples, transforms them to the backend schema,
/// batches them, and ingests via HealthApiService.
class HealthSyncManager {
  final String userId;
  final HealthApiService api;
  final int batchSize;

  HealthSyncManager({
    required this.userId,
    HealthApiService? api,
    this.batchSize = 100,
  }) : api = api ?? HealthApiService();

  /// Fetch all supported sample categories currently exposed by the bridge.
  Future<Map<String, dynamic>> fetchAllRaw() async {
    final workouts = await HealthKitBridge.fetchWorkouts();
    final hr = await HealthKitBridge.fetchHeartRate();
    final hrv = await HealthKitBridge.fetchHRV();
    final resting = await HealthKitBridge.fetchRestingHeartRate();
    final sleep = await HealthKitBridge.fetchSleep();
    return {
      'workouts': workouts,
      'heart_rate': hr,
      'hrv': hrv,
      'resting_hr': resting,
      'sleep': sleep,
    };
  }

  /// Transform raw fetched data into backend `health_samples` compatible rows.
  List<Map<String, dynamic>> transform(Map<String, dynamic> raw) {
    final List<Map<String, dynamic>> samples = [];

    // Workouts: produce distance & calories samples if > 0
    for (final w in (raw['workouts'] as List<dynamic>)) {
      final distance = (w['distance'] ?? 0).toDouble();
      final calories = (w['calories'] ?? 0).toDouble();
      final start = _toIso(w['start']);
      final end = _toIso(w['end']);
      final source = 'apple.health';
      final uuid = w['uuid'];
      if (distance > 0) {
        samples.add({
          'user_id': userId,
          'sample_type': 'workout_distance',
          'value': distance,
          'unit': 'm',
          'start_time': start,
          'end_time': end,
          'source_app': source,
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
          'source_app': source,
          'source_uuid': uuid,
        });
      }
    }

    // Heart Rate samples
    for (final hr in (raw['heart_rate'] as List<dynamic>)) {
      final uuid = hr['uuid'];
      samples.add({
        'user_id': userId,
        'sample_type': 'heart_rate',
        'value': (hr['value'] ?? 0).toDouble(),
        'unit': 'bpm',
        'start_time': _toIso(hr['start']),
        'end_time': _toIso(hr['end']),
        'source_app': hr['source'] ?? 'apple.health',
        'source_uuid': uuid,
      });
    }

    // HRV samples
    for (final s in (raw['hrv'] as List<dynamic>)) {
      final uuid = s['uuid'];
      samples.add({
        'user_id': userId,
        'sample_type': 'hrv',
        'value': (s['value'] ?? 0).toDouble(),
        'unit': 'ms',
        'start_time': _toIso(s['start']),
        'end_time': _toIso(s['end']),
        'source_app': s['source'] ?? 'apple.health',
        'source_uuid': uuid,
      });
    }

    // Resting HR samples
    for (final r in (raw['resting_hr'] as List<dynamic>)) {
      final uuid = r['uuid'];
      samples.add({
        'user_id': userId,
        'sample_type': 'resting_hr',
        'value': (r['value'] ?? 0).toDouble(),
        'unit': 'bpm',
        'start_time': _toIso(r['start']),
        'end_time': _toIso(r['end']),
        'source_app': r['source'] ?? 'apple.health',
        'source_uuid': uuid,
      });
    }

    // Sleep samples (value raw category int)
    for (final sl in (raw['sleep'] as List<dynamic>)) {
      final uuid = sl['uuid'];
      samples.add({
        'user_id': userId,
        'sample_type': 'sleep_stage',
        'value': (sl['value'] ?? 0).toDouble(),
        'unit': 'code',
        'start_time': _toIso(sl['start']),
        'end_time': _toIso(sl['end']),
        'source_app': sl['source'] ?? 'apple.health',
        'source_uuid': uuid,
      });
    }

    return samples;
  }

  /// Perform full sync: fetch raw, transform, chunk, and ingest.
  Future<HealthSyncResult> sync() async {
    final raw = await fetchAllRaw();
    final transformed = transform(raw);
    int inserted = 0;
    final errors = <String>[];
    for (final chunk in transformed.slices(batchSize)) {
      try {
        final count = await api.ingestSamples(chunk);
        inserted += count;
      } catch (e) {
        errors.add('Chunk failed: $e');
      }
    }
    return HealthSyncResult(
      totalSamples: transformed.length,
      inserted: inserted,
      errors: errors,
    );
  }

  String _toIso(dynamic epochSeconds) {
    if (epochSeconds is num) {
      return DateTime.fromMillisecondsSinceEpoch((epochSeconds * 1000).round(), isUtc: true)
          .toIso8601String();
    }
    return DateTime.now().toUtc().toIso8601String();
  }
}

class HealthSyncResult {
  final int totalSamples;
  final int inserted;
  final List<String> errors;
  bool get success => errors.isEmpty;
  const HealthSyncResult({
    required this.totalSamples,
    required this.inserted,
    required this.errors,
  });
}
