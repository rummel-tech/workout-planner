import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class GoalsApiService {
  final String baseUrl;
  final Duration timeout;

  GoalsApiService({
    this.baseUrl = 'http://localhost:8000',
    this.timeout = const Duration(seconds: 10),
  });

  // Get all goals for a user
  Future<List<Map<String, dynamic>>> getGoals(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/goals?user_id=$userId'))
          .timeout(timeout);
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
      final response = await http
          .get(Uri.parse('$baseUrl/goals/$goalId/plans?user_id=$userId'))
          .timeout(timeout);
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
      final response = await http.post(
        Uri.parse('$baseUrl/goals/$goalId/plans'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'name': name,
          'description': description,
          'status': 'active',
        }),
      ).timeout(timeout);
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
      final response = await http.put(
        Uri.parse('$baseUrl/goals/plans/$planId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
        }),
      ).timeout(timeout);
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
      final response = await http
          .delete(Uri.parse('$baseUrl/goals/plans/$planId'))
          .timeout(timeout);
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
      final response = await http.post(
        Uri.parse('$baseUrl/goals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'goal_type': goalType,
          'target_value': targetValue,
          'target_unit': targetUnit,
          'target_date': targetDate,
          'notes': notes,
        }),
      ).timeout(timeout);
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
      final response = await http.put(
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'goal_type': goalType,
          'target_value': targetValue,
          'target_unit': targetUnit,
          'target_date': targetDate,
          'notes': notes,
        }),
      ).timeout(timeout);
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
      final response = await http
          .delete(Uri.parse('$baseUrl/goals/$goalId'))
          .timeout(timeout);
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
