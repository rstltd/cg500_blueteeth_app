import 'package:cg500_blueteeth_app/models/command/command_category.dart';
import 'package:cg500_blueteeth_app/models/command/custom_command.dart';
import 'package:cg500_blueteeth_app/models/role/user_role.dart';
import 'package:cg500_blueteeth_app/repositories/command_repository.dart';
import 'package:cg500_blueteeth_app/repositories/custom_command_repository.dart';
import 'package:cg500_blueteeth_app/repositories/role_aware_command_repository.dart';
import 'package:cg500_blueteeth_app/services/custom_command_service.dart';
import 'package:cg500_blueteeth_app/services/role_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool neverBuiltIn(String _) => false;

  late CommandRepository builtIn;
  late CustomCommandService service;
  late CustomCommandRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    builtIn = CommandRepository();
    service = CustomCommandService();
    await service.initialize();
    repo = CustomCommandRepository(
      inner: builtIn,
      customService: service,
    );
  });

  group('CustomCommandRepository', () {
    test('getAllCommands returns only built-ins when no custom commands', () {
      final all = repo.getAllCommands();
      expect(all.length, builtIn.getAllCommands().length);
    });

    test('getAllCommands merges built-ins + custom commands', () async {
      await service.add(
        const CustomCommand(command: r'$MYNEW1', name: 'Mine 1'),
        isBuiltIn: neverBuiltIn,
      );
      final all = repo.getAllCommands();
      expect(all.length, builtIn.getAllCommands().length + 1);
      expect(all.last.command, r'$MYNEW1');
      expect(all.last.category, CommandCategory.custom);
    });

    test('getCommandsByCategory(custom) returns only user commands', () async {
      await service.add(
        const CustomCommand(command: r'$MYNEW1', name: 'A'),
        isBuiltIn: neverBuiltIn,
      );
      final list = repo.getCommandsByCategory(CommandCategory.custom);
      expect(list.length, 1);
      expect(list.single.command, r'$MYNEW1');
    });

    test('getCommandsByCategory(config) still returns only built-in config',
        () async {
      await service.add(
        const CustomCommand(command: r'$MYCFG', name: 'Mine'),
        isBuiltIn: neverBuiltIn,
      );
      final config = repo.getCommandsByCategory(CommandCategory.config);
      // Custom commands should NOT leak into the config category.
      expect(
        config.every((c) => c.category == CommandCategory.config),
        isTrue,
      );
      expect(config.any((c) => c.command == r'$MYCFG'), isFalse);
    });

    test('getCommand prefers built-in when key collides', () async {
      await service.add(
        const CustomCommand(command: r'$INFO', name: 'Custom INFO'),
        isBuiltIn: neverBuiltIn, // bypass the normal guard for this test
      );
      final found = repo.getCommand(r'$INFO');
      expect(found, isNotNull);
      // Built-in $INFO has a non-edit_note icon, custom would be edit_note
      expect(found!.category, isNot(CommandCategory.custom));
    });

    test('getCommand returns custom when no built-in match', () async {
      await service.add(
        const CustomCommand(command: r'$MYNEW1', name: 'Mine'),
        isBuiltIn: neverBuiltIn,
      );
      final found = repo.getCommand(r'$MYNEW1');
      expect(found, isNotNull);
      expect(found!.category, CommandCategory.custom);
    });

    test('searchCommands finds both built-in and custom matches', () async {
      await service.add(
        const CustomCommand(command: r'$MYINFO', name: 'Custom info query'),
        isBuiltIn: neverBuiltIn,
      );
      final results = repo.searchCommands('info');
      final commands = results.map((c) => c.command).toSet();
      expect(commands.contains(r'$MYINFO'), isTrue);
    });

    test('getGroupedCommands includes custom category only if non-empty',
        () async {
      var grouped = repo.getGroupedCommands();
      expect(grouped.containsKey(CommandCategory.custom), isFalse);

      await service.add(
        const CustomCommand(command: r'$MYNEW1', name: 'Mine'),
        isBuiltIn: neverBuiltIn,
      );
      grouped = repo.getGroupedCommands();
      expect(grouped[CommandCategory.custom]?.length, 1);
    });

    test('custom command colliding with built-in is hidden from merged view',
        () async {
      // Simulate post-update state: user has a custom $INFO that now
      // collides with a built-in of the same name. The merged view hides
      // the custom one; detectConflicts surfaces it for resolution.
      await service.add(
        const CustomCommand(command: r'$INFO', name: 'Stale custom'),
        isBuiltIn: neverBuiltIn,
      );
      final infos = repo
          .getAllCommands()
          .where((c) => c.command == r'$INFO')
          .toList();
      expect(infos.length, 1); // no duplicates
      expect(infos.single.category, CommandCategory.query); // built-in wins
    });

    test('stacked with RoleAwareCommandRepository hides custom in normal mode',
        () async {
      final roleService = RoleService();
      final stacked = RoleAwareCommandRepository(
        inner: repo,
        roleService: roleService,
      );
      await service.add(
        const CustomCommand(command: r'$MYNEW1', name: 'Mine'),
        isBuiltIn: neverBuiltIn,
      );

      // Normal mode: custom command filtered out by whitelist.
      final normal = stacked.getAllCommands().map((c) => c.command).toSet();
      expect(normal.contains(r'$MYNEW1'), isFalse);
      expect(normal, equals(RoleAwareCommandRepository.normalModeWhitelist));

      // Developer mode: custom command visible.
      await roleService.tryEnableDeveloperMode('cg500dev');
      final dev = stacked.getAllCommands().map((c) => c.command).toSet();
      expect(dev.contains(r'$MYNEW1'), isTrue);
      expect(dev.contains(UserRole.developer.name), isFalse); // sanity
    });
  });
}
