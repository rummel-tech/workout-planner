import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:home_dashboard_ui/services/api_config.dart';
import '../models/strength_metrics.dart';
import '../models/swim_metrics.dart';

export '../models/strength_metrics.dart';
export '../models/swim_metrics.dart';

/// API service for logging strength and swim metrics.
class MetricsApiService {
  final String baseUrl;
  final Duration timeout;

  MetricsApiService({
    String? baseUrl,
    Duration? timeout,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        timeout = timeout ?? ApiConfig.defaultTimeout;

  // ============ STRENGTH METRICS ============

  /// Log a strength training set
  Future<StrengthMetrics> logStrengthSet(StrengthMetrics metrics) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/strength'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(metrics.toJson()),
      ).timeout(timeout);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return StrengthMetrics.fromJson(json.decode(resp.body));
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  /// Get strength metrics for a user
  Future<List<StrengthMetrics>> getStrengthMetrics(
    String userId, {
    String? lift,
    int limit = 50,
  }) async {
    final params = {
      'user_id': userId,
      if (lift != null) 'lift': lift,
      'limit': limit.toString(),
    };
    final uri = Uri.parse('$baseUrl/strength').replace(queryParameters: params);

    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        return data.map((json) => StrengthMetrics.fromJson(json)).toList();
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  /// Get progress for a specific lift
  Future<List<StrengthMetrics>> getStrengthProgress(
    String userId,
    String lift, {
    int days = 90,
  }) async {
    final uri = Uri.parse('$baseUrl/strength/progress/$lift').replace(
      queryParameters: {
        'user_id': userId,
        'days': days.toString(),
      },
    );

    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        return data.map((json) => StrengthMetrics.fromJson(json)).toList();
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  // ============ SWIM METRICS ============

  /// Log a swim workout
  Future<SwimMetrics> logSwim(SwimMetrics metrics) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/swim'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(metrics.toJson()),
      ).timeout(timeout);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return SwimMetrics.fromJson(json.decode(resp.body));
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  /// Get swim metrics for a user
  Future<List<SwimMetrics>> getSwimMetrics(
    String userId, {
    int limit = 50,
  }) async {
    final params = {
      'user_id': userId,
      'limit': limit.toString(),
    };
    final uri = Uri.parse('$baseUrl/swim').replace(queryParameters: params);

    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        return data.map((json) => SwimMetrics.fromJson(json)).toList();
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  /// Get swim trends
  Future<Map<String, dynamic>> getSwimTrends(
    String userId, {
    int days = 90,
  }) async {
    final uri = Uri.parse('$baseUrl/swim/trends').replace(
      queryParameters: {
        'user_id': userId,
        'days': days.toString(),
      },
    );

    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      throw Exception('Server ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Backend unreachable');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }
}
