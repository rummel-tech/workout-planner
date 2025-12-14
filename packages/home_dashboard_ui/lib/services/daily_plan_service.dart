import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';
import 'api_config.dart';

class DailyPlanService {
  static const _keyPrefix = 'daily_plan_';

  String get _baseUrl => ApiConfig.baseUrl;

  /// Load today's workout plan for a user
  Future<Map<String, dynamic>?> loadToday(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await load(userId, today);
  }

  /// Load workout plan for a specific date
  Future<Map<String, dynamic>?> load(String userId, String date) async {
    // Try backend first
    final baseUrl = _baseUrl;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-plans/$userId/$date'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Cache locally
        await _saveLocal(userId, date, data);
        return data;
      }
    } catch (e) {
      // Backend unavailable, fall through to local cache
    }

    // Fallback to local storage
    return await _loadLocal(userId, date);
  }

  /// Save today's workout plan
  Future<void> saveToday(String userId, Map<String, dynamic> plan) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await save(userId, today, plan);
  }

  /// Save workout plan for a specific date
  Future<void> save(String userId, String date, Map<String, dynamic> plan) async {
    // Always save locally first for immediate persistence
    await _saveLocal(userId, date, plan);

    // Then try to sync to backend
    final baseUrl = _baseUrl;
    try {
      // Build workouts array in the new format
      List<Map<String, dynamic>> workouts = [];

      if (plan.containsKey('workouts') && plan['workouts'] is List) {
        // New format: plan has workouts array
        workouts = (plan['workouts'] as List).map((w) {
          final workout = w as Map<String, dynamic>;
          return {
            'name': workout['name'] ?? workout['type'] ?? 'Workout',
            'type': workout['type'],
            'warmup': workout['warmup'] ?? [],
            'main': workout['main'] ?? [],
            'cooldown': workout['cooldown'] ?? [],
            'notes': workout['notes'] ?? '',
            'status': workout['status'] ?? 'pending',
          };
        }).toList();
      } else if (plan.containsKey('warmup') || plan.containsKey('main') || plan.containsKey('cooldown')) {
        // Old format: flat warmup/main/cooldown at top level
        workouts = [{
          'name': 'Workout',
          'type': null,
          'warmup': plan['warmup'] ?? [],
          'main': plan['main'] ?? [],
          'cooldown': plan['cooldown'] ?? [],
          'notes': plan['notes'] ?? '',
          'status': plan['status'] ?? 'pending',
        }];
      }

      final payload = {
        'user_id': userId,
        'date': date,
        'workouts': workouts,
        'ai_notes': plan['ai_notes'],
      };

      await http.put(
        Uri.parse('$baseUrl/daily-plans/$userId/$date'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      // Backend sync failed, data is saved locally
    }
  }

  Future<Map<String, dynamic>?> _loadLocal(String userId, String date) async {
    try {
      final key = '$_keyPrefix${userId}_$date';

      if (kIsWeb) {
        // Use localStorage for web
        final raw = getItem(key);
        if (raw == null) {
          return null;
        }
        try {
          final decoded = json.decode(raw);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (e) {
          // JSON decode error, return null
        }
      }
      // For mobile, would use shared_preferences or secure storage
    } catch (e) {
      // Local storage error
    }
    return null;
  }

  Future<void> _saveLocal(String userId, String date, Map<String, dynamic> plan) async {
    try {
      final key = '$_keyPrefix${userId}_$date';
      final encoded = json.encode(plan);

      if (kIsWeb) {
        // Use localStorage for web
        setItem(key, encoded);
      }
      // For mobile, would use shared_preferences or secure storage
    } catch (e) {
      rethrow;
    }
  }
}
