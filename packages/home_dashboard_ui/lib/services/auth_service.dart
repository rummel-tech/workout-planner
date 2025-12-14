// Authentication service for managing user sessions and tokens
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart' as web_storage;

/// Exception thrown when authentication fails and user needs to re-login
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final String baseUrl;
  final Duration timeout;
  final _storage = const FlutterSecureStorage();

  /// Callback to invoke when authentication fails and user must re-login
  /// Set this to navigate to the login screen
  void Function()? onAuthFailure;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';

  AuthService({
    String? baseUrl,
    Duration? timeout,
    this.onAuthFailure,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl,
       timeout = timeout ?? ApiConfig.defaultTimeout;

  /// Validate a registration code
  Future<Map<String, dynamic>> validateCode(String code) async {
    final uri = Uri.parse('$baseUrl/auth/validate-code?code=${Uri.encodeComponent(code)}');
    try {
      final resp = await http.post(uri).timeout(timeout);

      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      } else {
        return {'valid': false, 'message': 'Failed to validate code'};
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

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
    String? registrationCode,
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
          if (registrationCode != null) 'registration_code': registrationCode,
        }),
      ).timeout(timeout);

      if (resp.statusCode == 201) {
        final data = json.decode(resp.body);
        // Check if user was registered or waitlisted
        if (data['status'] == 'registered') {
          await _saveTokens(
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'],
          );
        }
        return data;
      } else {
        final body = json.decode(resp.body);
        // Handle both error formats: {"detail": "..."} and {"error": {"message": "..."}}
        String message = 'Registration failed';
        if (body['detail'] != null) {
          message = body['detail'];
        } else if (body['error'] != null && body['error']['message'] != null) {
          message = body['error']['message'];
        }
        throw Exception(message);
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
        final body = json.decode(resp.body);
        // Handle both error formats: {"detail": "..."} and {"error": {"message": "..."}}
        String message = 'Login failed';
        if (body['detail'] != null) {
          message = body['detail'];
        } else if (body['error'] != null && body['error']['message'] != null) {
          message = body['error']['message'];
        }
        throw Exception(message);
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
        if (web_storage.isWeb) {
          web_storage.setItem(_userIdKey, data['id']);
          web_storage.setItem(_emailKey, data['email']);
        } else {
          await _storage.write(key: _userIdKey, value: data['id']);
          await _storage.write(key: _emailKey, value: data['email']);
        }
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
      await _handleAuthFailure();
      throw AuthenticationException('No refresh token available');
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
        // Refresh failed, clear tokens and notify
        await _handleAuthFailure();
        throw AuthenticationException('Session expired, please login again');
      }
    } catch (e) {
      if (e is! AuthenticationException) {
        await _handleAuthFailure();
      }
      rethrow;
    }
  }

  /// Handle authentication failure - clears tokens and triggers callback
  Future<void> _handleAuthFailure() async {
    await logout();
    onAuthFailure?.call();
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    if (web_storage.isWeb) {
      web_storage.removeItem(_accessTokenKey);
      web_storage.removeItem(_refreshTokenKey);
      web_storage.removeItem(_userIdKey);
      web_storage.removeItem(_emailKey);
    } else {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _emailKey);
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    if (web_storage.isWeb) {
      return web_storage.getItem(_accessTokenKey);
    }
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    if (web_storage.isWeb) {
      return web_storage.getItem(_refreshTokenKey);
    }
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get cached user ID
  Future<String?> getUserId() async {
    if (web_storage.isWeb) {
      return web_storage.getItem(_userIdKey);
    }
    return await _storage.read(key: _userIdKey);
  }

  /// Get cached email
  Future<String?> getEmail() async {
    if (web_storage.isWeb) {
      return web_storage.getItem(_emailKey);
    }
    return await _storage.read(key: _emailKey);
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (web_storage.isWeb) {
      web_storage.setItem(_accessTokenKey, accessToken);
      web_storage.setItem(_refreshTokenKey, refreshToken);
    } else {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
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

  /// Perform client-side Google Sign-In and exchange token with backend.
  ///
  /// This uses `package:google_sign_in` to obtain a Google id token and then
  /// posts it to the backend endpoint `/auth/oauth/google` which is expected
  /// to validate the token and return application `access_token` /
  /// `refresh_token` similar to the existing login/register endpoints.
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) throw Exception('Google sign-in cancelled');

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google did not return an idToken');

      final uri = Uri.parse('$baseUrl/auth/oauth/google');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      ).timeout(timeout);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = json.decode(resp.body);
        if (data['access_token'] != null && data['refresh_token'] != null) {
          await _saveTokens(
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'],
          );
          // Cache user info if provided
          if (data['user'] != null && data['user']['id'] != null) {
            if (web_storage.isWeb) {
              web_storage.setItem(_userIdKey, data['user']['id'].toString());
            } else {
              await _storage.write(key: _userIdKey, value: data['user']['id'].toString());
            }
          }
          await getCurrentUser();
        }
        return data;
      } else {
        String message = 'Google sign-in failed';
        try {
          final body = json.decode(resp.body);
          if (body['detail'] != null) message = body['detail'];
          else if (body['error'] != null && body['error']['message'] != null) message = body['error']['message'];
        } catch (_) {}
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        throw Exception('Backend unreachable');
      }
      rethrow;
    }
  }

  /// Request a password reset email to be sent to [email].
  ///
  /// Backend should accept `POST $baseUrl/auth/forgot` with `{ email }` and
  /// return a 200/202 status on success. The UI will inform the user to check
  /// their email for a reset token or link.
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/auth/forgot');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(timeout);

      if (resp.statusCode == 200 || resp.statusCode == 202) {
        return json.decode(resp.body.isNotEmpty ? resp.body : '{}');
      }

      String message = 'Failed to request password reset';
      try {
        final body = json.decode(resp.body);
        if (body['detail'] != null) message = body['detail'];
      } catch (_) {}
      throw Exception(message);
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        throw Exception('Backend unreachable');
      }
      rethrow;
    }
  }

  /// Complete a password reset using a server-issued [token] and [newPassword].
  ///
  /// Backend should accept `POST $baseUrl/auth/reset` with `{ token, new_password }`.
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final uri = Uri.parse('$baseUrl/auth/reset');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'new_password': newPassword}),
      ).timeout(timeout);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return json.decode(resp.body.isNotEmpty ? resp.body : '{}');
      }

      String message = 'Failed to reset password';
      try {
        final body = json.decode(resp.body);
        if (body['detail'] != null) message = body['detail'];
      } catch (_) {}
      throw Exception(message);
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        throw Exception('Backend unreachable');
      }
      rethrow;
    }
  }
}
