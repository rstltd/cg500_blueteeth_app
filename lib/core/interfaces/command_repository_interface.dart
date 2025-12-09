import '../../models/command/command_category.dart';
import '../../models/command/device_command.dart';

/// Interface for command repository.
///
/// Abstracts access to device command definitions,
/// enabling testing with mock implementations.
abstract class CommandRepositoryInterface {
  /// Get all commands.
  List<DeviceCommand> getAllCommands();

  /// Get commands filtered by category.
  List<DeviceCommand> getCommandsByCategory(CommandCategory category);

  /// Get commands suitable for quick access (no params + safe).
  List<DeviceCommand> getQuickAccessCommands();

  /// Get a specific command by its command string.
  DeviceCommand? getCommand(String command);

  /// Search commands by name, description, or command string.
  List<DeviceCommand> searchCommands(String query);

  /// Get all categories with their commands.
  Map<CommandCategory, List<DeviceCommand>> getGroupedCommands();

  /// Get commands that require confirmation.
  List<DeviceCommand> getDangerousCommands();
}
