import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/welcome_screen.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('displays app title and tagline', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      expect(find.text('Workout-Planner'), findsOneWidget);
      expect(find.text('AI-Powered Training Platform'), findsOneWidget);
    });

    testWidgets('displays feature cards', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      expect(find.text('AI Coach'), findsOneWidget);
      expect(find.text('Smart Planning'), findsOneWidget);
      expect(find.text('Performance Insights'), findsOneWidget);
    });

    testWidgets('has separate Login button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginButton, findsOneWidget);
    });

    testWidgets('has separate Sign Up with Code button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      final signUpButton = find.widgetWithText(OutlinedButton, 'Sign Up with Code');
      expect(signUpButton, findsOneWidget);
    });

    testWidgets('Login button navigates to login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login Screen')),
          },
        ),
      );

      // Scroll down to make button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('Sign Up button navigates to register screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/register': (context) => const Scaffold(body: Text('Register Screen')),
          },
        ),
      );

      // Scroll down to make button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final signUpButton = find.widgetWithText(OutlinedButton, 'Sign Up with Code');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('displays registration code hint text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      expect(find.text('Have a registration code? Sign up to get started.'), findsOneWidget);
    });
  });
}
