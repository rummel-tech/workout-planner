import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen shows fields and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    // Expect email input
    expect(find.byType(TextField), findsNWidgets(3)); // email, token, new password

    // Expect labels / buttons
    expect(find.text('Request password reset'), findsOneWidget);
    expect(find.text('Send reset email'), findsOneWidget);
    expect(find.text('Have a token? Reset password'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);

    // Brings widget tree to stable state
    await tester.pumpAndSettle();
  });
}
