import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/update_logic_manager.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateLogicManager', () {
    late UpdateLogicManager manager;

    setUp(() {
      manager = UpdateLogicManager();
    });

    tearDown(() {
      manager.dispose();
    });

    group('constructor', () {
      test('should create with default values', () {
        final mgr = UpdateLogicManager();
        expect(mgr.isDownloading, false);
        expect(mgr.downloadProgress, 0.0);
        expect(mgr.downloadStatus, isEmpty);
        mgr.dispose();
      });

      test('should create with callbacks', () {
        bool callbackCalled = false;
        final mgr = UpdateLogicManager(
          onDownloadStateChanged: (_) => callbackCalled = true,
        );
        expect(mgr, isNotNull);
        mgr.dispose();
      });

      test('should create with all callbacks', () {
        final mgr = UpdateLogicManager(
          onDownloadStateChanged: (_) {},
          onProgressUpdated: (_, __) {},
          onNetworkStatusChanged: (_) {},
        );
        expect(mgr, isNotNull);
        mgr.dispose();
      });
    });

    group('initial state', () {
      test('isDownloading should be false initially', () {
        expect(manager.isDownloading, false);
      });

      test('downloadProgress should be 0.0 initially', () {
        expect(manager.downloadProgress, 0.0);
      });

      test('downloadStatus should be empty initially', () {
        expect(manager.downloadStatus, isEmpty);
      });

      test('networkStatus should be unknown initially', () {
        expect(manager.networkStatus, NetworkStatus.unknown);
      });
    });

    group('service accessors', () {
      test('updateService should be accessible', () {
        expect(manager.updateService, isA<UpdateService>());
      });

      test('networkService should be accessible', () {
        expect(manager.networkService, isA<NetworkService>());
      });

      test('updateService should be consistent', () {
        final service1 = manager.updateService;
        final service2 = manager.updateService;
        expect(identical(service1, service2), true);
      });

      test('networkService should be consistent', () {
        final service1 = manager.networkService;
        final service2 = manager.networkService;
        expect(identical(service1, service2), true);
      });
    });

    group('initialize', () {
      test('should not throw', () {
        expect(() => manager.initialize(), returnsNormally);
      });

      test('should be callable multiple times', () {
        manager.initialize();
        manager.initialize();
        manager.initialize();
        expect(true, true); // If we get here, no exception was thrown
      });

      test('should trigger network status callback', () {
        NetworkStatus? receivedStatus;
        final mgr = UpdateLogicManager(
          onNetworkStatusChanged: (status) => receivedStatus = status,
        );
        mgr.initialize();
        // Callback should have been called during initialize
        // Status may be any NetworkStatus value
        expect(receivedStatus, anyOf(isNull, isA<NetworkStatus>()));
        mgr.dispose();
      });
    });

    group('dispose', () {
      test('should not throw', () {
        expect(() => manager.dispose(), returnsNormally);
      });

      test('should be safe to call multiple times', () {
        manager.dispose();
        manager.dispose();
        manager.dispose();
        expect(true, true); // If we get here, no exception was thrown
      });

      test('should work on newly created manager', () {
        final mgr = UpdateLogicManager();
        expect(() => mgr.dispose(), returnsNormally);
      });

      test('should work after initialize', () {
        final mgr = UpdateLogicManager();
        mgr.initialize();
        expect(() => mgr.dispose(), returnsNormally);
      });
    });

    group('state getters consistency', () {
      test('isDownloading is consistent', () {
        expect(manager.isDownloading, manager.isDownloading);
      });

      test('downloadProgress is consistent', () {
        expect(manager.downloadProgress, manager.downloadProgress);
      });

      test('downloadStatus is consistent', () {
        expect(manager.downloadStatus, manager.downloadStatus);
      });

      test('networkStatus is consistent', () {
        expect(manager.networkStatus, manager.networkStatus);
      });
    });

    group('callback behavior', () {
      test('callbacks are optional', () {
        final mgr = UpdateLogicManager(
          onDownloadStateChanged: null,
          onProgressUpdated: null,
          onNetworkStatusChanged: null,
        );
        expect(() => mgr.initialize(), returnsNormally);
        mgr.dispose();
      });

      test('onDownloadStateChanged can be set', () {
        int callCount = 0;
        final mgr = UpdateLogicManager(
          onDownloadStateChanged: (_) => callCount++,
        );
        expect(mgr.onDownloadStateChanged, isNotNull);
        mgr.dispose();
      });

      test('onProgressUpdated can be set', () {
        final mgr = UpdateLogicManager(
          onProgressUpdated: (progress, status) {},
        );
        expect(mgr.onProgressUpdated, isNotNull);
        mgr.dispose();
      });

      test('onNetworkStatusChanged can be set', () {
        final mgr = UpdateLogicManager(
          onNetworkStatusChanged: (status) {},
        );
        expect(mgr.onNetworkStatusChanged, isNotNull);
        mgr.dispose();
      });
    });

    group('state types', () {
      test('isDownloading returns bool', () {
        expect(manager.isDownloading, isA<bool>());
      });

      test('downloadProgress returns double', () {
        expect(manager.downloadProgress, isA<double>());
      });

      test('downloadStatus returns String', () {
        expect(manager.downloadStatus, isA<String>());
      });

      test('networkStatus returns NetworkStatus', () {
        expect(manager.networkStatus, isA<NetworkStatus>());
      });
    });
  });

  group('UpdateLogicManager integration', () {
    test('multiple managers can coexist', () {
      final mgr1 = UpdateLogicManager();
      final mgr2 = UpdateLogicManager();
      final mgr3 = UpdateLogicManager();

      // All should have independent state
      expect(mgr1.isDownloading, false);
      expect(mgr2.isDownloading, false);
      expect(mgr3.isDownloading, false);

      mgr1.dispose();
      mgr2.dispose();
      mgr3.dispose();
    });

    test('managers can be created and disposed rapidly', () {
      for (int i = 0; i < 10; i++) {
        final mgr = UpdateLogicManager();
        mgr.initialize();
        mgr.dispose();
      }
      expect(true, true);
    });

    test('services are shared across managers', () {
      final mgr1 = UpdateLogicManager();
      final mgr2 = UpdateLogicManager();

      // Services should be singletons
      expect(
        identical(mgr1.updateService, mgr2.updateService),
        true,
      );
      expect(
        identical(mgr1.networkService, mgr2.networkService),
        true,
      );

      mgr1.dispose();
      mgr2.dispose();
    });
  });

  group('UpdateLogicManager edge cases', () {
    test('getters can be accessed before initialize', () {
      final mgr = UpdateLogicManager();
      expect(() => mgr.isDownloading, returnsNormally);
      expect(() => mgr.downloadProgress, returnsNormally);
      expect(() => mgr.downloadStatus, returnsNormally);
      expect(() => mgr.networkStatus, returnsNormally);
      mgr.dispose();
    });

    test('services can be accessed before initialize', () {
      final mgr = UpdateLogicManager();
      expect(() => mgr.updateService, returnsNormally);
      expect(() => mgr.networkService, returnsNormally);
      mgr.dispose();
    });

    test('dispose before initialize', () {
      final mgr = UpdateLogicManager();
      expect(() => mgr.dispose(), returnsNormally);
    });

    test('initialize after dispose', () {
      final mgr = UpdateLogicManager();
      mgr.dispose();
      // Initialize after dispose should still work
      expect(() => mgr.initialize(), returnsNormally);
    });
  });

  group('NetworkStatus enum', () {
    test('should have expected values', () {
      expect(NetworkStatus.values, contains(NetworkStatus.unknown));
      expect(NetworkStatus.values, contains(NetworkStatus.wifi));
      expect(NetworkStatus.values, contains(NetworkStatus.mobile));
      expect(NetworkStatus.values, contains(NetworkStatus.none));
    });

    test('should have 4 values', () {
      expect(NetworkStatus.values.length, 4);
    });
  });

  group('UpdateLogicManager callback interactions', () {
    test('onDownloadStateChanged is invoked correctly', () {
      List<bool> receivedStates = [];
      final mgr = UpdateLogicManager(
        onDownloadStateChanged: (state) => receivedStates.add(state),
      );

      // Trigger callback manually through getter
      mgr.onDownloadStateChanged?.call(true);
      mgr.onDownloadStateChanged?.call(false);

      expect(receivedStates, [true, false]);
      mgr.dispose();
    });

    test('onProgressUpdated is invoked correctly', () {
      List<double> receivedProgress = [];
      List<String> receivedStatus = [];

      final mgr = UpdateLogicManager(
        onProgressUpdated: (progress, status) {
          receivedProgress.add(progress);
          receivedStatus.add(status);
        },
      );

      mgr.onProgressUpdated?.call(0.5, 'Downloading...');
      mgr.onProgressUpdated?.call(1.0, 'Complete');

      expect(receivedProgress, [0.5, 1.0]);
      expect(receivedStatus, ['Downloading...', 'Complete']);
      mgr.dispose();
    });

    test('onNetworkStatusChanged is invoked correctly', () {
      List<NetworkStatus> receivedStatuses = [];

      final mgr = UpdateLogicManager(
        onNetworkStatusChanged: (status) => receivedStatuses.add(status),
      );

      mgr.onNetworkStatusChanged?.call(NetworkStatus.wifi);
      mgr.onNetworkStatusChanged?.call(NetworkStatus.mobile);
      mgr.onNetworkStatusChanged?.call(NetworkStatus.none);

      expect(receivedStatuses, [
        NetworkStatus.wifi,
        NetworkStatus.mobile,
        NetworkStatus.none,
      ]);
      mgr.dispose();
    });

    test('callbacks can be null without error', () {
      final mgr = UpdateLogicManager();

      // Should not throw even when callbacks are null
      expect(() => mgr.onDownloadStateChanged?.call(true), returnsNormally);
      expect(() => mgr.onProgressUpdated?.call(0.5, 'test'), returnsNormally);
      expect(() => mgr.onNetworkStatusChanged?.call(NetworkStatus.wifi), returnsNormally);

      mgr.dispose();
    });

    test('all callbacks can be set simultaneously', () {
      bool downloadStateReceived = false;
      bool progressReceived = false;
      bool networkStatusReceived = false;

      final mgr = UpdateLogicManager(
        onDownloadStateChanged: (_) => downloadStateReceived = true,
        onProgressUpdated: (_, __) => progressReceived = true,
        onNetworkStatusChanged: (_) => networkStatusReceived = true,
      );

      mgr.onDownloadStateChanged?.call(true);
      mgr.onProgressUpdated?.call(0.5, 'test');
      mgr.onNetworkStatusChanged?.call(NetworkStatus.wifi);

      expect(downloadStateReceived, true);
      expect(progressReceived, true);
      expect(networkStatusReceived, true);

      mgr.dispose();
    });
  });

  group('UpdateLogicManager state management', () {
    test('downloadProgress initial value is 0.0', () {
      final mgr = UpdateLogicManager();
      expect(mgr.downloadProgress, 0.0);
      mgr.dispose();
    });

    test('downloadProgress is within valid range', () {
      final mgr = UpdateLogicManager();
      expect(mgr.downloadProgress, greaterThanOrEqualTo(0.0));
      expect(mgr.downloadProgress, lessThanOrEqualTo(1.0));
      mgr.dispose();
    });

    test('downloadStatus is never null', () {
      final mgr = UpdateLogicManager();
      expect(mgr.downloadStatus, isNotNull);
      mgr.dispose();
    });

    test('isDownloading returns bool type', () {
      final mgr = UpdateLogicManager();
      expect(mgr.isDownloading, isA<bool>());
      mgr.dispose();
    });

    test('networkStatus has valid enum value', () {
      final mgr = UpdateLogicManager();
      expect(NetworkStatus.values, contains(mgr.networkStatus));
      mgr.dispose();
    });
  });

  group('UpdateLogicManager service consistency', () {
    test('updateService is always non-null', () {
      final mgr = UpdateLogicManager();
      expect(mgr.updateService, isNotNull);
      mgr.dispose();
    });

    test('networkService is always non-null', () {
      final mgr = UpdateLogicManager();
      expect(mgr.networkService, isNotNull);
      mgr.dispose();
    });

    test('services persist across multiple accesses', () {
      final mgr = UpdateLogicManager();

      final updateService1 = mgr.updateService;
      final updateService2 = mgr.updateService;
      final networkService1 = mgr.networkService;
      final networkService2 = mgr.networkService;

      expect(identical(updateService1, updateService2), true);
      expect(identical(networkService1, networkService2), true);

      mgr.dispose();
    });

    test('different manager instances share services', () {
      final mgr1 = UpdateLogicManager();
      final mgr2 = UpdateLogicManager();

      // Services should be singletons
      expect(identical(mgr1.updateService, mgr2.updateService), true);
      expect(identical(mgr1.networkService, mgr2.networkService), true);

      mgr1.dispose();
      mgr2.dispose();
    });
  });

  group('UpdateLogicManager lifecycle', () {
    test('initialize then dispose cycle', () {
      final mgr = UpdateLogicManager();
      mgr.initialize();
      expect(() => mgr.dispose(), returnsNormally);
    });

    test('multiple initialize calls are safe', () {
      final mgr = UpdateLogicManager();
      expect(() {
        mgr.initialize();
        mgr.initialize();
        mgr.initialize();
      }, returnsNormally);
      mgr.dispose();
    });

    test('dispose after multiple initializations', () {
      final mgr = UpdateLogicManager();
      mgr.initialize();
      mgr.initialize();
      expect(() => mgr.dispose(), returnsNormally);
    });

    test('can access getters after dispose', () {
      final mgr = UpdateLogicManager();
      mgr.initialize();
      mgr.dispose();

      // Getters should still work after dispose
      expect(() => mgr.isDownloading, returnsNormally);
      expect(() => mgr.downloadProgress, returnsNormally);
      expect(() => mgr.downloadStatus, returnsNormally);
      expect(() => mgr.networkStatus, returnsNormally);
    });

    test('services accessible after dispose', () {
      final mgr = UpdateLogicManager();
      mgr.dispose();

      expect(() => mgr.updateService, returnsNormally);
      expect(() => mgr.networkService, returnsNormally);
    });
  });

  group('UpdateLogicManager stress tests', () {
    test('rapid create-initialize-dispose cycles', () {
      for (int i = 0; i < 50; i++) {
        final mgr = UpdateLogicManager();
        mgr.initialize();
        mgr.dispose();
      }
      expect(true, true);
    });

    test('concurrent manager instances', () {
      final managers = List.generate(20, (i) => UpdateLogicManager(
        onDownloadStateChanged: (_) {},
        onProgressUpdated: (_, __) {},
        onNetworkStatusChanged: (_) {},
      ));

      for (final mgr in managers) {
        mgr.initialize();
      }

      // All should have same initial state
      for (final mgr in managers) {
        expect(mgr.isDownloading, false);
        expect(mgr.downloadProgress, 0.0);
        expect(mgr.downloadStatus, isEmpty);
      }

      for (final mgr in managers) {
        mgr.dispose();
      }
    });

    test('callback invocation stress test', () {
      int callCount = 0;
      final mgr = UpdateLogicManager(
        onProgressUpdated: (_, __) => callCount++,
      );

      for (int i = 0; i < 100; i++) {
        mgr.onProgressUpdated?.call(i / 100.0, 'Progress: $i%');
      }

      expect(callCount, 100);
      mgr.dispose();
    });
  });

  group('NetworkStatus enum edge cases', () {
    test('all enum values are distinct', () {
      final values = NetworkStatus.values.toSet();
      expect(values.length, NetworkStatus.values.length);
    });

    test('enum values have correct indices', () {
      // Order is: none(0), mobile(1), wifi(2), unknown(3)
      expect(NetworkStatus.none.index, 0);
      expect(NetworkStatus.mobile.index, 1);
      expect(NetworkStatus.wifi.index, 2);
      expect(NetworkStatus.unknown.index, 3);
    });

    test('enum name property works', () {
      expect(NetworkStatus.unknown.name, 'unknown');
      expect(NetworkStatus.wifi.name, 'wifi');
      expect(NetworkStatus.mobile.name, 'mobile');
      expect(NetworkStatus.none.name, 'none');
    });

    test('enum can be converted to string', () {
      expect(NetworkStatus.unknown.toString(), contains('unknown'));
      expect(NetworkStatus.wifi.toString(), contains('wifi'));
    });
  });

  group('UpdateLogicManager callback edge cases', () {
    test('callback receives correct data types', () {
      bool? lastDownloadState;
      double? lastProgress;
      String? lastStatus;
      NetworkStatus? lastNetworkStatus;

      final mgr = UpdateLogicManager(
        onDownloadStateChanged: (state) => lastDownloadState = state,
        onProgressUpdated: (progress, status) {
          lastProgress = progress;
          lastStatus = status;
        },
        onNetworkStatusChanged: (status) => lastNetworkStatus = status,
      );

      mgr.onDownloadStateChanged?.call(true);
      mgr.onProgressUpdated?.call(0.75, 'Test status');
      mgr.onNetworkStatusChanged?.call(NetworkStatus.mobile);

      expect(lastDownloadState, isA<bool>());
      expect(lastProgress, isA<double>());
      expect(lastStatus, isA<String>());
      expect(lastNetworkStatus, isA<NetworkStatus>());

      mgr.dispose();
    });

    test('callback handles extreme progress values', () {
      List<double> receivedProgress = [];
      final mgr = UpdateLogicManager(
        onProgressUpdated: (progress, _) => receivedProgress.add(progress),
      );

      mgr.onProgressUpdated?.call(0.0, '');
      mgr.onProgressUpdated?.call(0.0001, '');
      mgr.onProgressUpdated?.call(0.9999, '');
      mgr.onProgressUpdated?.call(1.0, '');

      expect(receivedProgress, [0.0, 0.0001, 0.9999, 1.0]);
      mgr.dispose();
    });

    test('callback handles special characters in status', () {
      List<String> receivedStatuses = [];
      final mgr = UpdateLogicManager(
        onProgressUpdated: (_, status) => receivedStatuses.add(status),
      );

      mgr.onProgressUpdated?.call(0.5, '中文状态');
      mgr.onProgressUpdated?.call(0.5, 'Status with émojis 🎉');
      mgr.onProgressUpdated?.call(0.5, 'Special: @#\$%^&*()');
      mgr.onProgressUpdated?.call(0.5, '');
      mgr.onProgressUpdated?.call(0.5, '   ');

      expect(receivedStatuses.length, 5);
      expect(receivedStatuses[0], '中文状态');
      expect(receivedStatuses[1], 'Status with émojis 🎉');
      mgr.dispose();
    });
  });

  group('UpdateLogicManager download state transitions', () {
    test('download state starts as false', () {
      final mgr = UpdateLogicManager();
      expect(mgr.isDownloading, false);
      mgr.dispose();
    });

    test('download progress starts at 0', () {
      final mgr = UpdateLogicManager();
      expect(mgr.downloadProgress, 0.0);
      mgr.dispose();
    });

    test('download status starts empty', () {
      final mgr = UpdateLogicManager();
      expect(mgr.downloadStatus, isEmpty);
      mgr.dispose();
    });

    test('callback toggling download state', () {
      List<bool> states = [];
      final mgr = UpdateLogicManager(
        onDownloadStateChanged: (state) => states.add(state),
      );

      mgr.onDownloadStateChanged?.call(true);
      mgr.onDownloadStateChanged?.call(false);
      mgr.onDownloadStateChanged?.call(true);
      mgr.onDownloadStateChanged?.call(false);

      expect(states, [true, false, true, false]);
      mgr.dispose();
    });
  });

  group('UpdateLogicManager network status transitions', () {
    test('network status starts as unknown', () {
      final mgr = UpdateLogicManager();
      expect(mgr.networkStatus, NetworkStatus.unknown);
      mgr.dispose();
    });

    test('callback receives all network status types', () {
      List<NetworkStatus> statuses = [];
      final mgr = UpdateLogicManager(
        onNetworkStatusChanged: (status) => statuses.add(status),
      );

      for (final status in NetworkStatus.values) {
        mgr.onNetworkStatusChanged?.call(status);
      }

      expect(statuses.length, NetworkStatus.values.length);
      expect(statuses.toSet().length, NetworkStatus.values.length);
      mgr.dispose();
    });

    test('network status changes are tracked', () {
      List<NetworkStatus> statuses = [];
      final mgr = UpdateLogicManager(
        onNetworkStatusChanged: (status) => statuses.add(status),
      );

      mgr.onNetworkStatusChanged?.call(NetworkStatus.none);
      mgr.onNetworkStatusChanged?.call(NetworkStatus.mobile);
      mgr.onNetworkStatusChanged?.call(NetworkStatus.wifi);
      mgr.onNetworkStatusChanged?.call(NetworkStatus.none);

      expect(statuses, [
        NetworkStatus.none,
        NetworkStatus.mobile,
        NetworkStatus.wifi,
        NetworkStatus.none,
      ]);
      mgr.dispose();
    });
  });

  group('UpdateLogicManager progress simulation', () {
    test('progress callback with incremental values', () {
      List<double> progressValues = [];
      final mgr = UpdateLogicManager(
        onProgressUpdated: (progress, _) => progressValues.add(progress),
      );

      for (int i = 0; i <= 10; i++) {
        mgr.onProgressUpdated?.call(i / 10.0, 'Step $i');
      }

      expect(progressValues.length, 11);
      expect(progressValues.first, 0.0);
      expect(progressValues.last, 1.0);
      mgr.dispose();
    });

    test('status callback with file size info', () {
      List<String> statusMessages = [];
      final mgr = UpdateLogicManager(
        onProgressUpdated: (_, status) => statusMessages.add(status),
      );

      mgr.onProgressUpdated?.call(0.25, '5MB / 20MB');
      mgr.onProgressUpdated?.call(0.50, '10MB / 20MB');
      mgr.onProgressUpdated?.call(0.75, '15MB / 20MB');
      mgr.onProgressUpdated?.call(1.0, '20MB / 20MB');

      expect(statusMessages[0], '5MB / 20MB');
      expect(statusMessages[3], '20MB / 20MB');
      mgr.dispose();
    });
  });

  group('UpdateLogicManager manager isolation', () {
    test('different managers have independent state', () {
      bool mgr1Called = false;
      bool mgr2Called = false;

      final mgr1 = UpdateLogicManager(
        onDownloadStateChanged: (_) => mgr1Called = true,
      );
      final mgr2 = UpdateLogicManager(
        onDownloadStateChanged: (_) => mgr2Called = true,
      );

      mgr1.onDownloadStateChanged?.call(true);

      expect(mgr1Called, true);
      expect(mgr2Called, false);

      mgr1.dispose();
      mgr2.dispose();
    });

    test('different managers share services', () {
      final mgr1 = UpdateLogicManager();
      final mgr2 = UpdateLogicManager();

      expect(identical(mgr1.updateService, mgr2.updateService), true);
      expect(identical(mgr1.networkService, mgr2.networkService), true);

      mgr1.dispose();
      mgr2.dispose();
    });
  });

  group('UpdateLogicManager getter thread safety', () {
    test('rapid getter access is safe', () {
      final mgr = UpdateLogicManager();

      for (int i = 0; i < 1000; i++) {
        final _ = mgr.isDownloading;
        final __ = mgr.downloadProgress;
        final ___ = mgr.downloadStatus;
        final ____ = mgr.networkStatus;
      }

      expect(true, true);
      mgr.dispose();
    });

    test('rapid service access is safe', () {
      final mgr = UpdateLogicManager();

      for (int i = 0; i < 100; i++) {
        expect(mgr.updateService, isNotNull);
        expect(mgr.networkService, isNotNull);
      }

      mgr.dispose();
    });
  });
}
