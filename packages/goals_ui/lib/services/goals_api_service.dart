import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:home_dashboard_ui/services/auth_service.dart';

class GoalsApiService {
  final AuthService _authService;

  GoalsApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  // Get all goals for the authenticated user
  Future<List<Map<String, dynamic>>> getGoals([String? userId]) async {
    try {
      // Use provided userId or get from auth service
      final effectiveUserId = userId ?? await _authService.getUserId();
      if (effectiveUserId == null) {
        throw Exception('Not authenticated');
      }
      final response = await _authService.authenticatedRequest(
        method: 'GET',
        endpoint: '/goals?user_id=$effectiveUserId',
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }

  // Get plans for a specific goal
  Future<List<Map<String, dynamic>>> getPlans(int goalId, String userId) async {
    try {
      final response = await _authService.authenticatedRequest(
        method: 'GET',
        endpoint: '/goals/$goalId/plans?user_id=$userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }

  // Create a new plan for a goal
  Future<Map<String, dynamic>> createPlan(int goalId, String userId, String name, String description) async {
    try {
      final response = await _authService.authenticatedRequest(
        method: 'POST',
        endpoint: '/goals/$goalId/plans',
        body: json.encode({
          'user_id': userId,
          'name': name,
          'description': description,
          'status': 'active',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }

  // Update an existing plan
  Future<Map<String, dynamic>> updatePlan(int planId, String name, String description) async {
    try {
      final response = await _authService.authenticatedRequest(
        method: 'PUT',
        endpoint: '/goals/plans/$planId',
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }

  // Delete a plan
  Future<void> deletePlan(int planId) async {
    try {
      final response = await _authService.authenticatedRequest(
        method: 'DELETE',
        endpoint: '/goals/plans/$planId',
      );
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }

  // Create a new goal
  Future<Map<String, dynamic>> createGoal(
    String userId,
    String goalType,
    double? targetValue,
    String? targetDate,
    String? notes,
    String? targetUnit,
  ) async {
    try {
      final response = await _authService.authenticatedRequest(
        method: 'POST',
        endpoint: '/goals',
        body: json.encode({
          'user_id': userId,
          'goal_type': goalType,
          'target_value': targetValue,
          'target_unit': targetUnit,
          'target_date': targetDate,
          'notes': notes,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }

  // Update an existing goal
  Future<Map<String, dynamic>> updateGoal(
    int goalId,
    String goalType,
    double? targetValue,
    String? targetDate,
    String? notes,
    String? targetUnit,
  ) async {
    try {
      final response = await _authService.authenticatedRequest(
        method: 'PUT',
        endpoint: '/goals/$goalId',
        body: json.encode({
          'goal_type': goalType,
          'target_value': targetValue,
          'target_unit': targetUnit,
          'target_date': targetDate,
          'notes': notes,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }

  // Delete a goal
  Future<void> deleteGoal(int goalId) async {
    try {
      final response = await _authService.authenticatedRequest(
        method: 'DELETE',
        endpoint: '/goals/$goalId',
      );
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Cannot connect to server. Is the backend running?');
    } on TimeoutException {
      throw Exception('Request timed out. Server may be down.');
    }
  }
}
