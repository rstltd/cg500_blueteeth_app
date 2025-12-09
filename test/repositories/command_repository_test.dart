import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/command/command.dart';
import 'package:cg500_blueteeth_app/repositories/command_repository.dart';

void main() {
  late CommandRepository repository;

  setUp(() {
    repository = CommandRepository();
  });

  group('CommandRepository', () {
    group('getAllCommands', () {
      test('returns 12 commands', () {
        final commands = repository.getAllCommands();
        expect(commands.length, 12);
      });

      test('returns unmodifiable list', () {
        final commands = repository.getAllCommands();
        expect(
          () => commands.add(const DeviceCommand(
            command: '\$TEST',
            name: 'Test',
            description: 'Test',
            category: CommandCategory.query,
          )),
          throwsUnsupportedError,
        );
      });

      test('contains all expected commands', () {
        final commands = repository.getAllCommands();
        final commandStrings = commands.map((c) => c.command).toSet();

        expect(commandStrings, contains('\$CMD'));
        expect(commandStrings, contains('\$INFO'));
        expect(commandStrings, contains('\$DEBUG'));
        expect(commandStrings, contains('\$MAC'));
        expect(commandStrings, contains('\$APN'));
        expect(commandStrings, contains('\$ADDR'));
        expect(commandStrings, contains('\$REBOOT'));
        expect(commandStrings, contains('\$ALARM'));
        expect(commandStrings, contains('\$FTPADDR'));
        expect(commandStrings, contains('\$STARTX'));
        expect(commandStrings, contains('\$SHOWP'));
        expect(commandStrings, contains('\$TCPX'));
      });
    });

    group('getCommandsByCategory', () {
      test('returns query commands', () {
        final commands = repository.getCommandsByCategory(CommandCategory.query);

        expect(commands, isNotEmpty);
        for (final cmd in commands) {
          expect(cmd.category, CommandCategory.query);
        }
      });

      test('returns config commands', () {
        final commands = repository.getCommandsByCategory(CommandCategory.config);

        expect(commands, isNotEmpty);
        for (final cmd in commands) {
          expect(cmd.category, CommandCategory.config);
        }
        expect(commands.length, 5); // $MAC, $APN, $ADDR, $ALARM, $FTPADDR
      });

      test('returns control commands', () {
        final commands = repository.getCommandsByCategory(CommandCategory.control);

        expect(commands, isNotEmpty);
        for (final cmd in commands) {
          expect(cmd.category, CommandCategory.control);
        }
        expect(commands.length, 3); // $REBOOT, $TCPX, $STARTX
      });

      test('returns debug commands', () {
        final commands = repository.getCommandsByCategory(CommandCategory.debug);

        expect(commands, isNotEmpty);
        for (final cmd in commands) {
          expect(cmd.category, CommandCategory.debug);
        }
      });
    });

    group('getQuickAccessCommands', () {
      test('returns only safe commands without parameters', () {
        final commands = repository.getQuickAccessCommands();

        expect(commands, isNotEmpty);
        for (final cmd in commands) {
          expect(cmd.hasParameters, false);
          expect(cmd.dangerLevel, DangerLevel.safe);
        }
      });

      test(r'includes $INFO, $CMD, $TCPX, $SHOWP', () {
        final commands = repository.getQuickAccessCommands();
        final commandStrings = commands.map((c) => c.command).toSet();

        expect(commandStrings, contains('\$INFO'));
        expect(commandStrings, contains('\$CMD'));
        expect(commandStrings, contains('\$TCPX'));
        expect(commandStrings, contains('\$SHOWP'));
      });

      test(r'excludes $STARTX (dangerous)', () {
        final commands = repository.getQuickAccessCommands();
        final commandStrings = commands.map((c) => c.command).toSet();

        expect(commandStrings, isNot(contains('\$STARTX')));
      });

      test(r'excludes $DEBUG (warning)', () {
        final commands = repository.getQuickAccessCommands();
        final commandStrings = commands.map((c) => c.command).toSet();

        expect(commandStrings, isNot(contains('\$DEBUG')));
      });

      test('excludes commands with parameters', () {
        final commands = repository.getQuickAccessCommands();
        final commandStrings = commands.map((c) => c.command).toSet();

        expect(commandStrings, isNot(contains('\$MAC')));
        expect(commandStrings, isNot(contains('\$ADDR')));
        expect(commandStrings, isNot(contains('\$ALARM')));
      });
    });

    group('getCommand', () {
      test('returns command by exact match', () {
        final command = repository.getCommand('\$INFO');

        expect(command, isNotNull);
        expect(command!.command, '\$INFO');
      });

      test('returns command with case insensitive match', () {
        final command = repository.getCommand('\$info');

        expect(command, isNotNull);
        expect(command!.command, '\$INFO');
      });

      test('returns null for unknown command', () {
        final command = repository.getCommand('\$UNKNOWN');

        expect(command, isNull);
      });
    });

    group('searchCommands', () {
      test('returns all commands for empty query', () {
        final results = repository.searchCommands('');

        expect(results.length, 12);
      });

      test('finds commands by command string', () {
        final results = repository.searchCommands('INFO');

        expect(results, isNotEmpty);
        expect(results.any((c) => c.command == '\$INFO'), true);
      });

      test('finds commands by name', () {
        final results = repository.searchCommands('設備資訊');

        expect(results, isNotEmpty);
        expect(results.any((c) => c.command == '\$INFO'), true);
      });

      test('finds commands by description', () {
        final results = repository.searchCommands('MAC');

        expect(results, isNotEmpty);
        // Should find both $MAC and $INFO (which shows MAC)
      });

      test('case insensitive search', () {
        final results1 = repository.searchCommands('info');
        final results2 = repository.searchCommands('INFO');

        expect(results1.length, results2.length);
      });

      test('returns empty for no match', () {
        final results = repository.searchCommands('xyz123');

        expect(results, isEmpty);
      });
    });

    group('getGroupedCommands', () {
      test('returns commands grouped by category', () {
        final grouped = repository.getGroupedCommands();

        expect(grouped.containsKey(CommandCategory.query), true);
        expect(grouped.containsKey(CommandCategory.config), true);
        expect(grouped.containsKey(CommandCategory.control), true);
        expect(grouped.containsKey(CommandCategory.debug), true);
      });

      test('each group contains correct commands', () {
        final grouped = repository.getGroupedCommands();

        for (final entry in grouped.entries) {
          for (final cmd in entry.value) {
            expect(cmd.category, entry.key);
          }
        }
      });

      test('total commands equals 12', () {
        final grouped = repository.getGroupedCommands();
        int total = 0;
        for (final commands in grouped.values) {
          total += commands.length;
        }

        expect(total, 12);
      });
    });

    group('getDangerousCommands', () {
      test('returns commands that require confirmation', () {
        final commands = repository.getDangerousCommands();

        expect(commands, isNotEmpty);
        for (final cmd in commands) {
          expect(cmd.requiresConfirmation, true);
        }
      });

      test(r'includes $STARTX and $DEBUG', () {
        final commands = repository.getDangerousCommands();
        final commandStrings = commands.map((c) => c.command).toSet();

        expect(commandStrings, contains('\$STARTX'));
        expect(commandStrings, contains('\$DEBUG'));
      });

      test('excludes safe commands', () {
        final commands = repository.getDangerousCommands();
        final commandStrings = commands.map((c) => c.command).toSet();

        expect(commandStrings, isNot(contains('\$INFO')));
        expect(commandStrings, isNot(contains('\$CMD')));
      });
    });

    group('command definitions', () {
      test('\$INFO is correctly defined', () {
        final cmd = repository.getCommand('\$INFO');

        expect(cmd, isNotNull);
        expect(cmd!.name, contains('設備資訊'));
        expect(cmd.category, CommandCategory.query);
        expect(cmd.hasParameters, false);
        expect(cmd.dangerLevel, DangerLevel.safe);
      });

      test('\$MAC has text parameter', () {
        final cmd = repository.getCommand('\$MAC');

        expect(cmd, isNotNull);
        expect(cmd!.hasParameters, true);
        expect(cmd.parameters.length, 1);
        expect(cmd.parameters.first.type, ParameterType.text);
      });

      test('\$ADDR has IP:Port parameter', () {
        final cmd = repository.getCommand('\$ADDR');

        expect(cmd, isNotNull);
        expect(cmd!.hasParameters, true);
        expect(cmd.parameters.first.type, ParameterType.ipPort);
      });

      test('\$ALARM has bitFlags parameter', () {
        final cmd = repository.getCommand('\$ALARM');

        expect(cmd, isNotNull);
        expect(cmd!.hasParameters, true);
        expect(cmd.parameters.first.type, ParameterType.bitFlags);

        final flags = cmd.parameters.first.bitFlagOptions;
        expect(flags, isNotNull);
        expect(flags!.length, 4); // SD, GPS, TCP, ADC
      });

      test('\$REBOOT has hourPicker parameter', () {
        final cmd = repository.getCommand('\$REBOOT');

        expect(cmd, isNotNull);
        expect(cmd!.hasParameters, true);
        expect(cmd.parameters.first.type, ParameterType.hourPicker);
      });

      test('\$STARTX is dangerous', () {
        final cmd = repository.getCommand('\$STARTX');

        expect(cmd, isNotNull);
        expect(cmd!.dangerLevel, DangerLevel.dangerous);
        expect(cmd.requiresConfirmation, true);
        expect(cmd.warningMessage, isNotNull);
      });

      test('\$DEBUG has warning level', () {
        final cmd = repository.getCommand('\$DEBUG');

        expect(cmd, isNotNull);
        expect(cmd!.dangerLevel, DangerLevel.warning);
        expect(cmd.requiresConfirmation, true);
        expect(cmd.warningMessage, isNotNull);
      });
    });

    group('singleton pattern', () {
      test('returns same instance', () {
        final repo1 = CommandRepository();
        final repo2 = CommandRepository();

        expect(identical(repo1, repo2), true);
      });
    });
  });
}
