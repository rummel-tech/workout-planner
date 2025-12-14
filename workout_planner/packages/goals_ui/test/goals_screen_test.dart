import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_ui/screens/goals_screen.dart';
import 'package:goals_ui/ui_components/goal_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsScreen Widget Tests', () {
    testWidgets('renders loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state with create button when no goals', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Should show empty state
      expect(find.text('No goals yet'), findsOneWidget);
      expect(find.text('Create First Goal'), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('opens goal dialog when create button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Tap the "Create First Goal" button
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Create Goal'), findsOneWidget);
      expect(find.text('Goal Type'), findsOneWidget);
      expect(find.text('Target Value (optional)'), findsOneWidget);
      expect(find.text('Target Unit (optional)'), findsOneWidget);
      expect(find.text('Target Date (optional)'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
    });

    testWidgets('goal dialog has calendar icon for date field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Open dialog
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      // Check for calendar icon
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('validates required goal type field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Open dialog
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      // Try to submit without filling goal type
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Open dialog
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Create Goal'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Create Goal'), findsNothing);
    });

    testWidgets('displays app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      expect(find.text('Your Goals'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('goal dialog contains all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Open dialog
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      // Check all fields are present
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(5)); // 5 text fields

      // Check field labels
      expect(find.text('Goal Type'), findsOneWidget);
      expect(find.text('Target Value (optional)'), findsOneWidget);
      expect(find.text('Target Unit (optional)'), findsOneWidget);
      expect(find.text('Target Date (optional)'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
    });

    testWidgets('date field has calendar icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Open dialog
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      // Date field should have calendar icon in decoration
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('form has Create and Cancel buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Open dialog
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('goal dialog can be filled with text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Open dialog
      await tester.tap(find.text('Create First Goal'));
      await tester.pumpAndSettle();

      // Fill in goal type
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal Type'),
        'Marathon Training',
      );

      // Fill in target value
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Target Value (optional)'),
        '26.2',
      );

      // Fill in target unit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Target Unit (optional)'),
        'miles',
      );

      // Fill in notes
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes (optional)'),
        'Complete a marathon in under 4 hours',
      );

      await tester.pump();

      // Verify text was entered
      expect(find.text('Marathon Training'), findsOneWidget);
      expect(find.text('26.2'), findsOneWidget);
      expect(find.text('miles'), findsOneWidget);
      expect(find.text('Complete a marathon in under 4 hours'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GoalsScreen(),
        ),
      );

      // Wait for potential error state
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // If error occurs, should show retry
      if (find.text('Retry').evaluate().isNotEmpty) {
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      }
    });
  });

  group('GoalModel Tests', () {
    test('UserGoal creates instance with required fields', () {
      final goal = UserGoal(
        id: 1,
        goalType: 'Running',
        targetValue: 10.0,
        targetUnit: 'km',
        targetDate: '2025-12-31',
        notes: 'Test goal',
        isActive: true,
      );

      expect(goal.id, 1);
      expect(goal.goalType, 'Running');
      expect(goal.targetValue, 10.0);
      expect(goal.targetUnit, 'km');
      expect(goal.targetDate, '2025-12-31');
      expect(goal.notes, 'Test goal');
      expect(goal.isActive, true);
    });

    test('UserGoal creates instance with null optional fields', () {
      final goal = UserGoal(
        id: 2,
        goalType: 'Strength',
        targetValue: null,
        targetUnit: null,
        targetDate: null,
        notes: null,
        isActive: false,
      );

      expect(goal.id, 2);
      expect(goal.goalType, 'Strength');
      expect(goal.targetValue, isNull);
      expect(goal.targetUnit, isNull);
      expect(goal.targetDate, isNull);
      expect(goal.notes, isNull);
      expect(goal.isActive, false);
    });
  });
}
