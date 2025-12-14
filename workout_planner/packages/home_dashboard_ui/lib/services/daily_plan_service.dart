import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';

class DailyPlanService {
  static const _keyPrefix = 'daily_plan_';
  
  static String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      // Android emulator
      return 'http://10.0.2.2:8000';
    }
  }

  /// Load today's workout plan for a user
  Future<Map<String, dynamic>?> loadToday(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await load(userId, today);
  }

  /// Load workout plan for a specific date
  Future<Map<String, dynamic>?> load(String userId, String date) async {
    print('[DailyPlanService] Loading plan for $userId on $date');
    // Try backend first
    final baseUrl = _getBaseUrl();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-plans/$userId/$date'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('[DailyPlanService] Loaded from backend: ${data['main']?.length ?? 0} main items');
        // Cache locally
        await _saveLocal(userId, date, data);
        return data;
      }
    } catch (e) {
      print('[DailyPlanService] Backend load failed, using local cache: $e');
    }
    
    // Fallback to local storage
    final local = await _loadLocal(userId, date);
    print('[DailyPlanService] Loaded from local: ${local?['main']?.length ?? 0} main items');
    return local;
  }

  /// Save today's workout plan
  Future<void> saveToday(String userId, Map<String, dynamic> plan) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await save(userId, today, plan);
  }

  /// Save workout plan for a specific date
  Future<void> save(String userId, String date, Map<String, dynamic> plan) async {
    print('[DailyPlanService] Saving plan for $userId on $date with ${plan['main']?.length ?? 0} main items');
    print('[DailyPlanService] Plan data: ${json.encode(plan)}');
    
    // Always save locally first for immediate persistence
    await _saveLocal(userId, date, plan);
    print('[DailyPlanService] Saved to local storage');
    
    // Then try to sync to backend
    final baseUrl = _getBaseUrl();
    try {
      final payload = {
        'user_id': userId,
        'date': date,
        'plan_json': {
          'warmup': plan['warmup'] ?? [],
          'main': plan['main'] ?? [],
          'cooldown': plan['cooldown'] ?? [],
          'notes': plan['notes'] ?? '',
        },
        'status': plan['status'] ?? 'pending',
      };
      print('[DailyPlanService] Backend payload: ${json.encode(payload)}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/daily-plans/$userId/$date'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        print('[DailyPlanService] Synced to backend successfully');
      } else {
        print('[DailyPlanService] Backend save failed (HTTP ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('[DailyPlanService] Backend save failed, data saved locally: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadLocal(String userId, String date) async {
    try {
      final key = '$_keyPrefix${userId}_$date';
      print('[DailyPlanService] Loading from local key: $key');
      
      if (kIsWeb) {
        // Use localStorage for web
        final raw = getItem(key);
        if (raw == null) {
          print('[DailyPlanService] No local data found');
          return null;
        }
        print('[DailyPlanService] Raw local data: $raw');
        try {
          final decoded = json.decode(raw);
          if (decoded is Map<String, dynamic>) {
            print('[DailyPlanService] Decoded ${decoded['main']?.length ?? 0} main items from local');
            return decoded;
          }
        } catch (e) {
          print('[DailyPlanService] JSON decode error: $e');
        }
      } else {
        // For mobile, would use shared_preferences or secure storage
        print('[DailyPlanService] Mobile storage not yet implemented');
      }
    } catch (e) {
      print('[DailyPlanService] Local storage error in _loadLocal: $e');
    }
    return null;
  }

  Future<void> _saveLocal(String userId, String date, Map<String, dynamic> plan) async {
    try {
      final key = '$_keyPrefix${userId}_$date';
      final encoded = json.encode(plan);
      print('[DailyPlanService] Saving to local key: $key');
      print('[DailyPlanService] Encoded data: $encoded');
      
      if (kIsWeb) {
        // Use localStorage for web
        setItem(key, encoded);
        print('[DailyPlanService] Successfully saved to localStorage');
        
        // Verify save
        final verify = getItem(key);
        if (verify != null) {
          print('[DailyPlanService] Verified: data persisted correctly');
        } else {
          print('[DailyPlanService] WARNING: data not found after save!');
        }
      } else {
        // For mobile, would use shared_preferences or secure storage
        print('[DailyPlanService] Mobile storage not yet implemented');
      }
    } catch (e) {
      print('[DailyPlanService] Local storage error in _saveLocal: $e');
      rethrow;
    }
  }
}
