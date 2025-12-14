import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Service for securely storing and retrieving app configuration.
/// Uses flutter_secure_storage for encrypted storage (Keychain on iOS, KeyStore on Android).
class SecureConfigService {
  static final SecureConfigService _instance = SecureConfigService._internal();
  factory SecureConfigService() => _instance;
  SecureConfigService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _configKey = 'app_secure_config_v1';
  static const String _apiBaseUrlKey = 'api_base_url';
  static const String _openAiApiKeyKey = 'openai_api_key';
  static const String _anthropicApiKeyKey = 'anthropic_api_key';
  static const String _aiProviderKey = 'ai_provider';
  static const String _configuredAtKey = 'configured_at';
  static const String _healthKitEnabledKey = 'healthkit_enabled';

  // Cache for faster access
  Map<String, dynamic>? _cache;

  /// Load all configuration from secure storage
  Future<Map<String, dynamic>> _loadConfig() async {
    if (_cache != null) return _cache!;

    try {
      final jsonStr = await _storage.read(key: _configKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _cache = json.decode(jsonStr) as Map<String, dynamic>;
        return _cache!;
      }
    } catch (e) {
      print('SecureConfigService: Error loading config: $e');
    }
    _cache = {};
    return _cache!;
  }

  /// Save configuration to secure storage
  Future<void> _saveConfig(Map<String, dynamic> config) async {
    try {
      _cache = config;
      await _storage.write(key: _configKey, value: json.encode(config));
    } catch (e) {
      print('SecureConfigService: Error saving config: $e');
      rethrow;
    }
  }

  /// Check if initial configuration has been completed
  Future<bool> isConfigured() async {
    final config = await _loadConfig();
    final apiUrl = config[_apiBaseUrlKey] as String?;
    return apiUrl != null && apiUrl.isNotEmpty;
  }

  /// Get the configured API base URL
  Future<String?> getApiBaseUrl() async {
    final config = await _loadConfig();
    return config[_apiBaseUrlKey] as String?;
  }

  /// Set the API base URL
  Future<void> setApiBaseUrl(String url) async {
    final config = await _loadConfig();
    config[_apiBaseUrlKey] = url.trim();
    config[_configuredAtKey] = DateTime.now().toIso8601String();
    await _saveConfig(config);
  }

  /// Get the selected AI provider ('openai', 'anthropic', or null)
  Future<String?> getAiProvider() async {
    final config = await _loadConfig();
    return config[_aiProviderKey] as String?;
  }

  /// Set the AI provider
  Future<void> setAiProvider(String provider) async {
    final config = await _loadConfig();
    config[_aiProviderKey] = provider;
    await _saveConfig(config);
  }

  /// Get OpenAI API key
  Future<String?> getOpenAiApiKey() async {
    final config = await _loadConfig();
    return config[_openAiApiKeyKey] as String?;
  }

  /// Set OpenAI API key
  Future<void> setOpenAiApiKey(String key) async {
    final config = await _loadConfig();
    config[_openAiApiKeyKey] = key.trim();
    await _saveConfig(config);
  }

  /// Get Anthropic API key
  Future<String?> getAnthropicApiKey() async {
    final config = await _loadConfig();
    return config[_anthropicApiKeyKey] as String?;
  }

  /// Set Anthropic API key
  Future<void> setAnthropicApiKey(String key) async {
    final config = await _loadConfig();
    config[_anthropicApiKeyKey] = key.trim();
    await _saveConfig(config);
  }

  /// Get the current AI API key based on selected provider
  Future<String?> getCurrentAiApiKey() async {
    final provider = await getAiProvider();
    if (provider == 'openai') {
      return getOpenAiApiKey();
    } else if (provider == 'anthropic') {
      return getAnthropicApiKey();
    }
    return null;
  }

  /// Check if HealthKit sync is enabled
  Future<bool> isHealthKitEnabled() async {
    final config = await _loadConfig();
    return config[_healthKitEnabledKey] as bool? ?? false;
  }

  /// Set HealthKit enabled status
  Future<void> setHealthKitEnabled(bool enabled) async {
    final config = await _loadConfig();
    config[_healthKitEnabledKey] = enabled;
    await _saveConfig(config);
  }

  /// Get when configuration was last updated
  Future<DateTime?> getConfiguredAt() async {
    final config = await _loadConfig();
    final timestamp = config[_configuredAtKey] as String?;
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Clear all configuration (for logout or reset)
  Future<void> clearConfig() async {
    _cache = null;
    await _storage.delete(key: _configKey);
  }

  /// Clear only API keys (keep server URL)
  Future<void> clearApiKeys() async {
    final config = await _loadConfig();
    config.remove(_openAiApiKeyKey);
    config.remove(_anthropicApiKeyKey);
    config.remove(_aiProviderKey);
    await _saveConfig(config);
  }

  /// Get a masked version of an API key for display
  String maskApiKey(String? key) {
    if (key == null || key.isEmpty) return 'Not configured';
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  /// Validate API URL format
  bool isValidApiUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Test connection to API server
  Future<bool> testApiConnection(String url) async {
    try {
      final uri = Uri.parse('$url/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('SecureConfigService: Connection test failed: $e');
      return false;
    }
  }

  /// Export configuration summary (for debugging, no secrets)
  Future<Map<String, dynamic>> getConfigSummary() async {
    final config = await _loadConfig();
    return {
      'apiBaseUrl': config[_apiBaseUrlKey] != null ? '(configured)' : null,
      'aiProvider': config[_aiProviderKey],
      'hasOpenAiKey': config[_openAiApiKeyKey] != null,
      'hasAnthropicKey': config[_anthropicApiKeyKey] != null,
      'healthKitEnabled': config[_healthKitEnabledKey] ?? false,
      'configuredAt': config[_configuredAtKey],
    };
  }
}
