import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Enhanced theme service with support for multiple theme options
class ThemeService extends StateNotifier<AppThemeState> {
  static const String _themeKey = 'app_theme_mode';
  static const String _customThemeKey = 'custom_theme_colors';
  static const String _accentColorKey = 'accent_color';

  ThemeService() : super(const AppThemeState()) {
    _loadTheme();
  }

  /// Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeIndex = prefs.getInt(_themeKey) ?? AppThemeMode.system.index;
      final themeMode = AppThemeMode.values[themeModeIndex];
      
      // Load accent color
      final accentColorValue = prefs.getInt(_accentColorKey);
      Color? accentColor;
      if (accentColorValue != null) {
        accentColor = Color(accentColorValue);
      }
      
      // Load custom theme colors if any
      final customThemeData = prefs.getString(_customThemeKey);
      Map<String, dynamic>? customColors;
      if (customThemeData != null) {
        // Parse custom theme data (simplified for now)
        customColors = {};
      }

      state = state.copyWith(
        themeMode: themeMode,
        accentColor: accentColor,
        customColors: customColors,
      );
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      state = state.copyWith(themeMode: mode);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Set custom accent color
  Future<void> setAccentColor(Color color) async {
    try {
      state = state.copyWith(accentColor: color);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, color.value);
    } catch (e) {
      debugPrint('Error saving accent color: $e');
    }
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    try {
      state = const AppThemeState();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      await prefs.remove(_accentColorKey);
      await prefs.remove(_customThemeKey);
    } catch (e) {
      debugPrint('Error resetting theme: $e');
    }
  }

  /// Get current theme data based on brightness
  ThemeData getThemeData(Brightness brightness) {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return _buildLightTheme();
      case AppThemeMode.dark:
        return _buildDarkTheme();
      case AppThemeMode.system:
        return brightness == Brightness.dark ? _buildDarkTheme() : _buildLightTheme();
      case AppThemeMode.custom:
        return _buildCustomTheme(brightness);
    }
  }

  /// Build light theme with customizations
  ThemeData _buildLightTheme() {
    final baseTheme = AppTheme.lightTheme;
    
    if (state.accentColor != null) {
      return baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: state.accentColor,
          secondary: state.accentColor?.withOpacity(0.8),
        ),
      );
    }
    
    return baseTheme;
  }

  /// Build dark theme with customizations
  ThemeData _buildDarkTheme() {
    final baseTheme = AppTheme.darkTheme;
    
    if (state.accentColor != null) {
      return baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: state.accentColor,
          secondary: state.accentColor?.withOpacity(0.8),
        ),
      );
    }
    
    return baseTheme;
  }

  /// Build custom theme
  ThemeData _buildCustomTheme(Brightness brightness) {
    // For now, return the appropriate base theme
    // This can be expanded to support full custom theming
    return brightness == Brightness.dark ? _buildDarkTheme() : _buildLightTheme();
  }

  /// Get available accent colors
  static List<Color> get availableAccentColors => [
    AppColors.primary,
    AppColors.parentColor,
    AppColors.driverColor,
    AppColors.schoolAdminColor,
    AppColors.superAdminColor,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.deepOrange,
    Colors.cyan,
  ];

  /// Get theme mode display name
  static String getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.custom:
        return 'Custom';
    }
  }

  /// Get theme mode icon
  static IconData getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_brightness;
      case AppThemeMode.custom:
        return Icons.palette;
    }
  }
}

/// Theme state class
class AppThemeState {
  final AppThemeMode themeMode;
  final Color? accentColor;
  final Map<String, dynamic>? customColors;

  const AppThemeState({
    this.themeMode = AppThemeMode.system,
    this.accentColor,
    this.customColors,
  });

  AppThemeState copyWith({
    AppThemeMode? themeMode,
    Color? accentColor,
    Map<String, dynamic>? customColors,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      customColors: customColors ?? this.customColors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppThemeState &&
        other.themeMode == themeMode &&
        other.accentColor == accentColor &&
        other.customColors == customColors;
  }

  @override
  int get hashCode {
    return themeMode.hashCode ^ accentColor.hashCode ^ customColors.hashCode;
  }
}

/// Enhanced theme modes
enum AppThemeMode {
  light,
  dark,
  system,
  custom,
}

/// Theme service provider
final themeServiceProvider = StateNotifierProvider<ThemeService, AppThemeState>((ref) {
  return ThemeService();
});

/// Current theme data provider
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeServiceProvider);
  final themeService = ref.read(themeServiceProvider.notifier);
  
  // Get system brightness
  final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  
  return themeService.getThemeData(brightness);
});

/// Is dark mode provider
final isDarkModeProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeServiceProvider);
  final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  
  switch (themeState.themeMode) {
    case AppThemeMode.light:
      return false;
    case AppThemeMode.dark:
      return true;
    case AppThemeMode.system:
      return brightness == Brightness.dark;
    case AppThemeMode.custom:
      return brightness == Brightness.dark;
  }
});
