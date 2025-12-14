import 'package:flutter/material.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';
import 'theme_config_service.dart';

class ThemeController extends ValueNotifier<ThemeData> {
  ThemeController(ThemeData value) : super(value);

  static ThemeData buildTheme(int seedColor, {bool dark=false}) {
    // Use RummelBlueTheme as default if seed color matches primary
    if (seedColor == RummelBlueColors.primary500.value) {
      return dark ? RummelBlueTheme.dark() : RummelBlueTheme.light();
    }

    // Allow custom seed colors for user customization
    final color = Color(seedColor);
    final scheme = ColorScheme.fromSeed(
      brightness: dark ? Brightness.dark : Brightness.light,
      seedColor: color,
    );

    // Build custom theme matching RummelBlueTheme structure
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceVariant,
        selectedColor: scheme.primaryContainer,
      ),
    );
  }

  Future<void> apply(ThemeConfig cfg) async {
    value = buildTheme(cfg.seedColor, dark: cfg.mode == 'dark');
  }
}
