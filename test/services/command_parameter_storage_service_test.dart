import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cg500_blueteeth_app/services/command_parameter_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommandParameterStorageService', () {
    late CommandParameterStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = CommandParameterStorageService.forTesting(prefs);
    });

    group('initialization', () {
      test('should be initialized when created with forTesting', () {
        expect(service.isInitialized, true);
      });

      test('should not be initialized initially', () {
        final newService = CommandParameterStorageService();
        expect(newService.isInitialized, false);
      });

      test('should be initialized after calling initialize()', () async {
        SharedPreferences.setMockInitialValues({});
        final newService = CommandParameterStorageService();
        await newService.initialize();
        expect(newService.isInitialized, true);
      });

      test('initialize should be idempotent', () async {
        SharedPreferences.setMockInitialValues({});
        final newService = CommandParameterStorageService();
        await newService.initialize();
        await newService.initialize(); // Second call should not throw
        expect(newService.isInitialized, true);
      });
    });

    group('saveParameters and getParameters', () {
      test('should save and retrieve parameters', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1', 'port': '8080'});

        final params = service.getParameters('\$ADDR');
        expect(params, isNotNull);
        expect(params!['ip'], '192.168.1.1');
        expect(params['port'], '8080');
      });

      test('should return null for non-existent command', () {
        final params = service.getParameters('\$NONEXISTENT');
        expect(params, isNull);
      });

      test('should normalize command names with \$ prefix', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});

        // Should be accessible with or without $ prefix
        final params1 = service.getParameters('\$ADDR');
        final params2 = service.getParameters('ADDR');
        expect(params1, isNotNull);
        expect(params2, isNotNull);
        expect(params1!['ip'], params2!['ip']);
      });

      test('should be case insensitive for command names', () async {
        await service.saveParameters('\$addr', {'ip': '192.168.1.1'});

        final params = service.getParameters('\$ADDR');
        expect(params, isNotNull);
        expect(params!['ip'], '192.168.1.1');
      });

      test('should overwrite existing parameters', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});
        await service.saveParameters('\$ADDR', {'ip': '10.0.0.1'});

        final params = service.getParameters('\$ADDR');
        expect(params!['ip'], '10.0.0.1');
      });

      test('should handle empty parameters', () async {
        await service.saveParameters('\$EMPTY', {});

        final params = service.getParameters('\$EMPTY');
        expect(params, isNotNull);
        expect(params, isEmpty);
      });

      test('should handle parameters with special characters', () async {
        await service.saveParameters('\$SPECIAL', {
          'path': '/usr/local/bin',
          'query': 'a=1&b=2',
          'special': '!@#\$%^&*()',
        });

        final params = service.getParameters('\$SPECIAL');
        expect(params!['path'], '/usr/local/bin');
        expect(params['query'], 'a=1&b=2');
        expect(params['special'], '!@#\$%^&*()');
      });
    });

    group('clearParameters', () {
      test('should clear parameters for a specific command', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});
        await service.saveParameters('\$TIME', {'hour': '12'});

        await service.clearParameters('\$ADDR');

        expect(service.getParameters('\$ADDR'), isNull);
        expect(service.getParameters('\$TIME'), isNotNull);
      });

      test('should not throw when clearing non-existent command', () async {
        await service.clearParameters('\$NONEXISTENT');
        // Should not throw
      });
    });

    group('clearAllParameters', () {
      test('should clear all saved parameters', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});
        await service.saveParameters('\$TIME', {'hour': '12'});

        await service.clearAllParameters();

        expect(service.getParameters('\$ADDR'), isNull);
        expect(service.getParameters('\$TIME'), isNull);
      });

      test('should not affect command history', () async {
        await service.addToHistory('\$ADDR 192.168.1.1 8080');
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});

        await service.clearAllParameters();

        expect(service.getHistory(), isNotEmpty);
      });
    });

    group('command history', () {
      test('should add command to history', () async {
        await service.addToHistory('\$ADDR 192.168.1.1 8080');

        final history = service.getHistory();
        expect(history, contains('\$ADDR 192.168.1.1 8080'));
      });

      test('should add newest commands to the beginning', () async {
        await service.addToHistory('cmd1');
        await service.addToHistory('cmd2');
        await service.addToHistory('cmd3');

        final history = service.getHistory();
        expect(history[0], 'cmd3');
        expect(history[1], 'cmd2');
        expect(history[2], 'cmd1');
      });

      test('should not duplicate commands', () async {
        await service.addToHistory('cmd1');
        await service.addToHistory('cmd2');
        await service.addToHistory('cmd1'); // Add again

        final history = service.getHistory();
        expect(history.where((cmd) => cmd == 'cmd1').length, 1);
        expect(history[0], 'cmd1'); // Most recent is first
      });

      test('should limit history to 50 entries', () async {
        for (var i = 0; i < 60; i++) {
          await service.addToHistory('cmd$i');
        }

        final history = service.getHistory();
        expect(history.length, 50);
        expect(history[0], 'cmd59'); // Most recent
      });

      test('should return empty list for no history', () {
        final history = service.getHistory();
        expect(history, isEmpty);
      });

      test('should clear history', () async {
        await service.addToHistory('cmd1');
        await service.addToHistory('cmd2');

        await service.clearHistory();

        expect(service.getHistory(), isEmpty);
      });
    });

    group('getParameterValue', () {
      test('should get specific parameter value', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1', 'port': '8080'});

        expect(service.getParameterValue('\$ADDR', 'ip'), '192.168.1.1');
        expect(service.getParameterValue('\$ADDR', 'port'), '8080');
      });

      test('should return null for non-existent parameter', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});

        expect(service.getParameterValue('\$ADDR', 'nonexistent'), isNull);
      });

      test('should return null for non-existent command', () {
        expect(service.getParameterValue('\$NONEXISTENT', 'ip'), isNull);
      });
    });

    group('hasParameters', () {
      test('should return true when parameters exist', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});

        expect(service.hasParameters('\$ADDR'), true);
      });

      test('should return false when parameters do not exist', () {
        expect(service.hasParameters('\$NONEXISTENT'), false);
      });

      test('should be case insensitive', () async {
        await service.saveParameters('\$addr', {'ip': '192.168.1.1'});

        expect(service.hasParameters('\$ADDR'), true);
        expect(service.hasParameters('\$Addr'), true);
      });
    });

    group('getCommandsWithSavedParameters', () {
      test('should return list of commands with saved parameters', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});
        await service.saveParameters('\$TIME', {'hour': '12'});

        final commands = service.getCommandsWithSavedParameters();
        expect(commands.length, 2);
        // Commands are returned with $ prefix
        expect(commands, contains('\$ADDR'));
        expect(commands, contains('\$TIME'));
      });

      test('should return empty list when no parameters saved', () {
        final commands = service.getCommandsWithSavedParameters();
        expect(commands, isEmpty);
      });
    });

    group('getStorageStats', () {
      test('should return correct statistics', () async {
        await service.saveParameters('\$ADDR', {'ip': '192.168.1.1'});
        await service.saveParameters('\$TIME', {'hour': '12'});
        await service.addToHistory('cmd1');
        await service.addToHistory('cmd2');
        await service.addToHistory('cmd3');

        final stats = service.getStorageStats();
        expect(stats['commandsWithParams'], 2);
        expect(stats['historyEntries'], 3);
        expect(stats['maxHistoryEntries'], 50);
      });

      test('should return zeros for empty storage', () {
        final stats = service.getStorageStats();
        expect(stats['commandsWithParams'], 0);
        expect(stats['historyEntries'], 0);
      });
    });

    group('error handling', () {
      test('should throw StateError when not initialized', () {
        final uninitializedService = CommandParameterStorageService();

        expect(
          () => uninitializedService.getParameters('\$ADDR'),
          throwsStateError,
        );
        expect(
          () => uninitializedService.hasParameters('\$ADDR'),
          throwsStateError,
        );
        expect(
          () => uninitializedService.getHistory(),
          throwsStateError,
        );
      });

      test('should handle corrupted JSON data gracefully', () async {
        // Simulate corrupted data by accessing internal prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('command_params_CORRUPTED', 'invalid json');

        // Should return null instead of throwing
        final params = service.getParameters('\$CORRUPTED');
        expect(params, isNull);
      });
    });

    group('forTesting factory', () {
      test('should create pre-initialized instance', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final testService = CommandParameterStorageService.forTesting(prefs);

        expect(testService.isInitialized, true);
        // Should be usable immediately without calling initialize()
        await testService.saveParameters('\$TEST', {'value': 'test'});
        expect(testService.getParameters('\$TEST'), isNotNull);
      });
    });
  });
}
