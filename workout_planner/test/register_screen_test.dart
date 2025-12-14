import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/register_screen.dart';

void main() {
  testWidgets('RegisterScreen has a title and text fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    // Verify that the title is displayed.
    expect(find.text('Register'), findsOneWidget);

    // Verify that the email and password text fields are displayed.
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
