import 'package:cg500_blueteeth_app/repositories/command_repository.dart';
import 'package:cg500_blueteeth_app/repositories/role_aware_command_repository.dart';
import 'package:cg500_blueteeth_app/services/role_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoleAwareCommandRepository', () {
    late RoleService roleService;
    late RoleAwareCommandRepository repo;
    late CommandRepository inner;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      roleService = RoleService();
      inner = CommandRepository();
      repo = RoleAwareCommandRepository(
        inner: inner,
        roleService: roleService,
      );
    });

    group('normal mode (default)', () {
      test('getAllCommands returns only the 5 whitelist commands', () {
        final commands = repo.getAllCommands();
        final commandStrings = commands.map((c) => c.command).toSet();
        expect(commandStrings,
            equals(RoleAwareCommandRepository.normalModeWhitelist));
        expect(commands.length, 5);
      });

      test('getCommand returns null for non-whitelisted commands', () {
        expect(repo.getCommand(r'$STARTX'), isNull);
        expect(repo.getCommand(r'$DEBUG'), isNull);
        expect(repo.getCommand(r'$SHOWP'), isNull);
      });

      test('getCommand returns command for whitelisted entries', () {
        final info = repo.getCommand(r'$INFO');
        expect(info, isNotNull);
        expect(info!.command, r'$INFO');

        final reboot = repo.getCommand(r'$REBOOT');
        expect(reboot, isNotNull);
        expect(reboot!.command, r'$REBOOT');
      });

      test('searchCommands does not surface non-whitelisted matches', () {
        final results = repo.searchCommands('startx');
        expect(results, isEmpty);
      });

      test('searchCommands returns whitelisted matches', () {
        final results = repo.searchCommands('reboot');
        expect(results.length, 1);
        expect(results.first.command, r'$REBOOT');
      });

      test('getGroupedCommands skips empty categories', () {
        final grouped = repo.getGroupedCommands();
        for (final entry in grouped.entries) {
          expect(entry.value, isNotEmpty,
              reason: 'category ${entry.key} should not be empty');
          for (final cmd in entry.value) {
            expect(
              RoleAwareCommandRepository.normalModeWhitelist
                  .contains(cmd.command),
              isTrue,
              reason: '${cmd.command} should be whitelisted',
            );
          }
        }
      });

      test('getQuickAccessCommands returns only whitelisted no-param/safe', () {
        final quick = repo.getQuickAccessCommands();
        for (final cmd in quick) {
          expect(
            RoleAwareCommandRepository.normalModeWhitelist
                .contains(cmd.command),
            isTrue,
          );
        }
      });

      test('getDangerousCommands filters out non-whitelisted dangerous cmds',
          () {
        final dangerous = repo.getDangerousCommands();
        for (final cmd in dangerous) {
          expect(
            RoleAwareCommandRepository.normalModeWhitelist
                .contains(cmd.command),
            isTrue,
          );
        }
      });
    });

    group('developer mode', () {
      setUp(() async {
        await roleService.tryEnableDeveloperMode('cg500dev');
      });

      test('getAllCommands matches the inner repository', () {
        final wrapped = repo.getAllCommands().map((c) => c.command).toSet();
        final innerAll = inner.getAllCommands().map((c) => c.command).toSet();
        expect(wrapped, equals(innerAll));
      });

      test('getCommand returns previously hidden commands', () {
        expect(repo.getCommand(r'$STARTX'), isNotNull);
        expect(repo.getCommand(r'$DEBUG'), isNotNull);
      });

      test('searchCommands surfaces non-whitelisted matches', () {
        final results = repo.searchCommands('startx');
        expect(results.length, greaterThan(0));
      });

      test('getGroupedCommands matches inner repository', () {
        final wrapped = repo.getGroupedCommands();
        final innerGrouped = inner.getGroupedCommands();
        expect(wrapped.keys.toSet(), equals(innerGrouped.keys.toSet()));
      });
    });

    group('reactive role switching', () {
      test('same wrapper instance reflects role flip without rebuild',
          () async {
        // Normal mode → 5
        expect(repo.getAllCommands().length, 5);

        // Flip to developer mode using the real unlock path
        await roleService.tryEnableDeveloperMode('cg500dev');

        // Same wrapper instance now returns the full set
        expect(repo.getAllCommands().length, greaterThan(5));
        expect(repo.getCommand(r'$STARTX'), isNotNull);

        // Flip back
        roleService.disableDeveloperMode();
        expect(repo.getAllCommands().length, 5);
        expect(repo.getCommand(r'$STARTX'), isNull);
      });
    });

    test('whitelist commands all exist in the inner repository', () {
      for (final cmd in RoleAwareCommandRepository.normalModeWhitelist) {
        expect(
          inner.getCommand(cmd),
          isNotNull,
          reason: '$cmd is whitelisted but not present in inner repository',
        );
      }
    });
  });
}
