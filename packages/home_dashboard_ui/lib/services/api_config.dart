import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API configuration for all services.
///
/// Configure via:
/// - Environment variable: `API_BASE_URL` (highest priority)
/// - Runtime: `ApiConfig.configure(baseUrl: 'https://api.example.com')`
/// - Default: platform-specific defaults (localhost for web, 10.0.2.2 for Android)
class ApiConfig {
  static String? _overrideBaseUrl;

  /// Configure the API base URL at runtime.
  /// Call this in main() before using any services.
  static void configure({String? baseUrl}) {
    _overrideBaseUrl = baseUrl;
  }

  /// Get the configured API base URL.
  /// Priority: runtime override > environment variable > platform default
  static String get baseUrl {
    // Runtime override takes highest priority
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    // Check environment variable
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // Platform-specific defaults
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      // Default to Android emulator host mapping for mobile
      return 'http://10.0.2.2:8000';
    }
  }

  /// Default timeout for API requests
  static const Duration defaultTimeout = Duration(seconds: 10);
}
