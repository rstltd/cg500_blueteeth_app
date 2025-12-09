import 'package:flutter/material.dart';

/// Danger level for device commands.
///
/// Used to determine if a command requires user confirmation before execution.
enum DangerLevel {
  /// Safe commands - no confirmation needed
  /// Examples: $CMD, $INFO, $MAC
  safe,

  /// Warning level - command has side effects but recoverable
  /// Examples: $DEBUG (requires device restart to recover)
  warning,

  /// Dangerous commands - requires explicit confirmation
  /// Examples: $STARTX (restarts MCU, disconnects all connections)
  dangerous,
}

/// Extension methods for [DangerLevel].
extension DangerLevelExtension on DangerLevel {
  /// Returns whether user confirmation is required.
  bool get requiresConfirmation {
    switch (this) {
      case DangerLevel.safe:
        return false;
      case DangerLevel.warning:
        return true;
      case DangerLevel.dangerous:
        return true;
    }
  }

  /// Returns the display name for the danger level.
  String get displayName {
    switch (this) {
      case DangerLevel.safe:
        return '安全';
      case DangerLevel.warning:
        return '警告';
      case DangerLevel.dangerous:
        return '危險';
    }
  }

  /// Returns the color associated with this danger level.
  Color get color {
    switch (this) {
      case DangerLevel.safe:
        return Colors.green;
      case DangerLevel.warning:
        return Colors.orange;
      case DangerLevel.dangerous:
        return Colors.red;
    }
  }

  /// Returns the icon for this danger level.
  IconData get icon {
    switch (this) {
      case DangerLevel.safe:
        return Icons.check_circle_outline;
      case DangerLevel.warning:
        return Icons.warning_amber_outlined;
      case DangerLevel.dangerous:
        return Icons.dangerous_outlined;
    }
  }

  /// Returns the confirmation dialog title.
  String get confirmationTitle {
    switch (this) {
      case DangerLevel.safe:
        return '確認執行';
      case DangerLevel.warning:
        return '注意';
      case DangerLevel.dangerous:
        return '警告：危險操作';
    }
  }

  /// Returns the confirmation button text.
  String get confirmButtonText {
    switch (this) {
      case DangerLevel.safe:
        return '執行';
      case DangerLevel.warning:
        return '我了解，繼續執行';
      case DangerLevel.dangerous:
        return '確認執行危險操作';
    }
  }
}
