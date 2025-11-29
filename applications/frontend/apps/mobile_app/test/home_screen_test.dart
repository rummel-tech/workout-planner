import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/home_screen.dart';
import 'package:home_dashboard_ui/services/theme_controller.dart';

void main() {
  testWidgets('HomeScreen has a title and displays data', (WidgetTester tester) async {
    final themeController = ThemeController(ThemeData.light());

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          themeController: themeController,
          readiness: const {'readiness': 0.8},
          dailyPlan: const {'main': ['Workout B']},
          weeklyPlan: const {'focus': 'strength'},
        ),
      ),
    );

    // Verify that the title is displayed.
    expect(find.text('Home'), findsOneWidget);

    // Verify that the readiness score is displayed.
    expect(find.text('Readiness: 0.8'), findsOneWidget);

    // Verify that the daily plan is displayed.
    expect(find.text('Workout B'), findsOneWidget);

    // Verify that the weekly plan is displayed.
    expect(find.text('Focus: strength'), findsOneWidget);
  });
}
