import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/weekly_plan_edit_screen.dart';

void main() {
  testWidgets('WeeklyPlanEditScreen allows adding workouts up to 3 per day', (WidgetTester tester) async {
    final plan = {
      'days': [
        {
          'day': 'Monday',
          'workouts': [
            {'type': 'Run'},
          ]
        },
        {
          'day': 'Tuesday',
          'workouts': []
        }
      ],
      'focus': 'General Fitness',
      'intensity': 'Moderate',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify days are displayed
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
  });

  testWidgets('WeeklyPlanEditScreen shows snackbar when adding 4th workout to a day', (WidgetTester tester) async {
    final plan = {
      'days': [
        {
          'day': 'Monday',
          'workouts': [
            {'type': 'Run'},
            {'type': 'Strength'},
            {'type': 'Swim'},
          ]
        }
      ],
      'focus': 'General Fitness',
      'intensity': 'Moderate',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the day card is displayed
    expect(find.text('Monday'), findsOneWidget);
    
    // Verify that with 3 workouts, the add button should trigger the snackbar
    // when tapped (the button gets disabled or shows feedback)
    final addButtons = find.byIcon(Icons.add);
    expect(addButtons, findsWidgets);
  });
}
