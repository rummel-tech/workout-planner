import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';

class ThemeConfig {
  final int seedColor; // ARGB int
  final String mode; // 'light' | 'dark'
  const ThemeConfig({required this.seedColor, this.mode = 'light'});

  Map<String, dynamic> toJson() => {
    'seedColor': seedColor,
    'mode': mode,
  };
  static ThemeConfig fromJson(Map<String, dynamic> j){
    return ThemeConfig(
      seedColor: (j['seedColor'] is int) ? j['seedColor'] as int : 0xFF2196F3,
      mode: (j['mode'] as String?) ?? 'light',
    );
  }
}

class ThemeConfigService {
  static const _key = 'app_theme_config_v1';

  Future<ThemeConfig> load() async {
    try {
      if (kIsWeb) {
        final raw = getItem(_key);
        if (raw == null) return const ThemeConfig(seedColor: 0xFF2196F3);
        final map = json.decode(raw) as Map<String, dynamic>;
        return ThemeConfig.fromJson(map);
      }
      // Mobile path (could use shared_prefs). For now, fallback default.
      return const ThemeConfig(seedColor: 0xFF2196F3);
    } catch (_) {
      return const ThemeConfig(seedColor: 0xFF2196F3);
    }
  }

  Future<void> save(ThemeConfig cfg) async {
    try {
      final raw = json.encode(cfg.toJson());
      if (kIsWeb) setItem(_key, raw);
      // Mobile path: no-op for now
    } catch (_) {}
  }
}
