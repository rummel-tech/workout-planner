import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class HealthService {
  final String baseUrl;
  final Duration timeout;
  HealthService({this.baseUrl = 'http://localhost:8000', this.timeout = const Duration(seconds: 10)});

  Future<Map<String, dynamic>> summary(String userId, {int days = 30}) async {
    final uri = Uri.parse('$baseUrl/health/summary').replace(queryParameters: {
      'user_id': userId,
      'days': days.toString(),
    });
    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      throw Exception('Summary ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Summary timed out');
    }
  }

  Future<List<Map<String, dynamic>>> listSamples(String userId, String sampleType, {int limit = 500}) async {
    final uri = Uri.parse('$baseUrl/health/samples').replace(queryParameters: {
      'user_id': userId,
      'sample_type': sampleType,
      'limit': limit.toString(),
    });
    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      throw Exception('Samples ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Samples timed out');
    }
  }
}