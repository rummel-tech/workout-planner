import 'package:flutter/material.dart';
import 'dart:math';
import 'package:logging/logging.dart';

import 'package:home_dashboard_ui/services/theme_controller.dart';
import 'package:home_dashboard_ui/services/theme_config_service.dart';
import 'package:home_dashboard_ui/screens/app_config_screen.dart';
import 'package:home_dashboard_ui/screens/home_screen.dart';
import 'package:home_dashboard_ui/screens/login_screen.dart';
import 'package:home_dashboard_ui/screens/register_screen.dart';
import 'package:workout_planner/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  final log = Logger('main');
  log.info("Starting app...");

  // In a real app, you'd use a service locator or dependency injection
  // to provide these services to the widget tree.
  final themeSvc = ThemeConfigService();
  final cfg = await themeSvc.load();
  final controller = ThemeController(ThemeController.buildTheme(cfg.seedColor, dark: cfg.mode=='dark'));

  // TODO: Check for a valid auth token here
  const bool isAuthenticated = false; // Replace with actual auth status

  runApp(MyApp(isAuthenticated: isAuthenticated, themeController: controller));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  final ThemeController themeController;
  final bool testMode;
  const MyApp({super.key, required this.isAuthenticated, required this.themeController, this.testMode = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeController,
      builder: (context, ThemeData theme, _) => MaterialApp(
      title: 'Workout-Planner',
      theme: theme,
      // TODO: Use a router like go_router for more complex navigation
      initialRoute: isAuthenticated ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/config': (context) => AppConfigScreen(controller: themeController),
        '/home': (context) => HomeDataLoader(themeController: themeController, testMode: testMode),
      },
    ));
  }
}

class HomeDataLoader extends StatefulWidget {
  final ThemeController themeController;
  final bool testMode;

  const HomeDataLoader({super.key, required this.themeController, this.testMode = false});

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
    // Simulate a network request
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would make an API call here.
    try {
      if (Random().nextBool()) {
        _log.info("Data fetched successfully.");
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
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e, s) {
      _log.severe('Failed to fetch data', e, s);
      rethrow;
    }
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
