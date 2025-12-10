import 'package:flutter/material.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

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
        return AppStrings.dangerLevelSafe;
      case DangerLevel.warning:
        return AppStrings.dangerLevelWarning;
      case DangerLevel.dangerous:
        return AppStrings.dangerLevelDangerous;
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
        return AppStrings.confirmExecution;
      case DangerLevel.warning:
        return AppStrings.attention;
      case DangerLevel.dangerous:
        return AppStrings.warningDangerousOperation;
    }
  }

  /// Returns the confirmation button text.
  String get confirmButtonText {
    switch (this) {
      case DangerLevel.safe:
        return AppStrings.execute;
      case DangerLevel.warning:
        return AppStrings.understandAndContinue;
      case DangerLevel.dangerous:
        return AppStrings.confirmDangerousOperation;
    }
  }
}
