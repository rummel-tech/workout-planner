import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:home_dashboard_ui/services/theme_controller.dart';
import 'package:home_dashboard_ui/services/theme_config_service.dart';
import 'package:home_dashboard_ui/services/auth_service.dart';
import 'package:home_dashboard_ui/services/secure_config_service.dart';
import 'package:home_dashboard_ui/services/api_config.dart';
import 'package:home_dashboard_ui/screens/app_config_screen.dart';
import 'package:home_dashboard_ui/screens/home_screen.dart';
import 'package:home_dashboard_ui/screens/login_screen.dart';
import 'package:home_dashboard_ui/screens/register_screen.dart';
import 'package:home_dashboard_ui/screens/forgot_password_screen.dart';
import 'package:home_dashboard_ui/screens/welcome_screen.dart';
import 'package:home_dashboard_ui/screens/setup_wizard_screen.dart';
import 'package:workout_planner/logging.dart';

/// Global navigator key for navigation from outside widget tree (e.g., auth failure)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  final log = Logger('main');
  log.info("Starting app...");

  // Load theme configuration
  final themeSvc = ThemeConfigService();
  final cfg = await themeSvc.load();
  final controller = ThemeController(ThemeController.buildTheme(cfg.seedColor, dark: cfg.mode=='dark'));

  final authService = AuthService();

  // Set up auth failure callback to redirect to login
  authService.onAuthFailure = () {
    log.info("Auth failure - redirecting to login");
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  // Check if app is configured (API URL set)
  final secureConfig = SecureConfigService();
  final isConfigured = await secureConfig.isConfigured();
  log.info("Config status: $isConfigured");

  // Initialize API config from secure storage if configured
  if (isConfigured) {
    final apiUrl = await secureConfig.getApiBaseUrl();
    if (apiUrl != null) {
      // Fix: If the stored URL is pointing to frontend port (8080), correct it to backend port (8000)
      final correctedUrl = apiUrl.replaceAll(':8080', ':8000');
      if (correctedUrl != apiUrl) {
        log.warning("Detected incorrect API URL ($apiUrl), correcting to: $correctedUrl");
        await secureConfig.setApiBaseUrl(correctedUrl);
        ApiConfig.configure(baseUrl: correctedUrl);
        log.info("API URL corrected and saved: $correctedUrl");
      } else {
        ApiConfig.configure(baseUrl: apiUrl);
        log.info("API URL set from secure config: $apiUrl");
      }
    }
  }

  runApp(MyApp(
    isConfigured: isConfigured,
    themeController: controller,
    authService: authService,
  ));
}

class MyApp extends StatelessWidget {
  final bool isConfigured;
  final ThemeController themeController;
  final AuthService authService;
  final bool testMode;
  const MyApp({
    super.key,
    required this.isConfigured,
    required this.themeController,
    required this.authService,
    this.testMode = false,
  });

  // Always start at welcome screen - no auto-login
  String get _initialRoute => '/welcome';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeController,
      builder: (context, ThemeData theme, _) => MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Workout-Planner',
      theme: theme,
      initialRoute: _initialRoute,
      routes: {
        '/setup': (context) => const SetupWizardScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/config': (context) => AppConfigScreen(controller: themeController),
        '/home': (context) => HomeDataLoader(
          themeController: themeController,
          authService: authService,
          testMode: testMode,
        ),
      },
    ));
  }
}

class HomeDataLoader extends StatefulWidget {
  final ThemeController themeController;
  final AuthService authService;
  final bool testMode;

  const HomeDataLoader({
    super.key,
    required this.themeController,
    required this.authService,
    this.testMode = false,
  });

  @override
  _HomeDataLoaderState createState() => _HomeDataLoaderState();
}

class _HomeDataLoaderState extends State<HomeDataLoader> {
  late Future<Map<String, dynamic>> _dataFuture;
  final _log = Logger('HomeDataLoader');

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    _log.info("Fetching data...");

    // Return default data for now - the HomeScreen will load real data from APIs
    _log.info("Data fetched successfully.");
    return {
      "readiness": {
        "readiness": 0.0,
        "hrv": 0,
        "sleep_hours": 0,
        "resting_hr": 0,
        "recovery_level": "unknown",
        "limiting_factor": "none"
      },
      "dailyPlan": {
        "warmup": [],
        "main": [],
        "cooldown": []
      },
      "weeklyPlan": {
        "focus": "general",
        "days": [
          {"day": "Monday", "type": "rest"},
          {"day": "Tuesday", "type": "rest"},
          {"day": "Wednesday", "type": "rest"},
          {"day": "Thursday", "type": "rest"},
          {"day": "Friday", "type": "rest"},
          {"day": "Saturday", "type": "rest"},
          {"day": "Sunday", "type": "rest"},
        ],
      },
    };
  }

  void _retry() {
    _log.info("Retrying data fetch...");
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          _log.warning("FutureBuilder has error", snapshot.error, snapshot.stackTrace);
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load data'),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          return HomeScreen(
            readiness: data['readiness'],
            dailyPlan: data['dailyPlan'],
            weeklyPlan: data['weeklyPlan'],
            testMode: widget.testMode,
            themeController: widget.themeController,
            authService: widget.authService,
          );
        } else {
          return const Scaffold(
            body: Center(child: Text('No data')),
          );
        }
      },
    );
  }
}
