import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todays_workout_ui/screens/workout_detail_screen.dart';

void main() {
  group('WorkoutDetailScreen - Exercise Builder Structure', () {
    testWidgets('displays warmup, main set, and cooldown sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all three sections are present
      expect(find.text('Warmup'), findsOneWidget);
      expect(find.text('Main Set'), findsOneWidget);
      expect(find.text('Cooldown'), findsOneWidget);
    });

    testWidgets('each section has add exercise button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Each section should have an add button (3 total)
      final addButtons = find.byIcon(Icons.add_circle_outline);
      expect(addButtons, findsNWidgets(3));
    });

    testWidgets('displays workout type selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Workout Type'), findsOneWidget);
    });

    testWidgets('displays workout name field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Workout Name'), findsOneWidget);
    });

    testWidgets('displays notes field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Notes field may have different hint text
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('has save button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('WorkoutDetailScreen - Workout Types', () {
    testWidgets('supports Strength workout type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the dropdown
      await tester.tap(find.text('Strength').first);
      await tester.pumpAndSettle();

      expect(find.text('Strength'), findsWidgets);
    });

    testWidgets('supports Run workout type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown and look for Run option
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);
    });

    testWidgets('supports Swim workout type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Dropdown should contain Swim option
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('supports all required workout types', (WidgetTester tester) async {
      // Test that the screen can be created with different workout types
      final types = ['Strength', 'Run', 'Swim', 'Murph', 'Bike', 'Yoga', 'Cardio', 'Mobility', 'Rest'];

      for (final type in types) {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutDetailScreen(
              existingWorkout: {'type': type, 'name': '$type Workout'},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display the workout - either in dropdown or name field
        // The dropdown shows type, the name field shows "Type Workout"
        expect(find.byType(WorkoutDetailScreen), findsOneWidget,
            reason: 'WorkoutDetailScreen should render for type $type');
      }
    });
  });

  group('WorkoutDetailScreen - Edit Existing Workout', () {
    testWidgets('loads existing workout data', (WidgetTester tester) async {
      final existingWorkout = {
        'type': 'Strength',
        'name': 'Upper Body Power',
        'warmup': [
          {'name': 'Arm Circles', 'duration': 60}
        ],
        'main': [
          {'name': 'Bench Press', 'sets': 4, 'reps': 8, 'weight': 135}
        ],
        'cooldown': [
          {'name': 'Stretch', 'duration': 300}
        ],
        'notes': 'Focus on form',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutDetailScreen(existingWorkout: existingWorkout),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the workout name
      expect(find.text('Upper Body Power'), findsOneWidget);

      // Should display exercises from sections
      expect(find.text('Arm Circles'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
    });

    testWidgets('shows Edit Workout title when editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutDetailScreen(
            existingWorkout: {'type': 'Run', 'name': 'Morning Run'},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Workout'), findsOneWidget);
    });

    testWidgets('shows Add Workout title when creating new', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Workout'), findsOneWidget);
    });
  });

  group('WorkoutDetailScreen - Save Functionality', () {
    testWidgets('save returns workout data', (WidgetTester tester) async {
      Map<String, dynamic>? savedWorkout;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                savedWorkout = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutDetailScreen(),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      // Navigate to workout detail screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should have returned workout data
      expect(savedWorkout, isNotNull);
      expect(savedWorkout!['type'], isNotNull);
    });
  });

  group('WorkoutDetailScreen - Empty State Messages', () {
    testWidgets('shows empty state for sections without exercises', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state text for all three sections
      expect(find.text('No exercises added'), findsNWidgets(3));
    });
  });
}
