import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class HealthApiService {
  final String baseUrl;
  final Duration timeout;

  HealthApiService({
    this.baseUrl = 'http://localhost:8000',
    this.timeout = const Duration(seconds: 10),
  });

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
