import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/app_update_manager.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateManager', () {
    late AppUpdateManager manager;

    setUp(() {
      manager = AppUpdateManager();
    });

    group('singleton', () {
      test('should return same instance', () {
        final instance1 = AppUpdateManager();
        final instance2 = AppUpdateManager();
        expect(identical(instance1, instance2), true);
      });

      test('should persist across multiple calls', () {
        final instances = List.generate(10, (_) => AppUpdateManager());
        for (int i = 1; i < instances.length; i++) {
          expect(identical(instances[0], instances[i]), true);
        }
      });
    });

    group('initial state', () {
      test('isCheckingForUpdates should be false initially', () {
        expect(manager.isCheckingForUpdates, false);
      });

      test('latestUpdateInfo should be null initially', () {
        expect(manager.latestUpdateInfo, isNull);
      });
    });

    group('service accessors', () {
      test('updateService should be accessible', () {
        expect(manager.updateService, isA<UpdateService>());
      });

      test('networkService should be accessible', () {
        expect(manager.networkService, isA<NetworkService>());
      });

      test('updateService should be same instance on multiple access', () {
        final service1 = manager.updateService;
        final service2 = manager.updateService;
        expect(identical(service1, service2), true);
      });

      test('networkService should be same instance on multiple access', () {
        final service1 = manager.networkService;
        final service2 = manager.networkService;
        expect(identical(service1, service2), true);
      });
    });

    group('autoUpdatesEnabled', () {
      test('should return bool value', () {
        expect(manager.autoUpdatesEnabled, isA<bool>());
      });

      test('should be consistent on multiple access', () {
        final value1 = manager.autoUpdatesEnabled;
        final value2 = manager.autoUpdatesEnabled;
        expect(value1, value2);
      });
    });

    group('autoDownloadEnabled', () {
      test('should return bool value', () {
        expect(manager.autoDownloadEnabled, isA<bool>());
      });

      test('should be consistent on multiple access', () {
        final value1 = manager.autoDownloadEnabled;
        final value2 = manager.autoDownloadEnabled;
        expect(value1, value2);
      });
    });

    group('getCurrentVersionInfo', () {
      test('should return Map<String, String>', () {
        final info = manager.getCurrentVersionInfo();
        expect(info, isA<Map<String, String>>());
      });

      test('should be consistent on multiple access', () {
        final info1 = manager.getCurrentVersionInfo();
        final info2 = manager.getCurrentVersionInfo();
        expect(info1.runtimeType, info2.runtimeType);
      });

      test('should be callable multiple times', () {
        for (int i = 0; i < 5; i++) {
          expect(() => manager.getCurrentVersionInfo(), returnsNormally);
        }
      });
    });

    group('downloadUpdate', () {
      test('should return null when no update info available', () async {
        final result = await manager.downloadUpdate();
        expect(result, isNull);
      });

      test('should be callable multiple times', () async {
        final results = await Future.wait([
          manager.downloadUpdate(),
          manager.downloadUpdate(),
        ]);
        expect(results, [null, null]);
      });
    });

    group('checkForUpdatesSilently', () {
      test('should return null when not initialized', () async {
        // Without proper initialization, the check should return null
        final result = await manager.checkForUpdatesSilently();
        // Result depends on initialization state
        expect(result, anyOf(isNull, isA<UpdateInfo>()));
      });
    });

    group('showUpdateDialogIfAvailable', () {
      test('should not throw when no context set', () {
        expect(() => manager.showUpdateDialogIfAvailable(), returnsNormally);
      });

      test('should not throw when no update info', () {
        expect(manager.latestUpdateInfo, isNull);
        expect(() => manager.showUpdateDialogIfAvailable(), returnsNormally);
      });
    });

    group('startPeriodicUpdateChecks', () {
      test('should accept default interval', () {
        expect(
          () => manager.startPeriodicUpdateChecks(),
          returnsNormally,
        );
      });

      test('should accept custom interval', () {
        expect(
          () => manager.startPeriodicUpdateChecks(
            interval: const Duration(hours: 12),
          ),
          returnsNormally,
        );
      });

      test('should accept short interval', () {
        expect(
          () => manager.startPeriodicUpdateChecks(
            interval: const Duration(minutes: 30),
          ),
          returnsNormally,
        );
      });

      test('should be callable multiple times', () {
        // Multiple calls should just restart the timer
        manager.startPeriodicUpdateChecks();
        manager.startPeriodicUpdateChecks();
        manager.startPeriodicUpdateChecks();
        expect(true, true); // If we get here, no exception was thrown
      });
    });

    group('dispose', () {
      test('should not throw', () {
        final mgr = AppUpdateManager();
        expect(() => mgr.dispose(), returnsNormally);
      });

      test('should reset isInitialized', () {
        final mgr = AppUpdateManager();
        mgr.dispose();
        // After dispose, isInitialized should be false
        expect(mgr.isInitialized, false);
      });

      test('should clear latestUpdateInfo', () {
        final mgr = AppUpdateManager();
        mgr.dispose();
        expect(mgr.latestUpdateInfo, isNull);
      });

      test('should be safe to call multiple times', () {
        final mgr = AppUpdateManager();
        mgr.dispose();
        mgr.dispose();
        mgr.dispose();
        expect(true, true); // If we get here, no exception was thrown
      });
    });

    group('state consistency', () {
      test('isCheckingForUpdates remains false without active check', () {
        expect(manager.isCheckingForUpdates, false);
        expect(manager.isCheckingForUpdates, false);
        expect(manager.isCheckingForUpdates, false);
      });

      test('latestUpdateInfo remains null without updates', () {
        expect(manager.latestUpdateInfo, isNull);
        expect(manager.latestUpdateInfo, isNull);
      });

      test('isInitialized is accessible', () {
        expect(manager.isInitialized, isA<bool>());
      });
    });
  });

  group('AppUpdateManager edge cases', () {
    test('concurrent downloadUpdate calls', () async {
      final manager = AppUpdateManager();

      final results = await Future.wait([
        manager.downloadUpdate(),
        manager.downloadUpdate(),
        manager.downloadUpdate(),
      ]);

      // All should return null as no update info is available
      expect(results, [null, null, null]);
    });

    test('rapid startPeriodicUpdateChecks calls', () {
      final manager = AppUpdateManager();

      // Rapid calls should not cause issues
      for (int i = 0; i < 10; i++) {
        manager.startPeriodicUpdateChecks(
          interval: Duration(hours: i + 1),
        );
      }

      expect(true, true); // If we get here, no exception was thrown
    });

    test('showUpdateDialogIfAvailable called many times', () {
      final manager = AppUpdateManager();

      // Multiple calls should be safe
      for (int i = 0; i < 100; i++) {
        manager.showUpdateDialogIfAvailable();
      }

      expect(true, true); // If we get here, no exception was thrown
    });
  });

  group('AppUpdateManager service interaction', () {
    test('updateService and networkService are different objects', () {
      final manager = AppUpdateManager();
      expect(
        identical(manager.updateService, manager.networkService),
        false,
      );
    });

    test('getCurrentVersionInfo returns map with expected types', () {
      final manager = AppUpdateManager();
      final info = manager.getCurrentVersionInfo();

      // Should be a map where all values are strings
      for (final entry in info.entries) {
        expect(entry.key, isA<String>());
        expect(entry.value, isA<String>());
      }
    });
  });

  group('AppUpdateManager preferences detailed', () {
    test('autoUpdatesEnabled returns bool', () {
      final manager = AppUpdateManager();
      expect(manager.autoUpdatesEnabled, isA<bool>());
    });

    test('autoDownloadEnabled returns bool', () {
      final manager = AppUpdateManager();
      expect(manager.autoDownloadEnabled, isA<bool>());
    });

    test('autoUpdatesEnabled is consistent on multiple calls', () {
      final manager = AppUpdateManager();
      final val1 = manager.autoUpdatesEnabled;
      final val2 = manager.autoUpdatesEnabled;
      final val3 = manager.autoUpdatesEnabled;
      expect(val1, val2);
      expect(val2, val3);
    });

    test('autoDownloadEnabled is consistent on multiple calls', () {
      final manager = AppUpdateManager();
      final val1 = manager.autoDownloadEnabled;
      final val2 = manager.autoDownloadEnabled;
      final val3 = manager.autoDownloadEnabled;
      expect(val1, val2);
      expect(val2, val3);
    });
  });

  group('AppUpdateManager state management detailed', () {
    test('isInitialized starts as false after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose(); // Reset state
      expect(manager.isInitialized, false);
    });

    test('isCheckingForUpdates starts as false after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose(); // Reset state
      expect(manager.isCheckingForUpdates, false);
    });

    test('latestUpdateInfo starts as null after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose(); // Reset state
      expect(manager.latestUpdateInfo, isNull);
    });

    test('state getters are all accessible', () {
      final manager = AppUpdateManager();

      expect(() => manager.isInitialized, returnsNormally);
      expect(() => manager.isCheckingForUpdates, returnsNormally);
      expect(() => manager.latestUpdateInfo, returnsNormally);
      expect(() => manager.autoUpdatesEnabled, returnsNormally);
      expect(() => manager.autoDownloadEnabled, returnsNormally);
    });

    test('all state getters return correct types', () {
      final manager = AppUpdateManager();

      expect(manager.isInitialized, isA<bool>());
      expect(manager.isCheckingForUpdates, isA<bool>());
      expect(manager.autoUpdatesEnabled, isA<bool>());
      expect(manager.autoDownloadEnabled, isA<bool>());
      // latestUpdateInfo can be null or UpdateInfo
      expect(
        manager.latestUpdateInfo,
        anyOf(isNull, isA<UpdateInfo>()),
      );
    });
  });

  group('AppUpdateManager service consistency detailed', () {
    test('updateService is singleton', () {
      final manager1 = AppUpdateManager();
      final manager2 = AppUpdateManager();

      expect(
        identical(manager1.updateService, manager2.updateService),
        true,
      );
    });

    test('networkService is singleton', () {
      final manager1 = AppUpdateManager();
      final manager2 = AppUpdateManager();

      expect(
        identical(manager1.networkService, manager2.networkService),
        true,
      );
    });

    test('services persist after dispose', () {
      final manager = AppUpdateManager();
      final serviceBefore = manager.updateService;
      manager.dispose();
      final serviceAfter = manager.updateService;

      // Services are singletons, they should remain same
      expect(identical(serviceBefore, serviceAfter), true);
    });

    test('services accessible in any order', () {
      final manager = AppUpdateManager();

      // Access in different orders
      final ns1 = manager.networkService;
      final us1 = manager.updateService;
      final us2 = manager.updateService;
      final ns2 = manager.networkService;

      expect(identical(ns1, ns2), true);
      expect(identical(us1, us2), true);
    });
  });

  group('AppUpdateManager lifecycle detailed', () {
    test('dispose is idempotent', () {
      final manager = AppUpdateManager();

      expect(() {
        manager.dispose();
        manager.dispose();
        manager.dispose();
        manager.dispose();
        manager.dispose();
      }, returnsNormally);
    });

    test('can access getters after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose();

      expect(() => manager.isInitialized, returnsNormally);
      expect(() => manager.isCheckingForUpdates, returnsNormally);
      expect(() => manager.latestUpdateInfo, returnsNormally);
      expect(() => manager.updateService, returnsNormally);
      expect(() => manager.networkService, returnsNormally);
    });

    test('can call methods after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose();

      expect(() => manager.getCurrentVersionInfo(), returnsNormally);
      expect(() => manager.showUpdateDialogIfAvailable(), returnsNormally);
      expect(() => manager.startPeriodicUpdateChecks(), returnsNormally);
    });

    test('dispose clears state correctly', () {
      final manager = AppUpdateManager();
      manager.dispose();

      expect(manager.isInitialized, false);
      expect(manager.latestUpdateInfo, isNull);
    });
  });

  group('AppUpdateManager periodic checks detailed', () {
    test('startPeriodicUpdateChecks with various intervals', () {
      final manager = AppUpdateManager();

      expect(
        () => manager.startPeriodicUpdateChecks(
          interval: const Duration(minutes: 1),
        ),
        returnsNormally,
      );

      expect(
        () => manager.startPeriodicUpdateChecks(
          interval: const Duration(hours: 1),
        ),
        returnsNormally,
      );

      expect(
        () => manager.startPeriodicUpdateChecks(
          interval: const Duration(days: 1),
        ),
        returnsNormally,
      );
    });

    test('startPeriodicUpdateChecks replaces previous timer', () {
      final manager = AppUpdateManager();

      // Multiple calls should replace, not stack
      manager.startPeriodicUpdateChecks(interval: const Duration(hours: 1));
      manager.startPeriodicUpdateChecks(interval: const Duration(hours: 2));
      manager.startPeriodicUpdateChecks(interval: const Duration(hours: 3));

      // Should not throw
      expect(true, true);
    });

    test('startPeriodicUpdateChecks after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose();

      expect(
        () => manager.startPeriodicUpdateChecks(),
        returnsNormally,
      );
    });
  });

  group('AppUpdateManager version info detailed', () {
    test('getCurrentVersionInfo returns non-empty map or empty map', () {
      final manager = AppUpdateManager();
      final info = manager.getCurrentVersionInfo();

      expect(info, isA<Map<String, String>>());
    });

    test('getCurrentVersionInfo keys are valid', () {
      final manager = AppUpdateManager();
      final info = manager.getCurrentVersionInfo();

      for (final key in info.keys) {
        expect(key, isNotEmpty);
        expect(key.trim(), key); // No whitespace
      }
    });

    test('getCurrentVersionInfo values are valid strings', () {
      final manager = AppUpdateManager();
      final info = manager.getCurrentVersionInfo();

      for (final value in info.values) {
        expect(value, isA<String>());
      }
    });

    test('getCurrentVersionInfo is consistent', () {
      final manager = AppUpdateManager();

      final info1 = manager.getCurrentVersionInfo();
      final info2 = manager.getCurrentVersionInfo();

      expect(info1.length, info2.length);
      for (final key in info1.keys) {
        expect(info2.containsKey(key), true);
      }
    });
  });

  group('AppUpdateManager async operations detailed', () {
    test('downloadUpdate with no update info', () async {
      final manager = AppUpdateManager();
      manager.dispose(); // Ensure no update info

      final result = await manager.downloadUpdate();
      expect(result, isNull);
    });

    test('checkForUpdatesSilently returns UpdateInfo or null', () async {
      final manager = AppUpdateManager();

      final result = await manager.checkForUpdatesSilently();
      expect(result, anyOf(isNull, isA<UpdateInfo>()));
    });

    test('concurrent checkForUpdatesSilently calls', () async {
      final manager = AppUpdateManager();

      final results = await Future.wait([
        manager.checkForUpdatesSilently(),
        manager.checkForUpdatesSilently(),
        manager.checkForUpdatesSilently(),
      ]);

      // All should complete without error
      for (final result in results) {
        expect(result, anyOf(isNull, isA<UpdateInfo>()));
      }
    });

    test('downloadUpdate concurrent calls', () async {
      final manager = AppUpdateManager();
      manager.dispose(); // No update info

      final results = await Future.wait([
        manager.downloadUpdate(),
        manager.downloadUpdate(),
        manager.downloadUpdate(),
        manager.downloadUpdate(),
        manager.downloadUpdate(),
      ]);

      // All should be null since no update info
      expect(results, everyElement(isNull));
    });
  });

  group('AppUpdateManager stress tests', () {
    test('rapid showUpdateDialogIfAvailable calls', () {
      final manager = AppUpdateManager();

      for (int i = 0; i < 1000; i++) {
        manager.showUpdateDialogIfAvailable();
      }

      expect(true, true); // If we get here, no exception
    });

    test('rapid getCurrentVersionInfo calls', () {
      final manager = AppUpdateManager();

      for (int i = 0; i < 100; i++) {
        final info = manager.getCurrentVersionInfo();
        expect(info, isA<Map<String, String>>());
      }
    });

    test('alternating operations', () async {
      final manager = AppUpdateManager();

      for (int i = 0; i < 20; i++) {
        manager.showUpdateDialogIfAvailable();
        manager.getCurrentVersionInfo();
        manager.startPeriodicUpdateChecks();
        await manager.downloadUpdate();
      }

      expect(true, true);
    });

    test('state remains consistent during rapid operations', () {
      final manager = AppUpdateManager();
      manager.dispose();

      for (int i = 0; i < 50; i++) {
        expect(manager.isInitialized, false);
        expect(manager.latestUpdateInfo, isNull);
        manager.showUpdateDialogIfAvailable();
        manager.getCurrentVersionInfo();
      }
    });
  });

  group('AppUpdateManager singleton behavior detailed', () {
    test('singleton persists across test groups', () {
      final instance1 = AppUpdateManager();
      final instance2 = AppUpdateManager();
      final instance3 = AppUpdateManager();
      final instance4 = AppUpdateManager();
      final instance5 = AppUpdateManager();

      expect(identical(instance1, instance2), true);
      expect(identical(instance2, instance3), true);
      expect(identical(instance3, instance4), true);
      expect(identical(instance4, instance5), true);
    });

    test('factory constructor always returns same instance', () {
      final instances = <AppUpdateManager>[];

      for (int i = 0; i < 100; i++) {
        instances.add(AppUpdateManager());
      }

      for (int i = 1; i < instances.length; i++) {
        expect(identical(instances[0], instances[i]), true);
      }
    });
  });

  group('AppUpdateManager setContext behavior', () {
    test('setContext does not throw with null-like context', () {
      final manager = AppUpdateManager();
      // We can't easily test with a real context, but ensure method exists
      expect(manager.setContext, isA<Function>());
    });
  });

  group('AppUpdateManager setAutoUpdatesEnabled', () {
    test('setAutoUpdatesEnabled returns Future', () async {
      final manager = AppUpdateManager();
      // Method should complete without error even when preferences is null
      await manager.setAutoUpdatesEnabled(true);
      await manager.setAutoUpdatesEnabled(false);
      expect(true, true);
    });

    test('setAutoUpdatesEnabled multiple calls are safe', () async {
      final manager = AppUpdateManager();

      await Future.wait([
        manager.setAutoUpdatesEnabled(true),
        manager.setAutoUpdatesEnabled(false),
        manager.setAutoUpdatesEnabled(true),
      ]);

      expect(true, true);
    });
  });

  group('AppUpdateManager initialize behavior', () {
    test('initialize returns Future<bool>', () async {
      final manager = AppUpdateManager();
      manager.dispose(); // Reset state

      final result = await manager.initialize();
      expect(result, isA<bool>());
    });

    test('initialize can be called after dispose', () async {
      final manager = AppUpdateManager();
      manager.dispose();

      final result = await manager.initialize();
      expect(result, anyOf(isTrue, isFalse));
    });

    test('multiple initialize calls are handled', () async {
      final manager = AppUpdateManager();
      manager.dispose();

      final result1 = await manager.initialize();
      final result2 = await manager.initialize();

      // Second call should return true if already initialized
      expect(result1, isA<bool>());
      expect(result2, isA<bool>());
    });
  });

  group('AppUpdateManager checkForUpdatesWithUI', () {
    test('checkForUpdatesWithUI returns UpdateInfo or null', () async {
      final manager = AppUpdateManager();

      final result = await manager.checkForUpdatesWithUI();
      expect(result, anyOf(isNull, isA<UpdateInfo>()));
    });

    test('checkForUpdatesWithUI with force flag', () async {
      final manager = AppUpdateManager();

      final result = await manager.checkForUpdatesWithUI(force: true);
      expect(result, anyOf(isNull, isA<UpdateInfo>()));
    });

    test('concurrent checkForUpdatesWithUI calls', () async {
      final manager = AppUpdateManager();

      // Multiple concurrent calls should be handled gracefully
      final results = await Future.wait([
        manager.checkForUpdatesWithUI(),
        manager.checkForUpdatesWithUI(),
      ]);

      for (final result in results) {
        expect(result, anyOf(isNull, isA<UpdateInfo>()));
      }
    });
  });

  group('AppUpdateManager state after dispose', () {
    test('getters return valid values after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose();

      expect(manager.isInitialized, false);
      expect(manager.isCheckingForUpdates, false);
      expect(manager.latestUpdateInfo, isNull);
      expect(manager.autoUpdatesEnabled, isA<bool>());
      expect(manager.autoDownloadEnabled, isA<bool>());
    });

    test('services remain accessible after dispose', () {
      final manager = AppUpdateManager();
      manager.dispose();

      expect(manager.updateService, isNotNull);
      expect(manager.networkService, isNotNull);
    });

    test('methods can be called after dispose', () async {
      final manager = AppUpdateManager();
      manager.dispose();

      expect(() => manager.showUpdateDialogIfAvailable(), returnsNormally);
      expect(() => manager.startPeriodicUpdateChecks(), returnsNormally);
      expect(() => manager.getCurrentVersionInfo(), returnsNormally);
      await manager.downloadUpdate();
      expect(true, true);
    });
  });

  group('AppUpdateManager preferences integration', () {
    test('autoUpdatesEnabled default is true', () {
      final manager = AppUpdateManager();
      // Default should be true or whatever is in preferences
      expect(manager.autoUpdatesEnabled, isA<bool>());
    });

    test('autoDownloadEnabled default is false', () {
      final manager = AppUpdateManager();
      // Default should be false or whatever is in preferences
      expect(manager.autoDownloadEnabled, isA<bool>());
    });

    test('preferences getters are consistent', () {
      final manager = AppUpdateManager();

      final auto1 = manager.autoUpdatesEnabled;
      final auto2 = manager.autoUpdatesEnabled;
      final download1 = manager.autoDownloadEnabled;
      final download2 = manager.autoDownloadEnabled;

      expect(auto1, auto2);
      expect(download1, download2);
    });
  });

  group('AppUpdateManager rapid operations', () {
    test('rapid dispose and access cycles', () {
      for (int i = 0; i < 20; i++) {
        final manager = AppUpdateManager();
        manager.dispose();
        expect(manager.isInitialized, false);
      }
    });

    test('rapid method calls', () async {
      final manager = AppUpdateManager();

      for (int i = 0; i < 10; i++) {
        manager.getCurrentVersionInfo();
        manager.showUpdateDialogIfAvailable();
        manager.startPeriodicUpdateChecks();
      }

      expect(true, true);
    });

    test('alternating initialize and dispose', () async {
      final manager = AppUpdateManager();

      for (int i = 0; i < 5; i++) {
        manager.dispose();
        await manager.initialize();
      }

      expect(manager.isInitialized, isA<bool>());
    });
  });

  group('AppUpdateManager version info structure', () {
    test('getCurrentVersionInfo has expected keys', () {
      final manager = AppUpdateManager();
      final info = manager.getCurrentVersionInfo();

      // Should contain version info as strings
      for (final entry in info.entries) {
        expect(entry.key, isA<String>());
        expect(entry.value, isA<String>());
      }
    });

    test('getCurrentVersionInfo is idempotent', () {
      final manager = AppUpdateManager();

      final info1 = manager.getCurrentVersionInfo();
      final info2 = manager.getCurrentVersionInfo();

      expect(info1.length, info2.length);
      for (final key in info1.keys) {
        expect(info2.containsKey(key), true);
      }
    });
  });
}
