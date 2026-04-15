import 'package:cg500_blueteeth_app/models/command/custom_command.dart';
import 'package:cg500_blueteeth_app/services/custom_command_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool neverBuiltIn(String _) => false;
  bool Function(String) builtInContains(Set<String> keys) =>
      (key) => keys.contains(key);

  group('CustomCommandService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initialize starts with empty list when prefs are empty', () async {
      final service = CustomCommandService();
      await service.initialize();
      expect(service.list(), isEmpty);
    });

    test('add persists command and emits changeStream', () async {
      final service = CustomCommandService();
      await service.initialize();

      final events = <List<CustomCommand>>[];
      final sub = service.changeStream.listen(events.add);

      final result = await service.add(
        const CustomCommand(command: r'$MAC,CN001', name: 'Test MAC'),
        isBuiltIn: neverBuiltIn,
      );

      expect(result, CustomCommandResult.success);
      expect(service.list().length, 1);
      await Future<void>.delayed(Duration.zero);
      expect(events.length, 1);
      expect(events.first.length, 1);
      await sub.cancel();
    });

    test('add rejects empty command', () async {
      final service = CustomCommandService();
      await service.initialize();
      final result = await service.add(
        const CustomCommand(command: '   ', name: 'x'),
        isBuiltIn: neverBuiltIn,
      );
      expect(result, CustomCommandResult.invalidFormat);
      expect(service.list(), isEmpty);
    });

    test('add rejects command without \$ prefix', () async {
      final service = CustomCommandService();
      await service.initialize();
      final result = await service.add(
        const CustomCommand(command: 'MAC,CN001', name: 'x'),
        isBuiltIn: neverBuiltIn,
      );
      expect(result, CustomCommandResult.invalidFormat);
    });

    test('add rejects empty name', () async {
      final service = CustomCommandService();
      await service.initialize();
      final result = await service.add(
        const CustomCommand(command: r'$MAC,CN001', name: '   '),
        isBuiltIn: neverBuiltIn,
      );
      expect(result, CustomCommandResult.nameRequired);
    });

    test('add rejects duplicate custom command (case-insensitive)', () async {
      final service = CustomCommandService();
      await service.initialize();
      await service.add(
        const CustomCommand(command: r'$MAC,CN001', name: 'A'),
        isBuiltIn: neverBuiltIn,
      );
      final result = await service.add(
        const CustomCommand(command: r'$mac,cn001', name: 'B'),
        isBuiltIn: neverBuiltIn,
      );
      expect(result, CustomCommandResult.duplicateInCustom);
      expect(service.list().length, 1);
    });

    test('add rejects collision with built-in command', () async {
      final service = CustomCommandService();
      await service.initialize();
      final result = await service.add(
        const CustomCommand(command: r'$INFO', name: 'Info'),
        isBuiltIn: builtInContains({r'$INFO', r'$APN'}),
      );
      expect(result, CustomCommandResult.duplicateInBuiltIn);
    });

    test('update replaces existing command', () async {
      final service = CustomCommandService();
      await service.initialize();
      await service.add(
        const CustomCommand(command: r'$MAC,CN001', name: 'Old'),
        isBuiltIn: neverBuiltIn,
      );
      final result = await service.update(
        r'$MAC,CN001',
        const CustomCommand(command: r'$MAC,CN002', name: 'New'),
        isBuiltIn: neverBuiltIn,
      );
      expect(result, CustomCommandResult.success);
      expect(service.list().single.command, r'$MAC,CN002');
      expect(service.list().single.name, 'New');
    });

    test('update fails when new key collides with other custom', () async {
      final service = CustomCommandService();
      await service.initialize();
      await service.add(
        const CustomCommand(command: r'$A', name: 'A'),
        isBuiltIn: neverBuiltIn,
      );
      await service.add(
        const CustomCommand(command: r'$B', name: 'B'),
        isBuiltIn: neverBuiltIn,
      );
      final result = await service.update(
        r'$A',
        const CustomCommand(command: r'$B', name: 'Collide'),
        isBuiltIn: neverBuiltIn,
      );
      expect(result, CustomCommandResult.duplicateInCustom);
    });

    test('update notFound when old key missing', () async {
      final service = CustomCommandService();
      await service.initialize();
      final result = await service.update(
        r'$MISSING',
        const CustomCommand(command: r'$NEW', name: 'x'),
        isBuiltIn: neverBuiltIn,
      );
      expect(result, CustomCommandResult.notFound);
    });

    test('remove deletes and emits changeStream', () async {
      final service = CustomCommandService();
      await service.initialize();
      await service.add(
        const CustomCommand(command: r'$A', name: 'A'),
        isBuiltIn: neverBuiltIn,
      );
      final events = <List<CustomCommand>>[];
      final sub = service.changeStream.listen(events.add);
      await service.remove(r'$A');
      expect(service.list(), isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(events.length, 1);
      expect(events.first, isEmpty);
      await sub.cancel();
    });

    test('data persists across service instances', () async {
      final first = CustomCommandService();
      await first.initialize();
      await first.add(
        const CustomCommand(
            command: r'$MAC,CN001', name: 'Persistent', description: 'note'),
        isBuiltIn: neverBuiltIn,
      );

      // Second instance reads the same SharedPreferences.
      final second = CustomCommandService();
      await second.initialize();
      expect(second.list().length, 1);
      expect(second.list().single.command, r'$MAC,CN001');
      expect(second.list().single.description, 'note');
    });

    test('detectConflicts returns commands colliding with built-ins',
        () async {
      final service = CustomCommandService();
      await service.initialize();
      await service.add(
        const CustomCommand(command: r'$MAC,CN001', name: 'A'),
        isBuiltIn: neverBuiltIn,
      );
      await service.add(
        const CustomCommand(command: r'$CUSTOM1', name: 'B'),
        isBuiltIn: neverBuiltIn,
      );
      // Simulate an app update that added $MAC,CN001 as a built-in.
      final conflicts = service.detectConflicts(
        isBuiltIn: builtInContains({r'$MAC,CN001'}),
      );
      expect(conflicts.length, 1);
      expect(conflicts.single.command, r'$MAC,CN001');
    });
  });
}
