import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';
import 'api_config.dart';

/// Service for managing workout templates (CRUD operations)
class WorkoutService {
  static const _storageKey = 'saved_workouts';
  String get _baseUrl => ApiConfig.baseUrl;

  /// Get all saved workouts for a user
  Future<List<Map<String, dynamic>>> getWorkouts(String userId) async {
    // Try backend first
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workouts?user_id=$userId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final workouts = data.cast<Map<String, dynamic>>();
          // Cache locally
          await _saveLocal(userId, workouts);
          return workouts;
        }
      }
    } catch (e) {
      // Backend unavailable, fall through to local cache
    }

    // Fallback to local storage
    return await _loadLocal(userId);
  }

  /// Get a specific workout by ID
  Future<Map<String, dynamic>?> getWorkout(String userId, String workoutId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workouts/$workoutId?user_id=$userId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Backend unavailable, try local
    }

    // Fallback to local
    final workouts = await _loadLocal(userId);
    return workouts.firstWhere(
      (w) => w['id']?.toString() == workoutId,
      orElse: () => <String, dynamic>{},
    );
  }

  /// Save a new workout
  Future<Map<String, dynamic>> createWorkout(String userId, Map<String, dynamic> workout) async {
    final workoutWithMeta = {
      ...workout,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Try backend first
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/workouts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(workoutWithMeta),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final saved = json.decode(response.body) as Map<String, dynamic>;
        // Update local cache
        final workouts = await _loadLocal(userId);
        workouts.add(saved);
        await _saveLocal(userId, workouts);
        return saved;
      }
    } catch (e) {
      // Backend unavailable, save locally only
    }

    // Fallback: save locally with generated ID
    final localWorkout = {
      ...workoutWithMeta,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'local_only': true,
    };
    final workouts = await _loadLocal(userId);
    workouts.add(localWorkout);
    await _saveLocal(userId, workouts);
    return localWorkout;
  }

  /// Update an existing workout
  Future<Map<String, dynamic>> updateWorkout(
    String userId,
    String workoutId,
    Map<String, dynamic> workout,
  ) async {
    final workoutWithMeta = {
      ...workout,
      'id': workoutId,
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Try backend first
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/workouts/$workoutId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(workoutWithMeta),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final updated = json.decode(response.body) as Map<String, dynamic>;
        // Update local cache
        final workouts = await _loadLocal(userId);
        final index = workouts.indexWhere((w) => w['id']?.toString() == workoutId);
        if (index >= 0) {
          workouts[index] = updated;
        } else {
          workouts.add(updated);
        }
        await _saveLocal(userId, workouts);
        return updated;
      }
    } catch (e) {
      // Backend unavailable, update locally
    }

    // Fallback: update locally
    final workouts = await _loadLocal(userId);
    final index = workouts.indexWhere((w) => w['id']?.toString() == workoutId);
    if (index >= 0) {
      workouts[index] = workoutWithMeta;
    } else {
      workouts.add(workoutWithMeta);
    }
    await _saveLocal(userId, workouts);
    return workoutWithMeta;
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String userId, String workoutId) async {
    // Try backend first
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/workouts/$workoutId?user_id=$userId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from local cache
        final workouts = await _loadLocal(userId);
        workouts.removeWhere((w) => w['id']?.toString() == workoutId);
        await _saveLocal(userId, workouts);
        return true;
      }
    } catch (e) {
      // Backend unavailable, delete locally
    }

    // Fallback: delete locally
    final workouts = await _loadLocal(userId);
    final initialLength = workouts.length;
    workouts.removeWhere((w) => w['id']?.toString() == workoutId);
    if (workouts.length < initialLength) {
      await _saveLocal(userId, workouts);
      return true;
    }
    return false;
  }

  /// Get workouts by type
  Future<List<Map<String, dynamic>>> getWorkoutsByType(String userId, String type) async {
    final workouts = await getWorkouts(userId);
    return workouts.where((w) => w['type'] == type).toList();
  }

  /// Search workouts by name
  Future<List<Map<String, dynamic>>> searchWorkouts(String userId, String query) async {
    final workouts = await getWorkouts(userId);
    final lowerQuery = query.toLowerCase();
    return workouts.where((w) {
      final name = (w['name'] ?? '').toString().toLowerCase();
      final type = (w['type'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery) || type.contains(lowerQuery);
    }).toList();
  }

  /// Create a copy of a workout (for "use previous workout" feature)
  Map<String, dynamic> copyWorkout(Map<String, dynamic> workout, {String? newName}) {
    final copy = Map<String, dynamic>.from(workout);
    // Remove ID so it creates a new workout when saved
    copy.remove('id');
    copy.remove('created_at');
    copy.remove('updated_at');
    copy.remove('local_only');
    if (newName != null) {
      copy['name'] = newName;
    }
    return copy;
  }

  // Local storage helpers
  Future<List<Map<String, dynamic>>> _loadLocal(String userId) async {
    if (kIsWeb) {
      final key = '${_storageKey}_$userId';
      final raw = getItem(key);
      if (raw != null) {
        try {
          final decoded = json.decode(raw);
          if (decoded is List) {
            return decoded.cast<Map<String, dynamic>>();
          }
        } catch (_) {}
      }
    }
    return [];
  }

  Future<void> _saveLocal(String userId, List<Map<String, dynamic>> workouts) async {
    if (kIsWeb) {
      final key = '${_storageKey}_$userId';
      setItem(key, json.encode(workouts));
    }
  }
}
