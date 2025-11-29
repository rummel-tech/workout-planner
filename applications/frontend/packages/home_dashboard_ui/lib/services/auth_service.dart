// Authentication service for managing user sessions and tokens
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final String baseUrl;
  final Duration timeout;
  final _storage = const FlutterSecureStorage();
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';

  AuthService({
    // Web: use localhost
    // Android emulator: use 10.0.2.2 to reach host machine
    // iOS simulator: use localhost or actual machine IP
    // For production, use actual backend URL
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : baseUrl = baseUrl ?? _getDefaultBaseUrl();

  static String _getDefaultBaseUrl() {
    // Check environment variable first
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    // Platform-specific defaults
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      // Default to Android emulator host mapping for mobile
      return 'http://10.0.2.2:8000';
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          if (fullName != null) 'full_name': fullName,
        }),
      ).timeout(timeout);

      if (resp.statusCode == 201) {
        final data = json.decode(resp.body);
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return data;
      } else {
        final error = json.decode(resp.body);
        throw Exception(error['detail'] ?? 'Registration failed');
      }
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused')) {
        throw Exception('Backend unreachable');
      }
      rethrow;
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        // Fetch user info
        await getCurrentUser();
        return data;
      } else {
        final error = json.decode(resp.body);
        throw Exception(error['detail'] ?? 'Login failed');
      }
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused')) {
        throw Exception('Backend unreachable');
      }
      rethrow;
    }
  }

  /// Get current user information
  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/auth/me');
    try {
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        // Cache user info
        await _storage.write(key: _userIdKey, value: data['id']);
        await _storage.write(key: _emailKey, value: data['email']);
        return data;
      } else if (resp.statusCode == 401) {
        // Try to refresh token
        await refreshAccessToken();
        return getCurrentUser(); // Retry
      } else {
        throw Exception('Failed to get user info');
      }
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused')) {
        throw Exception('Backend unreachable');
      }
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  Future<void> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final uri = Uri.parse('$baseUrl/auth/refresh');
    try {
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $refreshToken',
        },
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
      } else {
        // Refresh failed, clear tokens
        await logout();
        throw Exception('Session expired, please login again');
      }
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _emailKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get cached user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Get cached email
  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Make authenticated HTTP request with auto-retry on token expiry
  Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    final authHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?headers,
    };

    http.Response resp;
    switch (method.toUpperCase()) {
      case 'GET':
        resp = await http.get(uri, headers: authHeaders).timeout(timeout);
        break;
      case 'POST':
        resp = await http.post(uri, headers: authHeaders, body: body).timeout(timeout);
        break;
      case 'PUT':
        resp = await http.put(uri, headers: authHeaders, body: body).timeout(timeout);
        break;
      case 'DELETE':
        resp = await http.delete(uri, headers: authHeaders).timeout(timeout);
        break;
      default:
        throw Exception('Unsupported HTTP method');
    }

    // Auto-refresh on 401
    if (resp.statusCode == 401) {
      await refreshAccessToken();
      return authenticatedRequest(
        method: method,
        endpoint: endpoint,
        headers: headers,
        body: body,
      );
    }

    return resp;
  }

  void dispose() {
    // Cleanup if needed
  }
}
