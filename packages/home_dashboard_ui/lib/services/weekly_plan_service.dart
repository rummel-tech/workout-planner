import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';
import 'api_config.dart';
import '../utils/week_ordering.dart';

class WeeklyPlanService {
  static const _keyPrefix = 'weekly_plan_';
  String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>?> load(String userId) async {
    Map<String, dynamic>? plan;

    // Try backend first
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/weekly-plans/$userId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        plan = json.decode(response.body) as Map<String, dynamic>;
        // Cache locally
        await _saveLocal(userId, plan);
      }
    } catch (e) {
      // Backend unavailable, fall through to local cache
    }

    // Fallback to local storage if backend failed
    plan ??= await _loadLocal(userId);

    // Reorder days to start from yesterday
    if (plan != null) {
      plan = reorderWeeklyPlanDays(plan);
    }

    return plan;
  }

  Future<void> save(String userId, Map<String, dynamic> plan) async {
    // Save to backend
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/weekly-plans/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'focus': (plan['focus'] ?? 'hybrid'),
          'days': plan['days'],
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        // Cache canonical server response if possible
        try {
          final serverPlan = json.decode(response.body) as Map<String, dynamic>;
          await _saveLocal(userId, serverPlan);
        } catch (_) {
          await _saveLocal(userId, plan);
        }
        return;
      } else {
        final bodySnippet = response.body.length > 160 ? response.body.substring(0,160) + '...' : response.body;
        throw Exception('Backend save failed (HTTP ${response.statusCode}): ' + bodySnippet);
      }
    } catch (e) {
      // Backend unavailable, fall through to local save
    }
    
    // Fallback to local storage only
    await _saveLocal(userId, plan);
  }

  Future<Map<String, dynamic>?> _loadLocal(String userId) async {
    if (kIsWeb) {
      final key = '$_keyPrefix$userId';
      final raw = getItem(key);
      if (raw == null) return null;
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _saveLocal(String userId, Map<String, dynamic> plan) async {
    if (kIsWeb) {
      final key = '$_keyPrefix$userId';
      setItem(key, json.encode(plan));
    }
  }
}
