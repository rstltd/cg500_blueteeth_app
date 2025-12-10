import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/command/command.dart';

void main() {
  group('DeviceCommand', () {
    group('basic properties', () {
      test('creates command with required properties', () {
        const command = DeviceCommand(
          command: '\$INFO',
          name: 'Show Info',
          description: 'Shows device information',
          category: CommandCategory.query,
        );

        expect(command.command, '\$INFO');
        expect(command.name, 'Show Info');
        expect(command.description, 'Shows device information');
        expect(command.category, CommandCategory.query);
      });

      test('has default values', () {
        const command = DeviceCommand(
          command: '\$TEST',
          name: 'Test',
          description: 'Test command',
          category: CommandCategory.query,
        );

        expect(command.parameters, isEmpty);
        expect(command.dangerLevel, DangerLevel.safe);
        expect(command.warningMessage, isNull);
        expect(command.icon, Icons.terminal);
        expect(command.example, isNull);
      });
    });

    group('hasParameters', () {
      test('returns false when no parameters', () {
        const command = DeviceCommand(
          command: '\$INFO',
          name: 'Info',
          description: 'Info',
          category: CommandCategory.query,
        );

        expect(command.hasParameters, false);
      });

      test('returns true when has parameters', () {
        final command = DeviceCommand(
          command: '\$MAC',
          name: 'Set MAC',
          description: 'Set MAC',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'mac', label: 'MAC'),
          ],
        );

        expect(command.hasParameters, true);
      });
    });

    group('requiresConfirmation', () {
      test('returns false for safe commands', () {
        const command = DeviceCommand(
          command: '\$INFO',
          name: 'Info',
          description: 'Info',
          category: CommandCategory.query,
          dangerLevel: DangerLevel.safe,
        );

        expect(command.requiresConfirmation, false);
      });

      test('returns true for warning commands', () {
        const command = DeviceCommand(
          command: '\$DEBUG',
          name: 'Debug',
          description: 'Debug',
          category: CommandCategory.debug,
          dangerLevel: DangerLevel.warning,
        );

        expect(command.requiresConfirmation, true);
      });

      test('returns true for dangerous commands', () {
        const command = DeviceCommand(
          command: '\$STARTX',
          name: 'Restart',
          description: 'Restart',
          category: CommandCategory.control,
          dangerLevel: DangerLevel.dangerous,
        );

        expect(command.requiresConfirmation, true);
      });
    });

    group('isQuickAccessible', () {
      test('returns true for safe commands without parameters', () {
        const command = DeviceCommand(
          command: '\$INFO',
          name: 'Info',
          description: 'Info',
          category: CommandCategory.query,
          dangerLevel: DangerLevel.safe,
        );

        expect(command.isQuickAccessible, true);
      });

      test('returns false for commands with parameters', () {
        final command = DeviceCommand(
          command: '\$MAC',
          name: 'Set MAC',
          description: 'Set MAC',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'mac', label: 'MAC'),
          ],
        );

        expect(command.isQuickAccessible, false);
      });

      test('returns false for dangerous commands', () {
        const command = DeviceCommand(
          command: '\$STARTX',
          name: 'Restart',
          description: 'Restart',
          category: CommandCategory.control,
          dangerLevel: DangerLevel.dangerous,
        );

        expect(command.isQuickAccessible, false);
      });
    });

    group('buildCommandString', () {
      test('returns command only when no parameters', () {
        const command = DeviceCommand(
          command: '\$INFO',
          name: 'Info',
          description: 'Info',
          category: CommandCategory.query,
        );

        expect(command.buildCommandString({}), '\$INFO');
      });

      test('builds command with single parameter', () {
        final command = DeviceCommand(
          command: '\$MAC',
          name: 'Set MAC',
          description: 'Set MAC',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'deviceId', label: 'Device ID'),
          ],
        );

        expect(
          command.buildCommandString({'deviceId': 'CN001'}),
          '\$MAC,CN001',
        );
      });

      test('builds command with IP:Port parameter', () {
        final command = DeviceCommand(
          command: '\$ADDR',
          name: 'Set Address',
          description: 'Set Address',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.ipPort(id: 'addr', label: 'Address'),
          ],
        );

        expect(
          command.buildCommandString({'addr': '192.168.1.1:8080'}),
          '\$ADDR,192.168.1.1:8080',
        );
      });

      test('uses placeholder for missing required parameter by default', () {
        final command = DeviceCommand(
          command: '\$MAC',
          name: 'Set MAC',
          description: 'Set MAC',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'deviceId', label: 'Device ID'),
          ],
        );

        expect(
          command.buildCommandString({}),
          '\$MAC,<Device ID>',
        );
      });

      test('throws for missing required parameter when throwOnMissing is true',
          () {
        final command = DeviceCommand(
          command: '\$MAC',
          name: 'Set MAC',
          description: 'Set MAC',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'deviceId', label: 'Device ID'),
          ],
        );

        expect(
          () => command.buildCommandString({}, throwOnMissing: true),
          throwsArgumentError,
        );
      });
    });

    group('validateParameters', () {
      test('returns empty map for valid parameters', () {
        final command = DeviceCommand(
          command: '\$MAC',
          name: 'Set MAC',
          description: 'Set MAC',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'deviceId', label: 'Device ID'),
          ],
        );

        final errors = command.validateParameters({'deviceId': 'CN001'});
        expect(errors, isEmpty);
      });

      test('returns errors for invalid parameters', () {
        final command = DeviceCommand(
          command: '\$ADDR',
          name: 'Set Address',
          description: 'Set Address',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.ipPort(id: 'addr', label: 'Address'),
          ],
        );

        final errors = command.validateParameters({'addr': 'invalid'});
        expect(errors, isNotEmpty);
        expect(errors['addr'], isNotNull);
      });

      test('returns multiple errors for multiple invalid parameters', () {
        final command = DeviceCommand(
          command: '\$TEST',
          name: 'Test',
          description: 'Test',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'text', label: 'Text', required: true),
            CommandParameter.ipPort(id: 'addr', label: 'Address'),
          ],
        );

        final errors = command.validateParameters({
          'text': '',
          'addr': 'invalid',
        });

        expect(errors.length, 2);
        expect(errors['text'], isNotNull);
        expect(errors['addr'], isNotNull);
      });
    });

    group('getDefaultValues', () {
      test('returns empty map when no defaults', () {
        final command = DeviceCommand(
          command: '\$MAC',
          name: 'Set MAC',
          description: 'Set MAC',
          category: CommandCategory.config,
          parameters: [
            CommandParameter.text(id: 'deviceId', label: 'Device ID'),
          ],
        );

        expect(command.getDefaultValues(), isEmpty);
      });

      test('returns default values', () {
        final command = DeviceCommand(
          command: '\$REBOOT',
          name: 'Set Reboot',
          description: 'Set Reboot',
          category: CommandCategory.control,
          parameters: [
            CommandParameter.hourPicker(
              id: 'hour',
              label: 'Hour',
              defaultHour: 2,
            ),
          ],
        );

        final defaults = command.getDefaultValues();
        expect(defaults['hour'], '2');
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        const original = DeviceCommand(
          command: '\$INFO',
          name: 'Info',
          description: 'Info',
          category: CommandCategory.query,
        );

        final copy = original.copyWith(
          name: 'New Name',
          description: 'New Description',
        );

        expect(copy.command, '\$INFO');
        expect(copy.name, 'New Name');
        expect(copy.description, 'New Description');
        expect(copy.category, CommandCategory.query);
      });

      test('keeps original values when not specified', () {
        const original = DeviceCommand(
          command: '\$INFO',
          name: 'Info',
          description: 'Info',
          category: CommandCategory.query,
          dangerLevel: DangerLevel.safe,
        );

        final copy = original.copyWith(name: 'New Name');

        expect(copy.command, original.command);
        expect(copy.description, original.description);
        expect(copy.category, original.category);
        expect(copy.dangerLevel, original.dangerLevel);
      });
    });

    group('equality', () {
      test('commands with same command string are equal', () {
        const command1 = DeviceCommand(
          command: '\$INFO',
          name: 'Info 1',
          description: 'Description 1',
          category: CommandCategory.query,
        );

        const command2 = DeviceCommand(
          command: '\$INFO',
          name: 'Info 2',
          description: 'Description 2',
          category: CommandCategory.debug,
        );

        expect(command1, equals(command2));
      });

      test('commands with different command strings are not equal', () {
        const command1 = DeviceCommand(
          command: '\$INFO',
          name: 'Info',
          description: 'Info',
          category: CommandCategory.query,
        );

        const command2 = DeviceCommand(
          command: '\$CMD',
          name: 'CMD',
          description: 'CMD',
          category: CommandCategory.query,
        );

        expect(command1, isNot(equals(command2)));
      });
    });
  });
}
