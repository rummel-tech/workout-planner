import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:home_dashboard_ui/services/api_config.dart';
import '../models/health_sample.dart';

export '../models/health_sample.dart';

class HealthApiService {
  final String baseUrl;
  final Duration timeout;

  HealthApiService({
    String? baseUrl,
    Duration? timeout,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl,
       timeout = timeout ?? ApiConfig.defaultTimeout;

  /// Ingest typed HealthSample objects
  Future<int> ingestSamplesTyped(List<HealthSample> samples) async {
    return ingestSamples(samples.map((s) => s.toIngestJson()).toList());
  }

  /// Ingest raw sample maps (backward compatibility)
  Future<int> ingestSamples(List<Map<String, dynamic>> samples) async {
    if (samples.isEmpty) return 0;
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/health/samples'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'samples': samples}),
      ).timeout(timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final inserted = data['inserted'];
        if (inserted is int) return inserted;
        if (inserted is num) return inserted.toInt();
        return samples.length;
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Ingestion timed out');
    }
  }

  /// List health samples as typed HealthSample objects
  Future<List<HealthSample>> listSamplesTyped(String userId, {String? sampleType, int limit = 100}) async {
    final rawSamples = await listSamples(userId, sampleType: sampleType, limit: limit);
    return rawSamples.map((json) => HealthSample.fromJson(json)).toList();
  }

  /// List health samples as raw maps (backward compatibility)
  Future<List<Map<String, dynamic>>> listSamples(String userId, {String? sampleType, int limit = 100}) async {
    final params = {
      'user_id': userId,
      if (sampleType != null) 'sample_type': sampleType,
      'limit': limit.toString(),
    };
    final uri = Uri.parse('$baseUrl/health/samples').replace(queryParameters: params);
    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        return List<Map<String, dynamic>>.from(decoded);
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Fetch timed out');
    }
  }

  Future<Map<String, dynamic>> summary(String userId, {int days = 7}) async {
    final uri = Uri.parse('$baseUrl/health/summary').replace(queryParameters: {
      'user_id': userId,
      'days': days.toString(),
    });
    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Summary timed out');
    }
  }
}
