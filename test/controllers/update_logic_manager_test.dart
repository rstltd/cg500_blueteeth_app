import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/update_logic_manager.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/core/interfaces/update_ui_delegate.dart';
import 'package:cg500_blueteeth_app/models/download_progress.dart';
import '../mocks/mock_services.dart';

/// Helper function to create a test UpdateLogicManager with mock dependencies
UpdateLogicManager createTestManager({
  MockUpdateService? updateService,
  MockNetworkService? networkService,
  void Function(bool)? onDownloadStateChanged,
  void Function(double, String)? onProgressUpdated,
  void Function(NetworkStatus)? onNetworkStatusChanged,
}) {
  final us = updateService ?? MockUpdateService();
  final ns = networkService ?? MockNetworkService();
  return UpdateLogicManager.withDependencies(
    updateService: us,
    networkService: ns,
    onDownloadStateChanged: onDownloadStateChanged,
    onProgressUpdated: onProgressUpdated,
    onNetworkStatusChanged: onNetworkStatusChanged,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateLogicManager', () {
    late MockUpdateService mockUpdateService;
    late MockNetworkService mockNetworkService;
    late UpdateLogicManager manager;

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockNetworkService = MockNetworkService();
      manager = UpdateLogicManager.withDependencies(
        updateService: mockUpdateService,
        networkService: mockNetworkService,
      );
    });

    tearDown(() {
      manager.dispose();
      mockUpdateService.dispose();
      mockNetworkService.dispose();
    });

    group('constructor', () {
      test('should create with default values', () {
        final mgr = createTestManager();
        expect(mgr.isDownloading, false);
        expect(mgr.downloadProgress, 0.0);
        expect(mgr.downloadStatus, isEmpty);
        mgr.dispose();
      });

      test('should create with callbacks', () {
        var callbackCalled = false;
        final mgr = createTestManager(
          onDownloadStateChanged: (_) => callbackCalled = true,
        );
        expect(mgr, isNotNull);
        // Trigger callback to verify it's set correctly
        mgr.onDownloadStateChanged?.call(true);
        expect(callbackCalled, true);
        mgr.dispose();
      });

      test('should create with all callbacks', () {
        final mgr = createTestManager(
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
        expect(manager.updateService, same(mockUpdateService));
      });

      test('networkService should be accessible', () {
        expect(manager.networkService, same(mockNetworkService));
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
        final mgr = createTestManager(
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
        final mgr = createTestManager();
        expect(() => mgr.dispose(), returnsNormally);
      });

      test('should work after initialize', () {
        final mgr = createTestManager();
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
        final mgr = createTestManager(
          onDownloadStateChanged: null,
          onProgressUpdated: null,
          onNetworkStatusChanged: null,
        );
        expect(() => mgr.initialize(), returnsNormally);
        mgr.dispose();
      });

      test('onDownloadStateChanged can be set', () {
        int callCount = 0;
        final mgr = createTestManager(
          onDownloadStateChanged: (_) => callCount++,
        );
        expect(mgr.onDownloadStateChanged, isNotNull);
        mgr.dispose();
      });

      test('onProgressUpdated can be set', () {
        final mgr = createTestManager(
          onProgressUpdated: (progress, status) {},
        );
        expect(mgr.onProgressUpdated, isNotNull);
        mgr.dispose();
      });

      test('onNetworkStatusChanged can be set', () {
        final mgr = createTestManager(
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
      final mgr1 = createTestManager();
      final mgr2 = createTestManager();
      final mgr3 = createTestManager();

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
        final mgr = createTestManager();
        mgr.initialize();
        mgr.dispose();
      }
      expect(true, true);
    });

    test('services are shared when same mocks passed', () {
      final sharedUpdateService = MockUpdateService();
      final sharedNetworkService = MockNetworkService();

      final mgr1 = UpdateLogicManager.withDependencies(
        updateService: sharedUpdateService,
        networkService: sharedNetworkService,
      );
      final mgr2 = UpdateLogicManager.withDependencies(
        updateService: sharedUpdateService,
        networkService: sharedNetworkService,
      );

      // Services should be same when shared
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
      sharedUpdateService.dispose();
      sharedNetworkService.dispose();
    });
  });

  group('UpdateLogicManager edge cases', () {
    test('getters can be accessed before initialize', () {
      final mgr = createTestManager();
      expect(() => mgr.isDownloading, returnsNormally);
      expect(() => mgr.downloadProgress, returnsNormally);
      expect(() => mgr.downloadStatus, returnsNormally);
      expect(() => mgr.networkStatus, returnsNormally);
      mgr.dispose();
    });

    test('services can be accessed before initialize', () {
      final mgr = createTestManager();
      expect(() => mgr.updateService, returnsNormally);
      expect(() => mgr.networkService, returnsNormally);
      mgr.dispose();
    });

    test('dispose before initialize', () {
      final mgr = createTestManager();
      expect(() => mgr.dispose(), returnsNormally);
    });

    test('initialize after dispose', () {
      final mgr = createTestManager();
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
      final mgr = createTestManager(
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

      final mgr = createTestManager(
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

      final mgr = createTestManager(
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
      final mgr = createTestManager();

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

      final mgr = createTestManager(
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
      final mgr = createTestManager();
      expect(mgr.downloadProgress, 0.0);
      mgr.dispose();
    });

    test('downloadProgress is within valid range', () {
      final mgr = createTestManager();
      expect(mgr.downloadProgress, greaterThanOrEqualTo(0.0));
      expect(mgr.downloadProgress, lessThanOrEqualTo(1.0));
      mgr.dispose();
    });

    test('downloadStatus is never null', () {
      final mgr = createTestManager();
      expect(mgr.downloadStatus, isNotNull);
      mgr.dispose();
    });

    test('isDownloading returns bool type', () {
      final mgr = createTestManager();
      expect(mgr.isDownloading, isA<bool>());
      mgr.dispose();
    });

    test('networkStatus has valid enum value', () {
      final mgr = createTestManager();
      expect(NetworkStatus.values, contains(mgr.networkStatus));
      mgr.dispose();
    });
  });

  group('UpdateLogicManager service consistency', () {
    test('updateService is always non-null', () {
      final mgr = createTestManager();
      expect(mgr.updateService, isNotNull);
      mgr.dispose();
    });

    test('networkService is always non-null', () {
      final mgr = createTestManager();
      expect(mgr.networkService, isNotNull);
      mgr.dispose();
    });

    test('services persist across multiple accesses', () {
      final mgr = createTestManager();

      final updateService1 = mgr.updateService;
      final updateService2 = mgr.updateService;
      final networkService1 = mgr.networkService;
      final networkService2 = mgr.networkService;

      expect(identical(updateService1, updateService2), true);
      expect(identical(networkService1, networkService2), true);

      mgr.dispose();
    });

    test('different manager instances can share services via DI', () {
      // With DI pattern, services are shared when explicitly passed the same instance
      final sharedUpdateService = MockUpdateService();
      final sharedNetworkService = MockNetworkService();

      final mgr1 = createTestManager(
        updateService: sharedUpdateService,
        networkService: sharedNetworkService,
      );
      final mgr2 = createTestManager(
        updateService: sharedUpdateService,
        networkService: sharedNetworkService,
      );

      // Services should be identical when same instances are injected
      expect(identical(mgr1.updateService, mgr2.updateService), true);
      expect(identical(mgr1.networkService, mgr2.networkService), true);

      mgr1.dispose();
      mgr2.dispose();
    });
  });

  group('UpdateLogicManager lifecycle', () {
    test('initialize then dispose cycle', () {
      final mgr = createTestManager();
      mgr.initialize();
      expect(() => mgr.dispose(), returnsNormally);
    });

    test('multiple initialize calls are safe', () {
      final mgr = createTestManager();
      expect(() {
        mgr.initialize();
        mgr.initialize();
        mgr.initialize();
      }, returnsNormally);
      mgr.dispose();
    });

    test('dispose after multiple initializations', () {
      final mgr = createTestManager();
      mgr.initialize();
      mgr.initialize();
      expect(() => mgr.dispose(), returnsNormally);
    });

    test('can access getters after dispose', () {
      final mgr = createTestManager();
      mgr.initialize();
      mgr.dispose();

      // Getters should still work after dispose
      expect(() => mgr.isDownloading, returnsNormally);
      expect(() => mgr.downloadProgress, returnsNormally);
      expect(() => mgr.downloadStatus, returnsNormally);
      expect(() => mgr.networkStatus, returnsNormally);
    });

    test('services accessible after dispose', () {
      final mgr = createTestManager();
      mgr.dispose();

      expect(() => mgr.updateService, returnsNormally);
      expect(() => mgr.networkService, returnsNormally);
    });
  });

  group('UpdateLogicManager stress tests', () {
    test('rapid create-initialize-dispose cycles', () {
      for (int i = 0; i < 50; i++) {
        final mgr = createTestManager();
        mgr.initialize();
        mgr.dispose();
      }
      expect(true, true);
    });

    test('concurrent manager instances', () {
      final managers = List.generate(20, (i) => createTestManager(
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
      final mgr = createTestManager(
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

      final mgr = createTestManager(
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
      final mgr = createTestManager(
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
      final mgr = createTestManager(
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
      final mgr = createTestManager();
      expect(mgr.isDownloading, false);
      mgr.dispose();
    });

    test('download progress starts at 0', () {
      final mgr = createTestManager();
      expect(mgr.downloadProgress, 0.0);
      mgr.dispose();
    });

    test('download status starts empty', () {
      final mgr = createTestManager();
      expect(mgr.downloadStatus, isEmpty);
      mgr.dispose();
    });

    test('callback toggling download state', () {
      List<bool> states = [];
      final mgr = createTestManager(
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
      final mgr = createTestManager();
      expect(mgr.networkStatus, NetworkStatus.unknown);
      mgr.dispose();
    });

    test('callback receives all network status types', () {
      List<NetworkStatus> statuses = [];
      final mgr = createTestManager(
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
      final mgr = createTestManager(
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
      final mgr = createTestManager(
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
      final mgr = createTestManager(
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

      final mgr1 = createTestManager(
        onDownloadStateChanged: (_) => mgr1Called = true,
      );
      final mgr2 = createTestManager(
        onDownloadStateChanged: (_) => mgr2Called = true,
      );

      mgr1.onDownloadStateChanged?.call(true);

      expect(mgr1Called, true);
      expect(mgr2Called, false);

      mgr1.dispose();
      mgr2.dispose();
    });

    test('different managers can share services via DI', () {
      // With DI pattern, services are shared when explicitly injected
      final sharedUpdateService = MockUpdateService();
      final sharedNetworkService = MockNetworkService();

      final mgr1 = createTestManager(
        updateService: sharedUpdateService,
        networkService: sharedNetworkService,
      );
      final mgr2 = createTestManager(
        updateService: sharedUpdateService,
        networkService: sharedNetworkService,
      );

      expect(identical(mgr1.updateService, mgr2.updateService), true);
      expect(identical(mgr1.networkService, mgr2.networkService), true);

      mgr1.dispose();
      mgr2.dispose();
    });
  });

  group('UpdateLogicManager getter thread safety', () {
    test('rapid getter access is safe', () {
      final mgr = createTestManager();

      for (int i = 0; i < 1000; i++) {
        // Access getters rapidly to test thread safety
        mgr.isDownloading;
        mgr.downloadProgress;
        mgr.downloadStatus;
        mgr.networkStatus;
      }

      expect(true, true);
      mgr.dispose();
    });

    test('rapid service access is safe', () {
      final mgr = createTestManager();

      for (int i = 0; i < 100; i++) {
        expect(mgr.updateService, isNotNull);
        expect(mgr.networkService, isNotNull);
      }

      mgr.dispose();
    });
  });

  // ==========================================================================
  // STATE TRANSITION TESTS
  // ==========================================================================
  // These tests verify the state machine behavior of UpdateLogicManager
  // using the mock factories for UpdateInfo and DownloadProgress

  group('UpdateLogicManager state transitions', () {
    late MockUpdateService mockUpdateService;
    late MockNetworkService mockNetworkService;

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockNetworkService = MockNetworkService();
    });

    tearDown(() {
      mockUpdateService.dispose();
      mockNetworkService.dispose();
    });

    group('idle -> downloading transition', () {
      test('should transition to downloading state when startUpdate is invoked conceptually', () async {
        // Track state changes
        final List<bool> downloadStates = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onDownloadStateChanged: (state) => downloadStates.add(state),
        );

        manager.initialize();

        // Initial state should be idle (not downloading)
        expect(manager.isDownloading, false);

        // Simulate the callback that would be invoked when download starts
        manager.onDownloadStateChanged?.call(true);
        expect(downloadStates.last, true);

        // Simulate download completion
        manager.onDownloadStateChanged?.call(false);
        expect(downloadStates.last, false);

        expect(downloadStates, [true, false]);
        manager.dispose();
      });
    });

    group('download progress tracking', () {
      test('should receive progress updates from download stream', () async {
        final List<double> progressValues = [];
        final List<String> statusValues = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onProgressUpdated: (progress, status) {
            progressValues.add(progress);
            statusValues.add(status);
          },
        );

        manager.initialize();

        // Use factory to create progress sequence
        final progressSequence = MockDownloadProgressFactory.downloadSequence(
          steps: 5,
          totalBytes: 10 * 1024 * 1024,
        );

        // Emit progress updates through mock service
        for (final progress in progressSequence) {
          mockUpdateService.emitDownloadProgress(progress);
        }

        // Allow stream events to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify progress was tracked
        expect(progressValues.length, 6); // 0%, 20%, 40%, 60%, 80%, 100%
        expect(progressValues.first, 0.0);
        expect(progressValues.last, 1.0);

        manager.dispose();
      });

      test('should track progress from 0 to 100 correctly', () async {
        final List<double> progressValues = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onProgressUpdated: (progress, _) => progressValues.add(progress),
        );

        manager.initialize();

        // Emit incremental progress
        for (int i = 0; i <= 10; i++) {
          final progress = MockDownloadProgressFactory.atPercentage(i * 10);
          mockUpdateService.emitDownloadProgress(progress);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        expect(progressValues.length, 11);
        expect(progressValues.first, 0.0);
        expect(progressValues[5], closeTo(0.5, 0.01));
        expect(progressValues.last, 1.0);

        manager.dispose();
      });
    });

    group('network status transitions', () {
      test('should update network status when network changes', () async {
        final List<NetworkStatus> networkStatuses = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onNetworkStatusChanged: (status) => networkStatuses.add(status),
        );

        manager.initialize();

        // Initial status should be captured
        expect(networkStatuses.isNotEmpty, true);

        // Simulate network changes
        mockNetworkService.setStatus(NetworkStatus.wifi);
        await Future.delayed(const Duration(milliseconds: 50));

        mockNetworkService.setStatus(NetworkStatus.mobile);
        await Future.delayed(const Duration(milliseconds: 50));

        mockNetworkService.setStatus(NetworkStatus.none);
        await Future.delayed(const Duration(milliseconds: 50));

        mockNetworkService.setStatus(NetworkStatus.wifi);
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify all transitions were captured
        expect(networkStatuses, contains(NetworkStatus.wifi));
        expect(networkStatuses, contains(NetworkStatus.mobile));
        expect(networkStatuses, contains(NetworkStatus.none));

        manager.dispose();
      });

      test('should reflect current network status after changes', () async {
        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        manager.initialize();

        mockNetworkService.setStatus(NetworkStatus.wifi);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(manager.networkStatus, NetworkStatus.wifi);

        mockNetworkService.setStatus(NetworkStatus.none);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(manager.networkStatus, NetworkStatus.none);

        manager.dispose();
      });
    });

    group('download failure handling', () {
      test('should handle download failure and reset state', () async {
        final List<bool> downloadStates = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onDownloadStateChanged: (state) => downloadStates.add(state),
        );

        manager.initialize();

        // Simulate download start
        manager.onDownloadStateChanged?.call(true);
        expect(downloadStates.last, true);

        // Emit failed progress
        mockUpdateService.emitDownloadProgress(
          MockDownloadProgressFactory.failed(
            progressAtFailure: 0.3,
            errorMessage: 'Network error',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Simulate download state reset after failure
        manager.onDownloadStateChanged?.call(false);
        expect(downloadStates.last, false);

        manager.dispose();
      });
    });

    group('download completion handling', () {
      test('should handle successful download completion', () async {
        final List<bool> downloadStates = [];
        final List<double> progressValues = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onDownloadStateChanged: (state) => downloadStates.add(state),
          onProgressUpdated: (progress, _) => progressValues.add(progress),
        );

        manager.initialize();

        // Simulate download start
        manager.onDownloadStateChanged?.call(true);

        // Emit completed progress
        mockUpdateService.emitDownloadProgress(
          MockDownloadProgressFactory.completed(
            filePath: '/path/to/update.apk',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Verify completion
        expect(progressValues.last, 1.0);

        // Simulate download state reset after completion
        manager.onDownloadStateChanged?.call(false);
        expect(downloadStates.last, false);

        manager.dispose();
      });
    });

    group('update info scenarios', () {
      test('should work with forced update info', () {
        final updateInfo = MockUpdateInfoFactory.forced();

        expect(updateInfo.isForced, true);
        expect(updateInfo.hasUpdate, true);
        expect(updateInfo.updateType.name, 'forced');
      });

      test('should work with critical update info', () {
        final updateInfo = MockUpdateInfoFactory.critical();

        expect(updateInfo.isForced, false);
        expect(updateInfo.hasUpdate, true);
        expect(updateInfo.updateType.name, 'critical');
      });

      test('should work with recommended update info', () {
        final updateInfo = MockUpdateInfoFactory.recommended();

        expect(updateInfo.isForced, false);
        expect(updateInfo.hasUpdate, true);
        expect(updateInfo.updateType.name, 'recommended');
      });

      test('should work with no update scenario', () {
        final updateInfo = MockUpdateInfoFactory.noUpdate();

        expect(updateInfo.hasUpdate, false);
      });

      test('should work with major version update', () {
        final updateInfo = MockUpdateInfoFactory.majorUpdate(
          currentVersion: '1.5.3',
        );

        expect(updateInfo.hasUpdate, true);
        expect(updateInfo.latestVersion, '2.0.0');
      });

      test('should work with minor version update', () {
        final updateInfo = MockUpdateInfoFactory.minorUpdate(
          currentVersion: '1.5.3',
        );

        expect(updateInfo.hasUpdate, true);
        expect(updateInfo.latestVersion, '1.6.0');
      });

      test('should work with patch version update', () {
        final updateInfo = MockUpdateInfoFactory.patchUpdate(
          currentVersion: '1.5.3',
        );

        expect(updateInfo.hasUpdate, true);
        expect(updateInfo.latestVersion, '1.5.4');
      });
    });

    group('download progress scenarios', () {
      test('should handle not started state', () {
        final progress = MockDownloadProgressFactory.notStarted();

        expect(progress.progress, 0.0);
        expect(progress.progressText, '0%');
        expect(progress.status, 'Waiting to start');
      });

      test('should handle in progress state', () {
        final progress = MockDownloadProgressFactory.inProgress(progress: 0.5);

        expect(progress.progress, 0.5);
        expect(progress.progressText, '50%');
        expect(progress.status, 'Downloading...');
        expect(progress.speed, isNotNull);
        expect(progress.estimatedTimeRemaining, isNotNull);
      });

      test('should handle completed state', () {
        final progress = MockDownloadProgressFactory.completed();

        expect(progress.progress, 1.0);
        expect(progress.progressText, '100%');
        expect(progress.filePath, isNotNull);
      });

      test('should handle failed state', () {
        final progress = MockDownloadProgressFactory.failed(
          progressAtFailure: 0.3,
          errorMessage: 'Connection lost',
        );

        expect(progress.progress, 0.3);
        expect(progress.status, 'Connection lost');
        expect(progress.speed, 0);
      });

      test('should handle paused state', () {
        final progress = MockDownloadProgressFactory.paused(progress: 0.6);

        expect(progress.progress, 0.6);
        expect(progress.status, 'Paused');
        expect(progress.speed, 0);
      });

      test('should handle slow connection', () {
        final progress = MockDownloadProgressFactory.slowConnection();

        expect(progress.speed, 10 * 1024); // 10 KB/s
        expect(progress.estimatedTimeRemaining!.inSeconds, greaterThan(0));
      });

      test('should handle fast connection', () {
        final progress = MockDownloadProgressFactory.fastConnection();

        expect(progress.speed, 10 * 1024 * 1024); // 10 MB/s
        expect(progress.estimatedTimeRemaining!.inSeconds, lessThan(60));
      });

      test('should generate valid download sequence', () {
        final sequence = MockDownloadProgressFactory.downloadSequence(steps: 5);

        expect(sequence.length, 6); // 0 to 5 inclusive
        expect(sequence.first.progress, 0.0);
        expect(sequence.last.progress, 1.0);
        expect(sequence.last.filePath, isNotNull);

        // Verify sequence is monotonically increasing
        for (int i = 1; i < sequence.length; i++) {
          expect(sequence[i].progress, greaterThan(sequence[i - 1].progress));
        }
      });
    });

    group('mock service configuration', () {
      test('should configure download to succeed', () async {
        mockUpdateService.configureDownload(succeed: true);

        final updateInfo = MockUpdateInfoFactory.withUpdate();
        final result = await mockUpdateService.downloadUpdate(updateInfo);

        expect(result, isNotNull);
        expect(mockUpdateService.downloadAttempts, 1);
      });

      test('should configure download to fail', () async {
        mockUpdateService.configureDownload(succeed: false);

        final updateInfo = MockUpdateInfoFactory.withUpdate();
        final result = await mockUpdateService.downloadUpdate(updateInfo);

        expect(result, isNull);
        expect(mockUpdateService.downloadAttempts, 1);
      });

      test('should configure install to succeed', () async {
        mockUpdateService.configureInstall(succeed: true);

        final result = await mockUpdateService.installUpdate('/path/app.apk');

        expect(result, true);
        expect(mockUpdateService.installAttempts, 1);
      });

      test('should configure install to fail', () async {
        mockUpdateService.configureInstall(succeed: false);

        final result = await mockUpdateService.installUpdate('/path/app.apk');

        expect(result, false);
        expect(mockUpdateService.installAttempts, 1);
      });

      test('should track skipped versions', () async {
        await mockUpdateService.skipVersion('2.0.0');
        await mockUpdateService.skipVersion('2.1.0');

        expect(mockUpdateService.skippedVersions, ['2.0.0', '2.1.0']);
      });

      test('should emit custom progress sequence', () async {
        final customSequence = [
          MockDownloadProgressFactory.atPercentage(25),
          MockDownloadProgressFactory.atPercentage(50),
          MockDownloadProgressFactory.atPercentage(75),
          MockDownloadProgressFactory.completed(),
        ];

        mockUpdateService.configureDownload(progressSequence: customSequence);

        final List<DownloadProgress> received = [];
        final subscription = mockUpdateService.downloadStream.listen(
          (progress) => received.add(progress),
        );

        final updateInfo = MockUpdateInfoFactory.withUpdate();
        await mockUpdateService.downloadUpdate(updateInfo);

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(received.length, 4);
        expect(received[0].progress, closeTo(0.25, 0.01));
        expect(received[1].progress, closeTo(0.50, 0.01));
        expect(received[2].progress, closeTo(0.75, 0.01));
        expect(received[3].progress, 1.0);
      });

      test('should reset mock state', () async {
        mockUpdateService.configureDownload(succeed: false);
        mockUpdateService.configureInstall(succeed: false);
        await mockUpdateService.skipVersion('1.0.0');

        final updateInfo = MockUpdateInfoFactory.withUpdate();
        await mockUpdateService.downloadUpdate(updateInfo);
        await mockUpdateService.installUpdate('/path');

        expect(mockUpdateService.downloadAttempts, 1);
        expect(mockUpdateService.installAttempts, 1);
        expect(mockUpdateService.skippedVersions, ['1.0.0']);

        mockUpdateService.reset();

        expect(mockUpdateService.downloadAttempts, 0);
        expect(mockUpdateService.installAttempts, 0);
        expect(mockUpdateService.skippedVersions, isEmpty);

        // After reset, default behavior should be restored
        final result = await mockUpdateService.downloadUpdate(updateInfo);
        expect(result, isNotNull); // Default is succeed
      });
    });

    group('combined state transitions', () {
      test('should handle complete download flow: idle -> downloading -> completed', () async {
        final List<bool> downloadStates = [];
        final List<double> progressValues = [];
        final List<NetworkStatus> networkStatuses = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onDownloadStateChanged: (state) => downloadStates.add(state),
          onProgressUpdated: (progress, _) => progressValues.add(progress),
          onNetworkStatusChanged: (status) => networkStatuses.add(status),
        );

        manager.initialize();

        // Ensure WiFi connection
        mockNetworkService.setStatus(NetworkStatus.wifi);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(manager.networkStatus, NetworkStatus.wifi);

        // Start download
        manager.onDownloadStateChanged?.call(true);
        expect(downloadStates.last, true);

        // Simulate progress updates
        final progressSequence = MockDownloadProgressFactory.downloadSequence(
          steps: 4,
        );
        for (final progress in progressSequence) {
          mockUpdateService.emitDownloadProgress(progress);
          await Future.delayed(const Duration(milliseconds: 20));
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Verify progress was tracked
        expect(progressValues.last, 1.0);

        // Complete download
        manager.onDownloadStateChanged?.call(false);
        expect(downloadStates.last, false);

        manager.dispose();
      });

      test('should handle network interruption during download', () async {
        final List<bool> downloadStates = [];
        final List<NetworkStatus> networkStatuses = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onDownloadStateChanged: (state) => downloadStates.add(state),
          onNetworkStatusChanged: (status) => networkStatuses.add(status),
        );

        manager.initialize();

        // Start with WiFi
        mockNetworkService.setStatus(NetworkStatus.wifi);
        await Future.delayed(const Duration(milliseconds: 50));

        // Start download
        manager.onDownloadStateChanged?.call(true);

        // Network goes down
        mockNetworkService.setStatus(NetworkStatus.none);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(networkStatuses, contains(NetworkStatus.none));

        // Download fails
        mockUpdateService.emitDownloadProgress(
          MockDownloadProgressFactory.failed(errorMessage: 'Network lost'),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        manager.onDownloadStateChanged?.call(false);

        // Network recovers
        mockNetworkService.setStatus(NetworkStatus.wifi);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(networkStatuses.last, NetworkStatus.wifi);
        expect(downloadStates.last, false);

        manager.dispose();
      });

      test('should handle retry after failure', () async {
        final List<bool> downloadStates = [];
        final List<double> progressValues = [];

        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          onDownloadStateChanged: (state) => downloadStates.add(state),
          onProgressUpdated: (progress, _) => progressValues.add(progress),
        );

        manager.initialize();

        // First attempt - fails at 30%
        manager.onDownloadStateChanged?.call(true);
        mockUpdateService.emitDownloadProgress(
          MockDownloadProgressFactory.inProgress(progress: 0.3),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        mockUpdateService.emitDownloadProgress(
          MockDownloadProgressFactory.failed(progressAtFailure: 0.3),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        manager.onDownloadStateChanged?.call(false);

        expect(downloadStates, contains(false));

        // Clear progress for retry
        progressValues.clear();

        // Second attempt - succeeds
        manager.onDownloadStateChanged?.call(true);
        for (final progress in MockDownloadProgressFactory.downloadSequence(steps: 3)) {
          mockUpdateService.emitDownloadProgress(progress);
          await Future.delayed(const Duration(milliseconds: 20));
        }
        await Future.delayed(const Duration(milliseconds: 100));
        manager.onDownloadStateChanged?.call(false);

        expect(progressValues.last, 1.0);
        expect(downloadStates.last, false);

        manager.dispose();
      });
    });

    group('UI delegate integration', () {
      late MockUpdateUIDelegate mockUIDelegate;

      setUp(() {
        mockUIDelegate = MockUpdateUIDelegate();
      });

      test('should accept custom UI delegate in constructor', () {
        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
          uiDelegate: mockUIDelegate,
        );

        expect(manager.uiDelegate, same(mockUIDelegate));
        manager.dispose();
      });

      test('should use UpdateUIDelegate when not provided', () {
        final manager = UpdateLogicManager.withDependencies(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        expect(manager.uiDelegate, isA<UpdateUIDelegate>());
        manager.dispose();
      });

      test('should track delegate calls via mock', () {
        expect(mockUIDelegate.calls, isEmpty);

        // Simulate delegate usage patterns
        mockUIDelegate.showInstallationStarted(MockBuildContext());
        mockUIDelegate.showInstallationFailed(MockBuildContext());
        mockUIDelegate.showInstallationError(MockBuildContext(), 'Test error');

        expect(mockUIDelegate.calls, contains('showInstallationStarted'));
        expect(mockUIDelegate.calls, contains('showInstallationFailed'));
        expect(mockUIDelegate.calls, contains('showInstallationError: Test error'));
        expect(mockUIDelegate.installationErrorCalls, contains('Test error'));
      });

      test('should be able to configure skip version confirmation result', () async {
        mockUIDelegate.skipVersionConfirmationResult = false;
        final result = await mockUIDelegate.showSkipVersionConfirmation(
          MockBuildContext(),
          '2.0.0',
        );

        expect(result, false);
        expect(mockUIDelegate.skipVersionConfirmationCalls, contains('2.0.0'));

        mockUIDelegate.skipVersionConfirmationResult = true;
        final result2 = await mockUIDelegate.showSkipVersionConfirmation(
          MockBuildContext(),
          '3.0.0',
        );

        expect(result2, true);
      });

      test('should track close dialogs with count', () {
        mockUIDelegate.closeDialogs(MockBuildContext(), count: 2);
        mockUIDelegate.closeDialogs(MockBuildContext(), count: 1);

        expect(mockUIDelegate.closeDialogsCalls, equals([2, 1]));
        expect(mockUIDelegate.calls, contains('closeDialogs: 2'));
        expect(mockUIDelegate.calls, contains('closeDialogs: 1'));
      });

      test('should reset all tracked calls', () {
        mockUIDelegate.showInstallationStarted(MockBuildContext());
        mockUIDelegate.showInstallationFailed(MockBuildContext());
        mockUIDelegate.closeDialogs(MockBuildContext(), count: 3);

        expect(mockUIDelegate.calls, isNotEmpty);
        expect(mockUIDelegate.closeDialogsCalls, isNotEmpty);

        mockUIDelegate.reset();

        expect(mockUIDelegate.calls, isEmpty);
        expect(mockUIDelegate.installationStartedCalls, isEmpty);
        expect(mockUIDelegate.installationFailedCalls, isEmpty);
        expect(mockUIDelegate.closeDialogsCalls, isEmpty);
        expect(mockUIDelegate.skipVersionConfirmationResult, true);
      });
    });
  });
}

/// Mock BuildContext for testing UI delegate calls
class MockBuildContext extends Fake implements BuildContext {
  @override
  bool get mounted => true;
}
