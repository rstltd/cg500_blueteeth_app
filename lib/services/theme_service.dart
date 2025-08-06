import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final StreamController<AppThemeMode> _themeModeController = 
      StreamController<AppThemeMode>.broadcast();
  final StreamController<bool> _isDarkModeController = 
      StreamController<bool>.broadcast();

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
        return 'Light Mode';
      case AppThemeMode.dark:
        return 'Dark Mode';
      case AppThemeMode.system:
        return 'System Theme';
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

// Theme-aware colors for custom widgets
class AppColors {
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : Colors.white;
  }

  static Color backgroundGradientStart(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : Colors.blue.shade50;
  }

  static Color backgroundGradientEnd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.indigo.shade50;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.grey.shade800;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
  }

  static Color shadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);
  }

  // Status colors that work in both themes
  static Color successColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade600;
  }

  static Color warningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.orange.shade400
        : Colors.orange.shade600;
  }

  static Color errorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.red.shade400
        : Colors.red.shade600;
  }

  static Color infoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade400
        : Colors.blue.shade600;
  }
}