import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workout_planner/main.dart';
import 'package:home_dashboard_ui/services/theme_controller.dart';
import 'package:home_dashboard_ui/services/theme_config_service.dart';
import 'package:home_dashboard_ui/services/auth_service.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App E2E Tests', () {
    testWidgets('Happy path flow', (WidgetTester tester) async {
      final themeSvc = ThemeConfigService();
      final cfg = await themeSvc.load();
      final controller = ThemeController(ThemeController.buildTheme(cfg.seedColor, dark: cfg.mode=='dark'));
      final authService = AuthService();

      await tester.pumpWidget(MyApp(
        isAuthenticated: true,
        isConfigured: true,
        themeController: controller,
        authService: authService,
        testMode: true,
      ));

      // App starts and shows loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Verify that the home screen is displayed
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Readiness: 0.8'), findsOneWidget);
      expect(find.text('Workout B'), findsOneWidget);
      expect(find.text('Focus: strength'), findsOneWidget);
    });
  });
}
