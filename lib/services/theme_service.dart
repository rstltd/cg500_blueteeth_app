import 'dart:async';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  ThemeService()
      : _themeModeController = StreamController<AppThemeMode>.broadcast(),
        _isDarkModeController = StreamController<bool>.broadcast();

  /// Named constructor for testing that creates a fresh instance.
  ThemeService.forTesting()
      : _themeModeController = StreamController<AppThemeMode>.broadcast(),
        _isDarkModeController = StreamController<bool>.broadcast();

  final StreamController<AppThemeMode> _themeModeController;
  final StreamController<bool> _isDarkModeController;

  Stream<AppThemeMode> get themeModeStream => _themeModeController.stream;
  Stream<bool> get isDarkModeStream => _isDarkModeController.stream;

  AppThemeMode _currentThemeMode = AppThemeMode.system;
  bool _isDarkMode = false;
  bool _systemIsDarkMode = false;

  AppThemeMode get currentThemeMode => _currentThemeMode;
  bool get isDarkMode => _isDarkMode;
  bool get systemIsDarkMode => _systemIsDarkMode;

  void initialize() {
    _updateSystemTheme();
    _updateEffectiveTheme();
  }

  void _updateSystemTheme() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _systemIsDarkMode = brightness == Brightness.dark;
    _updateEffectiveTheme();
  }

  void _updateEffectiveTheme() {
    bool newIsDarkMode;
    
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        newIsDarkMode = false;
        break;
      case AppThemeMode.dark:
        newIsDarkMode = true;
        break;
      case AppThemeMode.system:
        newIsDarkMode = _systemIsDarkMode;
        break;
    }

    if (_isDarkMode != newIsDarkMode) {
      _isDarkMode = newIsDarkMode;
      _isDarkModeController.add(_isDarkMode);
      _updateSystemUIOverlay();
    }
  }

  void setThemeMode(AppThemeMode themeMode) {
    _currentThemeMode = themeMode;
    _themeModeController.add(_currentThemeMode);
    _updateEffectiveTheme();
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

  void _updateSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: _isDarkMode ? const Color(0xFF212121) : Colors.white,
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
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
    _isDarkModeController.close();
  }
}