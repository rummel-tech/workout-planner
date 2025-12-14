import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/services/api_client.dart';
import 'package:home_dashboard_ui/services/theme_controller.dart';
import 'package:mobile_app/services/theme_config_service.dart';

class MockApiClient implements ApiClient {
  @override
  Future<Map<String, dynamic>> fetchData() async {
    return {
      "readiness": {
        "readiness": 0.8,
        "hrv": 55,
        "sleep_hours": 8,
        "resting_hr": 55,
        "recovery_level": "high",
        "limiting_factor": "none"
      },
      "dailyPlan": {
        "warmup": ["10 min"],
        "main": ["Workout B"],
        "cooldown": ["light stretch"]
      },
      "weeklyPlan": {
        "focus": "strength",
        "days": [
          {"day": "Monday", "type": "strength"},
          {"day": "Tuesday", "type": "run"},
          {"day": "Wednesday", "type": "rest"},
          {"day": "Thursday", "type": "strength"},
          {"day": "Friday", "type": "swim"},
          {"day": "Saturday", "type": "long run"},
          {"day": "Sunday", "type": "rest"},
        ],
      },
    };
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App E2E Tests', () {
    testWidgets('Happy path flow', (WidgetTester tester) async {
      final apiClient = MockApiClient();
      final themeSvc = ThemeConfigService();
      final cfg = await themeSvc.load();
      final controller = ThemeController(ThemeController.buildTheme(cfg.seedColor, dark: cfg.mode=='dark'));

      await tester.pumpWidget(MyApp(isAuthenticated: true, themeController: controller, testMode: true));

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
