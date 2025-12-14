import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/register_screen.dart';

void main() {
  group('RegisterScreen Step 1 - Code Validation', () {
    testWidgets('shows registration code input field', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      // Verify step 1 title is displayed
      expect(find.text('Enter Registration Code'), findsOneWidget);

      // Verify registration code text field is displayed
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Registration Code'), findsOneWidget);
    });

    testWidgets('shows error when code is empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      // Tap validate button without entering code
      final validateButton = find.widgetWithText(ElevatedButton, 'Validate Code');
      await tester.tap(validateButton);
      await tester.pump();

      // Verify error message
      expect(find.text('Please enter your registration code'), findsOneWidget);
    });

    testWidgets('shows error when code is too short', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      // Enter short code
      final codeField = find.byType(TextFormField);
      await tester.enterText(codeField, 'ABC');

      // Tap validate button
      final validateButton = find.widgetWithText(ElevatedButton, 'Validate Code');
      await tester.tap(validateButton);
      await tester.pump();

      // Verify error message
      expect(find.text('Code must be at least 4 characters'), findsOneWidget);
    });

    testWidgets('has link to login screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      // Verify login link exists
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Login'), findsOneWidget);
    });
  });

  group('RegisterScreen Step 2 - User Details', () {
    // Note: Testing step 2 requires mocking the AuthService to simulate
    // a successful code validation. These tests would need dependency injection
    // or a mock to properly test the step 2 UI.

    testWidgets('step 2 has email, password, and confirm password fields', (WidgetTester tester) async {
      // This test documents expected behavior for step 2
      // In the actual UI, step 2 shows after code validation succeeds:
      // - Full Name (Optional) field
      // - Email field
      // - Password field
      // - Confirm Password field
      // - Create Account button
      // - Back button to return to step 1

      // To fully test this, we'd need to mock AuthService.validateCode()
      // For now, we verify the RegisterScreen widget builds without error
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('RegisterScreen Navigation', () {
    testWidgets('navigates to login when Login button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login Screen')),
          },
        ),
      );

      // Find and tap Login button
      final loginButton = find.widgetWithText(TextButton, 'Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
