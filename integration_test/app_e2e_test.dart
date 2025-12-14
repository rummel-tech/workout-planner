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
        isConfigured: true,
        themeController: controller,
        authService: authService,
        testMode: true,
      ));

      // Wait for the app to load
      await tester.pumpAndSettle();

      // App starts at welcome screen (no auto-login)
      expect(find.text('Welcome'), findsWidgets);
    });
  });
}
