import 'package:cg500_blueteeth_app/models/command/custom_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomCommand', () {
    test('normalizedKey trims and uppercases', () {
      const cmd = CustomCommand(
        command: '  \$mac,cn001 ',
        name: 'Test',
      );
      expect(cmd.normalizedKey, r'$MAC,CN001');
    });

    test('copyWith replaces only the specified fields', () {
      const original = CustomCommand(
        command: r'$INFO',
        name: 'Info',
        description: 'Query',
      );
      final updated = original.copyWith(name: 'New Info');
      expect(updated.command, r'$INFO');
      expect(updated.name, 'New Info');
      expect(updated.description, 'Query');
    });

    test('toJson round-trips via fromJson', () {
      const original = CustomCommand(
        command: r'$APN,internet',
        name: 'Set APN',
        description: 'Mobile APN',
      );
      final json = original.toJson();
      final parsed = CustomCommand.fromJson(json);
      expect(parsed, equals(original));
    });

    test('fromJson tolerates missing description', () {
      final parsed = CustomCommand.fromJson({
        'command': r'$REBOOT,2',
        'name': 'Reboot',
      });
      expect(parsed.command, r'$REBOOT,2');
      expect(parsed.name, 'Reboot');
      expect(parsed.description, '');
    });

    test('equality based on all fields', () {
      const a = CustomCommand(command: r'$A', name: 'A');
      const b = CustomCommand(command: r'$A', name: 'A');
      const c = CustomCommand(command: r'$A', name: 'B');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
