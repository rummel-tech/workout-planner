// Backend integration tests for authentication
// These tests validate the backend API directly without Flutter UI
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const baseUrl = 'http://localhost:8000';

void main() {
  group('Auth Backend Integration Tests', () {
    // Generate unique email for each test run
    final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    const testPassword = 'TestPassword123!';
    const testFullName = 'Test User';
    
    String? accessToken;
    String? refreshToken;

    test('Register new user successfully', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': testPassword,
          'full_name': testFullName,
        }),
      );

      expect(response.statusCode, 201);
      final data = json.decode(response.body);
      expect(data, containsPair('access_token', isA<String>()));
      expect(data, containsPair('refresh_token', isA<String>()));
      expect(data, containsPair('token_type', 'bearer'));
      
      // Save tokens for subsequent tests
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
    });

    test('Reject duplicate email registration', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': testPassword,
        }),
      );

      expect(response.statusCode, 400);
      final data = json.decode(response.body);
      expect(data['detail'], contains('already registered'));
    });

    test('Reject weak password (< 8 characters)', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'weak_${DateTime.now().millisecondsSinceEpoch}@example.com',
          'password': 'short',
        }),
      );

      expect(response.statusCode, 422);
      final data = json.decode(response.body);
      expect(data['detail'], isA<List>());
      expect(
        data['detail'][0]['msg'], 
        contains('at least 8 characters')
      );
    });

    test('Reject password over 72 bytes', () async {
      final longPassword = 'a' * 73;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'long_${DateTime.now().millisecondsSinceEpoch}@example.com',
          'password': longPassword,
        }),
      );

      expect(response.statusCode, 422);
      final data = json.decode(response.body);
      expect(data['detail'], isA<List>());
      expect(
        data['detail'][0]['msg'], 
        contains('at most 72 bytes')
      );
    });

    test('Login with existing user', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': testPassword,
        }),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data, containsPair('access_token', isA<String>()));
      expect(data, containsPair('refresh_token', isA<String>()));
      expect(data, containsPair('token_type', 'bearer'));
    });

    test('Login fails with wrong password', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': 'WrongPassword123!',
        }),
      );

      expect(response.statusCode, 401);
      final data = json.decode(response.body);
      expect(data['detail'], contains('Invalid'));
    });

    test('Refresh token works', () async {
      expect(refreshToken, isNotNull, reason: 'Refresh token should be set from registration test');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data, containsPair('access_token', isA<String>()));
      expect(data, containsPair('refresh_token', isA<String>()));
    });

    test('Get current user profile', () async {
      expect(accessToken, isNotNull, reason: 'Access token should be set from registration test');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['email'], testEmail);
      if (testFullName.isNotEmpty) {
        expect(data['full_name'], testFullName);
      }
    });

    test('Logout clears session', () async {
      expect(accessToken, isNotNull, reason: 'Access token should be set from registration test');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['message'], contains('Logged out'));
    });
  });
}
