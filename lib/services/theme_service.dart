import 'dart:async';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

// Re-export AppColors for backward compatibility
// New code should import from '../utils/app_colors.dart' directly
export '../utils/app_colors.dart' show AppColors;

enum AppThemeMode {
  light,
  dark,
  system,
}

/// Service for managing app theme (light/dark mode).
///
/// Use [ThemeService()] constructor and register via service locator
/// for production use.
class ThemeService {
  /// Default constructor for dependency injection via service locator.
  ThemeService() : _themeModeController = StreamController<AppThemeMode>.broadcast();

  /// Named constructor for testing that creates a fresh instance.
  ThemeService.forTesting() : _themeModeController = StreamController<AppThemeMode>.broadcast();

  final StreamController<AppThemeMode> _themeModeController;

  Stream<AppThemeMode> get themeModeStream => _themeModeController.stream;

  AppThemeMode _currentThemeMode = AppThemeMode.system;

  AppThemeMode get currentThemeMode => _currentThemeMode;

  void initialize() {}

  void setThemeMode(AppThemeMode themeMode) {
    _currentThemeMode = themeMode;
    _themeModeController.add(_currentThemeMode);
  }

  void toggleTheme() {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        setThemeMode(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        setThemeMode(AppThemeMode.system);
        break;
      case AppThemeMode.system:
        setThemeMode(AppThemeMode.light);
        break;
    }
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey.shade50,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  String get themeModeDescription {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return AppStrings.themeModeLight;
      case AppThemeMode.dark:
        return AppStrings.themeModeDark;
      case AppThemeMode.system:
        return AppStrings.themeModeSystem;
    }
  }

  IconData get themeModeIcon {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void dispose() {
    _themeModeController.close();
  }
}