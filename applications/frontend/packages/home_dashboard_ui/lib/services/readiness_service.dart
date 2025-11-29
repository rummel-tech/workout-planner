import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ReadinessService {
  final String baseUrl;
  final Duration timeout;
  ReadinessService({this.baseUrl = 'http://localhost:8000', this.timeout = const Duration(seconds: 10)});

  Future<Map<String, dynamic>> fetch(String userId) async {
    final uri = Uri.parse('$baseUrl/readiness').replace(queryParameters: {'user_id': userId});
    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      throw Exception('Readiness ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Readiness request timed out');
    }
  }
}