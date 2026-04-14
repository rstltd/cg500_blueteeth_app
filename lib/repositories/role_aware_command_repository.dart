import '../core/interfaces/command_repository_interface.dart';
import '../models/command/command_category.dart';
import '../models/command/device_command.dart';
import '../models/role/user_role.dart';
import '../services/role_service.dart';

/// A [CommandRepositoryInterface] decorator that filters command access by
/// the current [UserRole] held in [RoleService].
///
/// In [UserRole.developer] this delegates to the inner repository unchanged.
/// In [UserRole.normal] it exposes only the [normalModeWhitelist] commands —
/// every getter and lookup method is filtered, so neither UI listings nor
/// string-based lookups can return non-whitelisted commands.
///
/// The wrapper is stateless: it queries [RoleService.currentRole] on every
/// call, so a role switch becomes visible as soon as listeners rebuild.
class RoleAwareCommandRepository implements CommandRepositoryInterface {
  RoleAwareCommandRepository({
    required CommandRepositoryInterface inner,
    required RoleService roleService,
  })  : _inner = inner,
        _roleService = roleService;

  final CommandRepositoryInterface _inner;
  final RoleService _roleService;

  /// Commands visible to field operators (normal mode).
  static const Set<String> normalModeWhitelist = {
    r'$INFO',
    r'$APN',
    r'$ADDR',
    r'$FTPADDR',
    r'$REBOOT',
  };

  bool _isAllowed(DeviceCommand cmd) {
    if (_roleService.currentRole.isDeveloper) return true;
    return normalModeWhitelist.contains(cmd.command.toUpperCase());
  }

  @override
  List<DeviceCommand> getAllCommands() => _inner
      .getAllCommands()
      .where(_isAllowed)
      .toList(growable: false);

  @override
  List<DeviceCommand> getCommandsByCategory(CommandCategory category) => _inner
      .getCommandsByCategory(category)
      .where(_isAllowed)
      .toList(growable: false);

  @override
  List<DeviceCommand> getQuickAccessCommands() => _inner
      .getQuickAccessCommands()
      .where(_isAllowed)
      .toList(growable: false);

  @override
  DeviceCommand? getCommand(String command) {
    final cmd = _inner.getCommand(command);
    if (cmd == null) return null;
    return _isAllowed(cmd) ? cmd : null;
  }

  @override
  List<DeviceCommand> searchCommands(String query) => _inner
      .searchCommands(query)
      .where(_isAllowed)
      .toList(growable: false);

  @override
  Map<CommandCategory, List<DeviceCommand>> getGroupedCommands() {
    final source = _inner.getGroupedCommands();
    final result = <CommandCategory, List<DeviceCommand>>{};
    for (final entry in source.entries) {
      final filtered =
          entry.value.where(_isAllowed).toList(growable: false);
      if (filtered.isNotEmpty) {
        result[entry.key] = filtered;
      }
    }
    return result;
  }

  @override
  List<DeviceCommand> getDangerousCommands() => _inner
      .getDangerousCommands()
      .where(_isAllowed)
      .toList(growable: false);
}
