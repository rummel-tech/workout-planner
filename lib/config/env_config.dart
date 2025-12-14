/// Environment configuration for multi-app support
///
/// This allows the app to run alongside other applications by providing
/// configurable API endpoints and application context.
library;

import 'package:flutter/foundation.dart';

class EnvConfig {
  // Application configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Workout Planner',
  );

  static const String appContext = String.fromEnvironment(
    'APP_CONTEXT',
    defaultValue: '',
  );

  // API configuration
  static String get apiBaseUrl {
    // Check for environment-specific override
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // Platform-specific defaults
    // Production AWS endpoint (update when IP changes or use domain name)
    const productionUrl = String.fromEnvironment(
      'PRODUCTION_API_URL',
      defaultValue: '',
    );

    if (kIsWeb) {
      final webUrl = const String.fromEnvironment('WEB_API_URL', defaultValue: '');
      if (webUrl.isNotEmpty) return webUrl;
      if (productionUrl.isNotEmpty) return productionUrl;
      // Development fallback
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidUrl = const String.fromEnvironment('ANDROID_API_URL', defaultValue: '');
      if (androidUrl.isNotEmpty) return androidUrl;
      if (productionUrl.isNotEmpty) return productionUrl;
      // Android emulator uses 10.0.2.2 to reach host localhost
      return 'http://10.0.2.2:8000';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosUrl = const String.fromEnvironment('IOS_API_URL', defaultValue: '');
      if (iosUrl.isNotEmpty) return iosUrl;
      if (productionUrl.isNotEmpty) return productionUrl;
      // iOS simulator can use localhost
      return 'http://localhost:8000';
    }

    // Fallback - use production URL if set, otherwise localhost
    if (productionUrl.isNotEmpty) return productionUrl;
    return 'http://localhost:8000';
  }

  // Full API URL with context path
  static String get fullApiBaseUrl {
    if (appContext.isEmpty) {
      return apiBaseUrl;
    }
    return '$apiBaseUrl$appContext';
  }

  // Feature flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false,
  );

  static const bool enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: kDebugMode,
  );

  // Environment detection
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => kReleaseMode;
  static bool get isWeb => kIsWeb;

  /// Print configuration for debugging
  static void printConfig() {
    if (!kDebugMode) return;

    print('=== EnvConfig ===');
    print('App Name: $appName');
    print('App Context: $appContext');
    print('API Base URL: $apiBaseUrl');
    print('Full API URL: $fullApiBaseUrl');
    print('Platform: ${defaultTargetPlatform.name}');
    print('Is Web: $isWeb');
    print('Debug Logs: $enableDebugLogs');
    print('================');
  }
}
