import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/services/auth_service.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock secure storage for tests
  const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'read':
        return null;
      case 'write':
        return null;
      case 'delete':
        return null;
      default:
        return null;
    }
  });

  group('Authentication Integration Tests', () {
    late AuthService authService;

    setUp(() {
      // Use localhost for tests (assumes backend running on 8000)
      authService = AuthService(baseUrl: 'http://localhost:8000');
    });

    test('Register new user successfully', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'test_$timestamp@example.com';
      final password = 'TestPassword123';

      final result = await authService.register(
        email: email,
        password: password,
        fullName: 'Test User',
      );

      expect(result, isNotNull);
      expect(result['access_token'], isNotEmpty);
      expect(result['refresh_token'], isNotEmpty);
      expect(result['token_type'], equals('bearer'));

      // Verify tokens were stored
      final accessToken = await authService.getAccessToken();
      final refreshToken = await authService.getRefreshToken();
      expect(accessToken, isNotEmpty);
      expect(refreshToken, isNotEmpty);

      // Verify we're authenticated
      final isAuthed = await authService.isAuthenticated();
      expect(isAuthed, isTrue);

      // Cleanup
      await authService.logout();
    });

    test('Login with existing user', () async {
      // First register a user
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'login_test_$timestamp@example.com';
      final password = 'LoginPass123';

      await authService.register(
        email: email,
        password: password,
      );
      await authService.logout();

      // Now login
      final result = await authService.login(
        email: email,
        password: password,
      );

      expect(result, isNotNull);
      expect(result['access_token'], isNotEmpty);
      expect(result['refresh_token'], isNotEmpty);

      // Verify user info
      final userInfo = await authService.getCurrentUser();
      expect(userInfo['email'], equals(email));
      expect(userInfo['id'], isNotEmpty);

      // Cleanup
      await authService.logout();
    });

    test('Reject duplicate email registration', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'duplicate_$timestamp@example.com';
      final password = 'TestPassword123';

      // First registration succeeds
      await authService.register(email: email, password: password);
      await authService.logout();

      // Second registration with same email should fail
      expect(
        () => authService.register(email: email, password: password),
        throwsA(
          predicate((e) =>
              e.toString().contains('Email already registered') ||
              e.toString().contains('already exists')),
        ),
      );
    });

    test('Reject weak password', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'weak_$timestamp@example.com';

      expect(
        () => authService.register(email: email, password: 'short'),
        throwsException,
      );
    });

    test('Reject password over 72 bytes', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'long_$timestamp@example.com';
      final longPassword = 'A' * 73; // 73 bytes

      expect(
        () => authService.register(email: email, password: longPassword),
        throwsA(
          predicate((e) => e.toString().contains('72 bytes')),
        ),
      );
    });

    test('Login fails with wrong password', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'wrongpass_$timestamp@example.com';
      final password = 'CorrectPass123';

      await authService.register(email: email, password: password);
      await authService.logout();

      expect(
        () => authService.login(email: email, password: 'WrongPass123'),
        throwsA(
          predicate((e) =>
              e.toString().contains('Incorrect email or password') ||
              e.toString().contains('Login failed')),
        ),
      );
    });

    test('Refresh token works', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'refresh_$timestamp@example.com';
      final password = 'RefreshPass123';

      await authService.register(email: email, password: password);

      final originalToken = await authService.getAccessToken();

      // Wait a moment and refresh
      await Future.delayed(const Duration(milliseconds: 100));
      await authService.refreshAccessToken();

      final newToken = await authService.getAccessToken();
      expect(newToken, isNot(equals(originalToken)));

      // Cleanup
      await authService.logout();
    });

    test('Logout clears tokens', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'logout_$timestamp@example.com';
      final password = 'LogoutPass123';

      await authService.register(email: email, password: password);
      expect(await authService.isAuthenticated(), isTrue);

      await authService.logout();

      expect(await authService.isAuthenticated(), isFalse);
      expect(await authService.getAccessToken(), isNull);
      expect(await authService.getRefreshToken(), isNull);
    });
  });
}
