import 'package:flutter/material.dart';

import 'command_category.dart';
import 'command_parameter.dart';
import 'danger_level.dart';

/// Represents a device command definition.
///
/// Contains all metadata needed to display and execute a command,
/// including parameters, category, and danger level.
class DeviceCommand {
  /// The command string (e.g., "$INFO").
  final String command;

  /// Display name for the command.
  final String name;

  /// Detailed description of what the command does.
  final String description;

  /// Category for organizing commands.
  final CommandCategory category;

  /// List of parameters required by this command.
  final List<CommandParameter> parameters;

  /// Danger level determining if confirmation is needed.
  final DangerLevel dangerLevel;

  /// Warning message shown before execution (for warning/dangerous commands).
  final String? warningMessage;

  /// Icon to display for this command.
  final IconData icon;

  /// Example usage of the command.
  final String? example;

  /// Creates a device command definition.
  const DeviceCommand({
    required this.command,
    required this.name,
    required this.description,
    required this.category,
    this.parameters = const [],
    this.dangerLevel = DangerLevel.safe,
    this.warningMessage,
    this.icon = Icons.terminal,
    this.example,
  });

  /// Whether this command requires parameters.
  bool get hasParameters => parameters.isNotEmpty;

  /// Whether this command requires user confirmation before execution.
  bool get requiresConfirmation => dangerLevel.requiresConfirmation;

  /// Whether this command is suitable for quick access (no params + safe).
  bool get isQuickAccessible =>
      !hasParameters && dangerLevel == DangerLevel.safe;

  /// Builds the full command string with the given parameter values.
  ///
  /// [paramValues] is a map of parameter ID to value.
  /// Returns the formatted command string ready to send.
  String buildCommandString(Map<String, String> paramValues) {
    if (!hasParameters) {
      return command;
    }

    final List<String> parts = [command];

    for (final param in parameters) {
      final value = paramValues[param.id];
      if (value != null && value.isNotEmpty) {
        parts.add(value);
      } else if (param.required) {
        // Missing required parameter - this shouldn't happen if validation passes
        throw ArgumentError('Missing required parameter: ${param.label}');
      }
    }

    return parts.join(',');
  }

  /// Validates all parameter values.
  ///
  /// Returns a map of parameter ID to error message for invalid parameters,
  /// or an empty map if all parameters are valid.
  Map<String, String> validateParameters(Map<String, String> paramValues) {
    final errors = <String, String>{};

    for (final param in parameters) {
      final value = paramValues[param.id];
      final error = param.validate(value);
      if (error != null) {
        errors[param.id] = error;
      }
    }

    return errors;
  }

  /// Gets the default parameter values.
  Map<String, String> getDefaultValues() {
    final defaults = <String, String>{};

    for (final param in parameters) {
      if (param.defaultValue != null) {
        defaults[param.id] = param.defaultValue!;
      }
    }

    return defaults;
  }

  /// Creates a copy of this command with different properties.
  DeviceCommand copyWith({
    String? command,
    String? name,
    String? description,
    CommandCategory? category,
    List<CommandParameter>? parameters,
    DangerLevel? dangerLevel,
    String? warningMessage,
    IconData? icon,
    String? example,
  }) {
    return DeviceCommand(
      command: command ?? this.command,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      parameters: parameters ?? this.parameters,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      warningMessage: warningMessage ?? this.warningMessage,
      icon: icon ?? this.icon,
      example: example ?? this.example,
    );
  }

  @override
  String toString() {
    return 'DeviceCommand(command: $command, name: $name, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceCommand && other.command == command;
  }

  @override
  int get hashCode => command.hashCode;
}
