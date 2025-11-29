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
    if (kIsWeb) {
      return const String.fromEnvironment(
        'WEB_API_URL',
        defaultValue: 'http://localhost:8000',
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator uses 10.0.2.2 to reach host
      // For physical device, use actual IP (set via ANDROID_DEVICE_API_URL)
      return const String.fromEnvironment(
        'ANDROID_API_URL',
        defaultValue: 'http://10.0.2.2:8000',
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS simulator can use localhost
      // For physical device, use actual IP (set via IOS_DEVICE_API_URL)
      return const String.fromEnvironment(
        'IOS_API_URL',
        defaultValue: 'http://localhost:8000',
      );
    }

    // Fallback
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
