import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application
/// Provides different log levels and conditional logging based on build mode
class Logger {
  static const String _tag = '[CG500_BLE]';
  
  /// Log levels
  static const int _debugLevel = 0;
  static const int _infoLevel = 1;
  static const int _warningLevel = 2;
  static const int _errorLevel = 3;
  
  /// Current log level - can be adjusted based on build configuration
  static int _currentLogLevel = kDebugMode ? _debugLevel : _errorLevel;
  
  /// Debug level logging - only shown in debug builds
  static void debug(String message, {String? tag}) {
    if (_currentLogLevel <= _debugLevel) {
      debugPrint('$_tag[DEBUG]${tag != null ? '[$tag]' : ''} $message');
    }
  }
  
  /// Info level logging
  static void info(String message, {String? tag}) {
    if (_currentLogLevel <= _infoLevel) {
      debugPrint('$_tag[INFO]${tag != null ? '[$tag]' : ''} $message');
    }
  }
  
  /// Warning level logging
  static void warning(String message, {String? tag}) {
    if (_currentLogLevel <= _warningLevel) {
      debugPrint('$_tag[WARN]${tag != null ? '[$tag]' : ''} $message');
    }
  }
  
  /// Error level logging - always shown
  static void error(String message, {String? tag, Object? error}) {
    if (_currentLogLevel <= _errorLevel) {
      debugPrint('$_tag[ERROR]${tag != null ? '[$tag]' : ''} $message');
      if (error != null) {
        debugPrint('$_tag[ERROR] Stack trace: $error');
      }
    }
  }
  
  /// Connection related logs
  static void connection(String message) {
    debug(message, tag: 'CONNECTION');
  }
  
  /// BLE service related logs
  static void ble(String message) {
    debug(message, tag: 'BLE');
  }
  
  /// UI related logs
  static void ui(String message) {
    debug(message, tag: 'UI');
  }
  
  /// Command communication logs
  static void command(String message) {
    debug(message, tag: 'COMMAND');
  }
  
  /// Set log level (useful for testing or debugging)
  static void setLogLevel(int level) {
    _currentLogLevel = level;
  }
  
  /// Log levels constants for external use
  static int get debugLevel => _debugLevel;
  static int get infoLevel => _infoLevel;
  static int get warningLevel => _warningLevel;
  static int get errorLevel => _errorLevel;
}