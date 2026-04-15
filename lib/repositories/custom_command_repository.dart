import 'package:flutter/material.dart';

import '../core/interfaces/command_repository_interface.dart';
import '../models/command/command_category.dart';
import '../models/command/command_parameter.dart';
import '../models/command/custom_command.dart';
import '../models/command/danger_level.dart';
import '../models/command/device_command.dart';
import '../services/custom_command_service.dart';

/// Decorator that merges user-defined commands from [CustomCommandService]
/// into the results exposed by a wrapped [CommandRepositoryInterface].
///
/// v1 invariants:
/// - Custom commands are rendered as [DeviceCommand]s with empty
///   parameters and [DangerLevel.safe].
/// - They live in their own [CommandCategory.custom] bucket.
/// - If a custom command's key collides with a built-in command, the
///   built-in takes precedence and the custom version is hidden from
///   the merged result so UI consumers never see duplicates. The
///   conflict is still discoverable via [CustomCommandService.detectConflicts]
///   for the management view to surface.
class CustomCommandRepository implements CommandRepositoryInterface {
  CustomCommandRepository({
    required CommandRepositoryInterface inner,
    required CustomCommandService customService,
  })  : _inner = inner,
        _customService = customService;

  final CommandRepositoryInterface _inner;
  final CustomCommandService _customService;

  DeviceCommand _toDeviceCommand(CustomCommand custom) => DeviceCommand(
        command: custom.command,
        name: custom.name,
        description: custom.description,
        category: CommandCategory.custom,
        parameters: const <CommandParameter>[],
        dangerLevel: DangerLevel.safe,
        icon: Icons.edit_note,
      );

  /// Returns only the custom commands whose keys do NOT collide with any
  /// built-in command. The conflicting ones are hidden from normal UI
  /// paths so users don't see duplicates; they remain discoverable via
  /// [CustomCommandService.detectConflicts] for the management view.
  List<DeviceCommand> _visibleCustomAsDeviceCommands() {
    final builtInKeys = _inner
        .getAllCommands()
        .map((c) => c.command.trim().toUpperCase())
        .toSet();
    return _customService
        .list()
        .where((c) => !builtInKeys.contains(c.normalizedKey))
        .map(_toDeviceCommand)
        .toList(growable: false);
  }

  @override
  List<DeviceCommand> getAllCommands() => [
        ..._inner.getAllCommands(),
        ..._visibleCustomAsDeviceCommands(),
      ];

  @override
  List<DeviceCommand> getCommandsByCategory(CommandCategory category) {
    if (category == CommandCategory.custom) {
      return _visibleCustomAsDeviceCommands();
    }
    return _inner.getCommandsByCategory(category);
  }

  @override
  List<DeviceCommand> getQuickAccessCommands() => [
        ..._inner.getQuickAccessCommands(),
        ..._visibleCustomAsDeviceCommands()
            .where((c) => c.isQuickAccessible),
      ];

  @override
  DeviceCommand? getCommand(String command) {
    final fromBuiltIn = _inner.getCommand(command);
    if (fromBuiltIn != null) return fromBuiltIn;

    final key = command.trim().toUpperCase();
    for (final custom in _customService.list()) {
      if (custom.normalizedKey == key) {
        return _toDeviceCommand(custom);
      }
    }
    return null;
  }

  @override
  List<DeviceCommand> searchCommands(String query) {
    if (query.isEmpty) return getAllCommands();

    final fromBuiltIn = _inner.searchCommands(query);
    final lowerQuery = query.toLowerCase();
    final fromCustom = _visibleCustomAsDeviceCommands().where((cmd) {
      return cmd.command.toLowerCase().contains(lowerQuery) ||
          cmd.name.toLowerCase().contains(lowerQuery) ||
          cmd.description.toLowerCase().contains(lowerQuery);
    });
    return [...fromBuiltIn, ...fromCustom];
  }

  @override
  Map<CommandCategory, List<DeviceCommand>> getGroupedCommands() {
    final grouped = Map<CommandCategory, List<DeviceCommand>>.from(
      _inner.getGroupedCommands(),
    );
    final custom = _visibleCustomAsDeviceCommands();
    if (custom.isNotEmpty) {
      grouped[CommandCategory.custom] = custom;
    }
    return grouped;
  }

  @override
  List<DeviceCommand> getDangerousCommands() => _inner.getDangerousCommands();
}
