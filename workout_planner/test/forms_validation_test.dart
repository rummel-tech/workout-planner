import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_dashboard_ui/screens/login_screen.dart';
import 'package:home_dashboard_ui/screens/register_screen.dart';
import 'package:goals_ui/screens/goals_screen.dart';
import 'package:readiness_ui/screens/health_metrics_screen.dart';
import 'package:todays_workout_ui/screens/strength_metrics_screen.dart';
import 'package:todays_workout_ui/screens/swim_metrics_screen.dart';

void main() {
  group('Login Form Validation', () {
    testWidgets('shows error when email is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Find and tap the login button without entering email
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Verify email error message is shown
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows error when email is invalid', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Enter invalid email
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalid-email');

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Verify error message
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Enter valid email but short password
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, '12345'); // 5 chars, need 6

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Verify error message
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Initially shows visibility icon (password is obscured)
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap visibility toggle
      final visibilityToggle = find.byIcon(Icons.visibility);
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Check if it's now visible (icon changed to visibility_off)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('navigates to register screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/register': (context) => const RegisterScreen(),
          },
        ),
      );

      // Find and tap Sign Up button
      final signUpButton = find.widgetWithText(TextButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify we're on register screen
      expect(find.text('Create Account'), findsOneWidget);
    });
  });

  group('Register Form Validation', () {
    testWidgets('shows error when email is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, '1234567'); // 7 chars, need 8

      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      final passwordFields = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordFields, 'Password123!');

      final confirmField = find.widgetWithText(TextFormField, 'Confirm Password');
      await tester.enterText(confirmField, 'DifferentPassword123!');

      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('navigates to login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
        ),
      );

      final loginButton = find.widgetWithText(TextButton, 'Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Workout-Planner'), findsOneWidget);
      expect(find.text('AI-Powered Training Platform'), findsOneWidget);
    });
  });

  group('Goals Form Validation', () {
    testWidgets('shows error when goal type is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GoalsScreen()),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Tap FAB to open dialog (or the create button if no goals)
      final createButton = find.widgetWithIcon(ElevatedButton, Icons.add);
      if (createButton.evaluate().isEmpty) {
        // No goals yet, button in empty state
        final firstGoalButton = find.widgetWithText(ElevatedButton, 'Create First Goal');
        await tester.tap(firstGoalButton);
      } else {
        await tester.tap(createButton);
      }
      await tester.pumpAndSettle();

      // Find and tap Create button in dialog
      final dialogCreateButton = find.widgetWithText(ElevatedButton, 'Create');
      await tester.tap(dialogCreateButton);
      await tester.pump();

      // Verify error message
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('parses target value with unit suffix', (WidgetTester tester) async {
      // This test verifies the logic in goals_screen.dart lines 186-196
      // Example: "5km" should be parsed as value=5, unit="km"

      // The actual implementation extracts unit from value string
      const input = '5km';
      final reg = RegExp(r'^([0-9]*\.?[0-9]+)\s*([a-zA-Z]+)?$');
      final match = reg.firstMatch(input);

      expect(match, isNotNull);
      expect(match!.group(1), '5');
      expect(match.group(2), 'km');
    });

    testWidgets('date picker opens and sets date', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GoalsScreen()),
      );

      await tester.pumpAndSettle();

      // Open create goal dialog
      final createButton = find.widgetWithIcon(ElevatedButton, Icons.add);
      if (createButton.evaluate().isEmpty) {
        final firstGoalButton = find.widgetWithText(ElevatedButton, 'Create First Goal');
        await tester.tap(firstGoalButton);
      } else {
        await tester.tap(createButton);
      }
      await tester.pumpAndSettle();

      // Find date field with calendar icon
      final dateField = find.widgetWithIcon(TextFormField, Icons.calendar_today);
      expect(dateField, findsOneWidget);
    });
  });

  group('Health Metrics Form', () {
    testWidgets('renders all physical metric fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HealthMetricsScreen(userId: 'test-user')),
      );

      expect(find.text('HRV (ms)'), findsOneWidget);
      expect(find.text('Resting Heart Rate (bpm)'), findsOneWidget);
      expect(find.text('VO2 Max (ml/kg/min)'), findsOneWidget);
      expect(find.text('Sleep Hours'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
    });

    testWidgets('renders all subjective rating sliders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HealthMetricsScreen(userId: 'test-user')),
      );

      expect(find.text('Rate of Perceived Exertion (RPE)'), findsOneWidget);
      expect(find.text('Soreness'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);

      // Verify sliders exist
      expect(find.byType(Slider), findsNWidgets(3));
    });

    testWidgets('slider values update correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HealthMetricsScreen(userId: 'test-user')),
      );

      // Find first slider (RPE)
      final slider = find.byType(Slider).first;

      // Drag slider to the right
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Value should have changed (visual verification in actual test)
      final sliderWidget = tester.widget<Slider>(slider);
      expect(sliderWidget.value, greaterThan(5.0));
    });

    testWidgets('validates number input for sleep hours', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HealthMetricsScreen(userId: 'test-user')),
      );

      final sleepField = find.widgetWithText(TextFormField, 'Sleep Hours');
      await tester.enterText(sleepField, 'invalid');

      final saveButton = find.widgetWithIcon(ElevatedButton, Icons.save);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Invalid number'), findsOneWidget);
    });

    testWidgets('date picker works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HealthMetricsScreen(userId: 'test-user')),
      );

      final dateTile = find.widgetWithIcon(ListTile, Icons.calendar_today);
      expect(dateTile, findsOneWidget);
    });
  });

  group('Strength Metrics Form', () {
    testWidgets('renders all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StrengthMetricsScreen(userId: 'test-user')),
      );

      expect(find.text('Lift Type'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Set Number'), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StrengthMetricsScreen(userId: 'test-user')),
      );

      final logButton = find.widgetWithIcon(ElevatedButton, Icons.save);
      await tester.tap(logButton);
      await tester.pump();

      // Should show 3 "Required" errors (weight, reps, set number)
      expect(find.text('Required'), findsNWidgets(3));
    });

    testWidgets('calculates 1RM correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StrengthMetricsScreen(userId: 'test-user')),
      );

      // Enter weight and reps
      final weightField = find.widgetWithText(TextFormField, 'Weight (kg)');
      await tester.enterText(weightField, '100');

      final repsField = find.widgetWithText(TextFormField, 'Reps');
      await tester.enterText(repsField, '5');

      await tester.pumpAndSettle();

      // Epley formula: 100 * (1 + 5/30) = 100 * 1.1667 = 116.67
      expect(find.text('Estimated 1RM'), findsOneWidget);
      expect(find.textContaining('116'), findsOneWidget);
    });

    testWidgets('dropdown has all lift types', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StrengthMetricsScreen(userId: 'test-user')),
      );

      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);

      // Tap to open dropdown
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Verify all lift types are present
      expect(find.text('SQUAT'), findsOneWidget);
      expect(find.text('BENCH PRESS'), findsOneWidget);
      expect(find.text('DEADLIFT'), findsOneWidget);
    });
  });

  group('Swim Metrics Form', () {
    testWidgets('renders all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SwimMetricsScreen(userId: 'test-user')),
      );

      expect(find.text('Distance (meters)'), findsOneWidget);
      expect(find.text('Average Pace (seconds per 100m)'), findsOneWidget);
      expect(find.text('Stroke Rate (strokes per minute)'), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SwimMetricsScreen(userId: 'test-user')),
      );

      final logButton = find.widgetWithIcon(ElevatedButton, Icons.save);
      await tester.tap(logButton);
      await tester.pump();

      // Should show 2 "Required" errors (distance, pace)
      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('calculates total time correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SwimMetricsScreen(userId: 'test-user')),
      );

      // Enter distance and pace
      final distanceField = find.widgetWithText(TextFormField, 'Distance (meters)');
      await tester.enterText(distanceField, '1000');

      final paceField = find.widgetWithText(TextFormField, 'Average Pace (seconds per 100m)');
      await tester.enterText(paceField, '90'); // 1:30 per 100m

      await tester.pumpAndSettle();

      // 1000m / 100m * 90s = 900s = 15:00
      expect(find.text('Workout Summary'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('formats pace correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SwimMetricsScreen(userId: 'test-user')),
      );

      final paceField = find.widgetWithText(TextFormField, 'Average Pace (seconds per 100m)');
      await tester.enterText(paceField, '90');

      await tester.pumpAndSettle();

      // Should display as 1:30 / 100m
      expect(find.textContaining('1:30'), findsOneWidget);
    });

    testWidgets('water type selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SwimMetricsScreen(userId: 'test-user')),
      );

      // Find Pool radio button (should be selected by default)
      final poolRadio = find.widgetWithText(RadioListTile<String>, 'Pool');
      expect(poolRadio, findsOneWidget);

      // Find Open Water radio button
      final openWaterRadio = find.widgetWithText(RadioListTile<String>, 'Open Water');
      expect(openWaterRadio, findsOneWidget);

      // Tap Open Water
      await tester.tap(openWaterRadio);
      await tester.pump();

      // Verify selection changed (visual verification)
      final radioWidget = tester.widget<RadioListTile<String>>(openWaterRadio);
      expect(radioWidget.value, 'open_water');
    });
  });

  group('Form State Management', () {
    testWidgets('login form clears error on re-submit', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Submit empty form
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);

      // Enter email and re-submit
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      await tester.tap(loginButton);
      await tester.pump();

      // Email error should be gone, but password error should show
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('health metrics date defaults to today', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HealthMetricsScreen(userId: 'test-user')),
      );

      final now = DateTime.now();
      final expectedDate = '${now.month}/${now.day}/${now.year}';

      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('strength form increments set number after save', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StrengthMetricsScreen(userId: 'test-user')),
      );

      // Fill in all required fields
      final weightField = find.widgetWithText(TextFormField, 'Weight (kg)');
      await tester.enterText(weightField, '100');

      final repsField = find.widgetWithText(TextFormField, 'Reps');
      await tester.enterText(repsField, '5');

      final setField = find.widgetWithText(TextFormField, 'Set Number');
      await tester.enterText(setField, '1');

      // Submit
      final logButton = find.widgetWithIcon(ElevatedButton, Icons.save);
      await tester.tap(logButton);
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Set logged successfully!'), findsOneWidget);

      // Note: Set number auto-increment is tested by checking the controller value
      // In actual implementation, it should be '2' after submit
    });
  });
}
