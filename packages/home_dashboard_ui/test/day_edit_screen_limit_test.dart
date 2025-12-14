import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/day_edit_screen.dart';

void main() {
  testWidgets('DayEditScreen allows adding workouts up to 3', (WidgetTester tester) async {
    final dayData = {
      'day': 'Monday',
      'workouts': [
        {'type': 'Run'},
      ]
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayEditScreen(dayName: 'Monday', dayData: dayData, userId: 'test-user'),
        ),
      ),
    );

    // Verify the existing workout is shown
    expect(find.text('Run'), findsOneWidget);

    // Verify the add workout button is visible
    final addButtons = find.byIcon(Icons.add_circle_outline);
    expect(addButtons, findsWidgets);
  });

  testWidgets('DayEditScreen shows snackbar when adding 4th workout', (WidgetTester tester) async {
    final dayData = {
      'day': 'Monday',
      'workouts': [
        {'type': 'Run'},
        {'type': 'Strength'},
        {'type': 'Swim'},
      ]
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayEditScreen(dayName: 'Monday', dayData: dayData, userId: 'test-user'),
        ),
      ),
    );

    // Verify all three workouts are shown
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Swim'), findsOneWidget);

    // Find and tap the add button
    final addButton = find.byIcon(Icons.add_circle_outline);
    expect(addButton, findsOneWidget);
    
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify the snackbar message appears
    expect(find.text('Maximum 3 workouts per day'), findsOneWidget);
  });
}
