import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/ui_components/weekly_plan_preview.dart';

void main() {
  testWidgets('WeeklyPlanPreview shows Add button with tooltip when under 3 workouts', (WidgetTester tester) async {
    final plan = {
      'days': [
        {
          'day': 'Monday',
          'workouts': [
            {'type': 'Run'},
          ],
        }
      ]
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyPlanPreview(weeklyPlan: plan, userId: 'test-user'),
        ),
      ),
    );

    // Verify the single workout is shown
    expect(find.text('Run'), findsOneWidget);
    
    // Verify the 'Add' button is visible with tooltip message
    expect(find.text('Add'), findsOneWidget);
    expect(find.byTooltip('Add workout (max 3 per day)'), findsOneWidget);
  });

  testWidgets('WeeklyPlanPreview shows Max reached when day has 3 workouts', (WidgetTester tester) async {
    final plan = {
      'days': [
        {
          'day': 'Monday',
          'workouts': [
            {'type': 'Run'},
            {'type': 'Strength'},
            {'type': 'Swim'},
          ],
        }
      ]
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyPlanPreview(weeklyPlan: plan, userId: 'test-user'),
        ),
      ),
    );

    // Verify all three workouts are shown
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Swim'), findsOneWidget);

    // Verify 'Max reached' text is displayed
    expect(find.text('Max reached'), findsOneWidget);
    
    // Verify the disabled area has the max reached tooltip
    expect(find.byTooltip('Max 3 workouts per day'), findsOneWidget);
  });
}
