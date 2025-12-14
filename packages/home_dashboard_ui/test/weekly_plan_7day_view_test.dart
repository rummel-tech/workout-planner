import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/weekly_plan_edit_screen.dart';

void main() {
  group('Weekly Planner - 7-Day View', () {
    testWidgets('displays all 7 days of the week', (WidgetTester tester) async {
      final plan = {
        'days': [],
        'focus': 'General Fitness',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 7 days are displayed
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('displays workouts for each day', (WidgetTester tester) async {
      final plan = {
        'days': [
          {'day': 'Monday', 'workouts': [{'type': 'Strength', 'name': 'Upper Body'}]},
          {'day': 'Tuesday', 'workouts': [{'type': 'Run', 'name': 'Morning Run'}]},
          {'day': 'Wednesday', 'workouts': [{'type': 'Swim', 'name': 'Laps'}]},
          {'day': 'Thursday', 'workouts': [{'type': 'Rest', 'name': 'Rest'}]},
          {'day': 'Friday', 'workouts': [{'type': 'Strength', 'name': 'Lower Body'}]},
          {'day': 'Saturday', 'workouts': [{'type': 'Cardio', 'name': 'HIIT'}]},
          {'day': 'Sunday', 'workouts': [{'type': 'Yoga', 'name': 'Recovery'}]},
        ],
        'focus': 'Hybrid Training',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify workouts are displayed
      expect(find.text('Upper Body'), findsOneWidget);
      expect(find.text('Morning Run'), findsOneWidget);
    });

    testWidgets('each day can have multiple workouts displayed', (WidgetTester tester) async {
      final plan = {
        'days': [
          {
            'day': 'Monday',
            'workouts': [
              {'type': 'Run', 'name': 'Morning Run'},
              {'type': 'Strength', 'name': 'Weights'},
            ]
          },
        ],
        'focus': 'General Fitness',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify multiple workouts on one day
      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Weights'), findsOneWidget);
    });

    testWidgets('displays workout icons for different types', (WidgetTester tester) async {
      final plan = {
        'days': [
          {'day': 'Monday', 'workouts': [{'type': 'Strength', 'name': 'Strength'}]},
          {'day': 'Tuesday', 'workouts': [{'type': 'Run', 'name': 'Run'}]},
          {'day': 'Wednesday', 'workouts': [{'type': 'Swim', 'name': 'Swim'}]},
        ],
        'focus': 'Triathlon',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify workout type icons are displayed
      expect(find.byIcon(Icons.fitness_center), findsWidgets); // Strength
      expect(find.byIcon(Icons.directions_run), findsWidgets); // Run
      expect(find.byIcon(Icons.pool), findsWidgets); // Swim
    });
  });

  group('Weekly Planner - Day Editing', () {
    testWidgets('has add workout button for each day', (WidgetTester tester) async {
      final plan = {
        'days': [
          {'day': 'Monday', 'workouts': [{'type': 'Run', 'name': 'Run'}]},
        ],
        'focus': 'General Fitness',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have Add Workout buttons
      expect(find.text('Add Workout'), findsWidgets);
    });

    testWidgets('workouts are tappable for editing', (WidgetTester tester) async {
      final plan = {
        'days': [
          {'day': 'Monday', 'workouts': [{'type': 'Strength', 'name': 'Upper Body'}]},
        ],
        'focus': 'General Fitness',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the workout and verify it's tappable (wrapped in InkWell)
      final inkWell = find.ancestor(
        of: find.text('Upper Body'),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
    });

    testWidgets('has remove workout button for each workout', (WidgetTester tester) async {
      final plan = {
        'days': [
          {'day': 'Monday', 'workouts': [{'type': 'Run', 'name': 'Run'}]},
        ],
        'focus': 'General Fitness',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have close/remove icons
      expect(find.byIcon(Icons.close), findsWidgets);
    });
  });

  group('Weekly Planner - Screen Structure', () {
    testWidgets('has app bar with title', (WidgetTester tester) async {
      final plan = {'days': [], 'focus': 'General Fitness'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Edit Weekly Plan'), findsOneWidget);
    });

    testWidgets('days are scrollable horizontally', (WidgetTester tester) async {
      final plan = {'days': [], 'focus': 'General Fitness'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPlanEditScreen(initialPlan: plan, userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have a horizontal scroll view
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
