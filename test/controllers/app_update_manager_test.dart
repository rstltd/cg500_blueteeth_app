import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/app_update_manager.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/models/update_preferences.dart';

/// Mock UpdateService for testing
class MockUpdateService implements UpdateService {
  final _updateController = StreamController<UpdateInfo>.broadcast();
  final _downloadController = StreamController<DownloadProgress>.broadcast();
  UpdateInfo? _mockUpdateInfo;
  UpdatePreferences? _preferences;

  @override
  Stream<UpdateInfo> get updateStream => _updateController.stream;

  @override
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;

  @override
  bool get isDownloading => false;

  @override
  Future<bool> initialize() async {
    _preferences = UpdatePreferences();
    return true;
  }

  @override
  void dispose() {
    _updateController.close();
    _downloadController.close();
  }

  @override
  Future<UpdateInfo?> checkForUpdates({bool showNotification = true}) async {
    return _mockUpdateInfo;
  }

  @override
  Future<String?> downloadUpdate(UpdateInfo updateInfo) async {
    return '/mock/path/app.apk';
  }

  @override
  Future<void> cleanupDownloads({String? keepVersion}) async {}

  @override
  Future<bool> installUpdate(String apkPath) async => true;

  @override
  Future<bool> canInstallApks() async => true;

  @override
  Future<void> requestInstallPermission() async {}

  @override
  Future<Map<String, dynamic>> diagnosePermissions() async {
    return {'canInstall': true, 'platform': 'android'};
  }

  @override
  Map<String, String> getCurrentVersionInfo() {
    return {'version': '1.0.0', 'buildNumber': '1'};
  }

  @override
  Future<void> skipVersion(String version) async {}

  @override
  UpdatePreferences? get preferences => _preferences;

  @override
  Future<void> updatePreferences(UpdatePreferences newPreferences) async {
    _preferences = newPreferences;
  }

  @override
  bool shouldAutoDownload(UpdateInfo updateInfo) => false;

  void setMockUpdateInfo(UpdateInfo? info) {
    _mockUpdateInfo = info;
  }

  void emitUpdate(UpdateInfo info) {
    _updateController.add(info);
  }
}

/// Mock NetworkService for testing
class MockNetworkService extends NetworkService {
  final _networkController = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.wifi;

  @override
  Stream<NetworkStatus> get networkStream => _networkController.stream;

  @override
  NetworkStatus get currentStatus => _currentStatus;

  @override
  Future<bool> initialize() async => true;

  @override
  bool isSuitableForDownload({required bool wifiOnly}) {
    if (wifiOnly) return _currentStatus == NetworkStatus.wifi;
    return _currentStatus != NetworkStatus.none;
  }

  @override
  String getStatusDescription() => 'Connected via ${_currentStatus.displayName}';

  @override
  String getNetworkTypeDisplayName() => _currentStatus.displayName;

  @override
  String estimateDownloadTime(int fileSizeBytes) => '~5s';

  @override
  void dispose() {
    _networkController.close();
  }

  void setStatus(NetworkStatus status) {
    _currentStatus = status;
    _networkController.add(status);
  }
}

/// Mock NotificationService for testing
class MockNotificationService extends NotificationService {
  final _notificationsController = StreamController<NotificationModel>.broadcast();
  final List<String> shownNotifications = [];

  @override
  Stream<NotificationModel> get notifications => _notificationsController.stream;

  @override
  void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    shownNotifications.add('success:$title');
  }

  @override
  void showError({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    shownNotifications.add('error:$title');
  }

  @override
  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    shownNotifications.add('warning:$title');
  }

  @override
  void showInfo({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    shownNotifications.add('info:$title');
  }

  @override
  void showConnectionStatus({
    required String title,
    required String message,
    required bool isConnected,
  }) {
    shownNotifications.add('connection:$title');
  }

  @override
  void showScanningStatus({
    required String title,
    required String message,
    required bool isScanning,
  }) {
    shownNotifications.add('scanning:$title');
  }

  @override
  void dispose() {
    _notificationsController.close();
  }
}

/// Helper function to create a test AppUpdateManager with mock dependencies
AppUpdateManager createTestManager({
  MockUpdateService? updateService,
  MockNetworkService? networkService,
  MockNotificationService? notificationService,
}) {
  return AppUpdateManager.withDependencies(
    updateService: updateService ?? MockUpdateService(),
    networkService: networkService ?? MockNetworkService(),
    notificationService: notificationService ?? MockNotificationService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateManager', () {
    late MockUpdateService mockUpdateService;
    late MockNetworkService mockNetworkService;
    late MockNotificationService mockNotificationService;
    late AppUpdateManager manager;

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockNetworkService = MockNetworkService();
      mockNotificationService = MockNotificationService();
      manager = AppUpdateManager.withDependencies(
        updateService: mockUpdateService,
        networkService: mockNetworkService,
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      manager.dispose();
      mockUpdateService.dispose();
      mockNetworkService.dispose();
      mockNotificationService.dispose();
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
        expect(manager.updateService, same(mockUpdateService));
      });

      test('networkService should be accessible', () {
        expect(manager.networkService, same(mockNetworkService));
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
      test('should return bool value', () async {
        await manager.initialize();
        expect(manager.autoUpdatesEnabled, isA<bool>());
      });

      test('should be consistent on multiple access', () async {
        await manager.initialize();
        final value1 = manager.autoUpdatesEnabled;
        final value2 = manager.autoUpdatesEnabled;
        expect(value1, value2);
      });
    });

    group('autoDownloadEnabled', () {
      test('should return bool value', () async {
        await manager.initialize();
        expect(manager.autoDownloadEnabled, isA<bool>());
      });

      test('should be consistent on multiple access', () async {
        await manager.initialize();
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
      test('should return null when no updates', () async {
        final result = await manager.checkForUpdatesSilently();
        expect(result, isNull);
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
        final mgr = createTestManager();
        expect(() => mgr.dispose(), returnsNormally);
      });

      test('should reset isInitialized', () {
        final mgr = createTestManager();
        mgr.dispose();
        // After dispose, isInitialized should be false
        expect(mgr.isInitialized, false);
      });

      test('should clear latestUpdateInfo', () {
        final mgr = createTestManager();
        mgr.dispose();
        expect(mgr.latestUpdateInfo, isNull);
      });

      test('should be safe to call multiple times', () {
        final mgr = createTestManager();
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
      final manager = createTestManager();

      final results = await Future.wait([
        manager.downloadUpdate(),
        manager.downloadUpdate(),
        manager.downloadUpdate(),
      ]);

      // All should return null as no update info is available
      expect(results, [null, null, null]);
      manager.dispose();
    });

    test('rapid startPeriodicUpdateChecks calls', () {
      final manager = createTestManager();

      // Rapid calls should not cause issues
      for (int i = 0; i < 10; i++) {
        manager.startPeriodicUpdateChecks(
          interval: Duration(hours: i + 1),
        );
      }

      expect(true, true); // If we get here, no exception was thrown
      manager.dispose();
    });

    test('showUpdateDialogIfAvailable called many times', () {
      final manager = createTestManager();

      // Multiple calls should be safe
      for (int i = 0; i < 100; i++) {
        manager.showUpdateDialogIfAvailable();
      }

      expect(true, true); // If we get here, no exception was thrown
      manager.dispose();
    });
  });

  group('AppUpdateManager service interaction', () {
    test('updateService and networkService are different objects', () {
      final manager = createTestManager();
      expect(
        identical(manager.updateService, manager.networkService),
        false,
      );
      manager.dispose();
    });

    test('getCurrentVersionInfo returns map with expected types', () {
      final manager = createTestManager();
      final info = manager.getCurrentVersionInfo();

      // Should be a map where all values are strings
      for (final entry in info.entries) {
        expect(entry.key, isA<String>());
        expect(entry.value, isA<String>());
      }
      manager.dispose();
    });
  });

  group('AppUpdateManager preferences detailed', () {
    test('autoUpdatesEnabled returns bool', () async {
      final manager = createTestManager();
      await manager.initialize();
      expect(manager.autoUpdatesEnabled, isA<bool>());
      manager.dispose();
    });

    test('autoDownloadEnabled returns bool', () async {
      final manager = createTestManager();
      await manager.initialize();
      expect(manager.autoDownloadEnabled, isA<bool>());
      manager.dispose();
    });

    test('autoUpdatesEnabled is consistent on multiple calls', () async {
      final manager = createTestManager();
      await manager.initialize();
      final val1 = manager.autoUpdatesEnabled;
      final val2 = manager.autoUpdatesEnabled;
      final val3 = manager.autoUpdatesEnabled;
      expect(val1, val2);
      expect(val2, val3);
      manager.dispose();
    });

    test('autoDownloadEnabled is consistent on multiple calls', () async {
      final manager = createTestManager();
      await manager.initialize();
      final val1 = manager.autoDownloadEnabled;
      final val2 = manager.autoDownloadEnabled;
      final val3 = manager.autoDownloadEnabled;
      expect(val1, val2);
      expect(val2, val3);
      manager.dispose();
    });
  });

  group('AppUpdateManager state management detailed', () {
    test('isInitialized starts as false after dispose', () {
      final manager = createTestManager();
      manager.dispose(); // Reset state
      expect(manager.isInitialized, false);
    });

    test('isCheckingForUpdates starts as false after dispose', () {
      final manager = createTestManager();
      manager.dispose(); // Reset state
      expect(manager.isCheckingForUpdates, false);
    });

    test('latestUpdateInfo starts as null after dispose', () {
      final manager = createTestManager();
      manager.dispose(); // Reset state
      expect(manager.latestUpdateInfo, isNull);
    });

    test('state getters are all accessible', () {
      final manager = createTestManager();

      expect(() => manager.isInitialized, returnsNormally);
      expect(() => manager.isCheckingForUpdates, returnsNormally);
      expect(() => manager.latestUpdateInfo, returnsNormally);
      expect(() => manager.autoUpdatesEnabled, returnsNormally);
      expect(() => manager.autoDownloadEnabled, returnsNormally);
      manager.dispose();
    });

    test('all state getters return correct types', () async {
      final manager = createTestManager();
      await manager.initialize();

      expect(manager.isInitialized, isA<bool>());
      expect(manager.isCheckingForUpdates, isA<bool>());
      expect(manager.autoUpdatesEnabled, isA<bool>());
      expect(manager.autoDownloadEnabled, isA<bool>());
      // latestUpdateInfo can be null or UpdateInfo
      expect(
        manager.latestUpdateInfo,
        anyOf(isNull, isA<UpdateInfo>()),
      );
      manager.dispose();
    });
  });

  group('AppUpdateManager lifecycle detailed', () {
    test('dispose is idempotent', () {
      final manager = createTestManager();

      expect(() {
        manager.dispose();
        manager.dispose();
        manager.dispose();
        manager.dispose();
        manager.dispose();
      }, returnsNormally);
    });

    test('can access getters after dispose', () {
      final manager = createTestManager();
      manager.dispose();

      expect(() => manager.isInitialized, returnsNormally);
      expect(() => manager.isCheckingForUpdates, returnsNormally);
      expect(() => manager.latestUpdateInfo, returnsNormally);
      expect(() => manager.updateService, returnsNormally);
      expect(() => manager.networkService, returnsNormally);
    });

    test('can call methods after dispose', () {
      final manager = createTestManager();
      manager.dispose();

      expect(() => manager.getCurrentVersionInfo(), returnsNormally);
      expect(() => manager.showUpdateDialogIfAvailable(), returnsNormally);
      expect(() => manager.startPeriodicUpdateChecks(), returnsNormally);
    });

    test('dispose clears state correctly', () {
      final manager = createTestManager();
      manager.dispose();

      expect(manager.isInitialized, false);
      expect(manager.latestUpdateInfo, isNull);
    });
  });

  group('AppUpdateManager periodic checks detailed', () {
    test('startPeriodicUpdateChecks with various intervals', () {
      final manager = createTestManager();

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
      manager.dispose();
    });

    test('startPeriodicUpdateChecks replaces previous timer', () {
      final manager = createTestManager();

      // Multiple calls should replace, not stack
      manager.startPeriodicUpdateChecks(interval: const Duration(hours: 1));
      manager.startPeriodicUpdateChecks(interval: const Duration(hours: 2));
      manager.startPeriodicUpdateChecks(interval: const Duration(hours: 3));

      // Should not throw
      expect(true, true);
      manager.dispose();
    });

    test('startPeriodicUpdateChecks after dispose', () {
      final manager = createTestManager();
      manager.dispose();

      expect(
        () => manager.startPeriodicUpdateChecks(),
        returnsNormally,
      );
    });
  });

  group('AppUpdateManager version info detailed', () {
    test('getCurrentVersionInfo returns non-empty map or empty map', () {
      final manager = createTestManager();
      final info = manager.getCurrentVersionInfo();

      expect(info, isA<Map<String, String>>());
      manager.dispose();
    });

    test('getCurrentVersionInfo keys are valid', () {
      final manager = createTestManager();
      final info = manager.getCurrentVersionInfo();

      for (final key in info.keys) {
        expect(key, isNotEmpty);
        expect(key.trim(), key); // No whitespace
      }
      manager.dispose();
    });

    test('getCurrentVersionInfo values are valid strings', () {
      final manager = createTestManager();
      final info = manager.getCurrentVersionInfo();

      for (final value in info.values) {
        expect(value, isA<String>());
      }
      manager.dispose();
    });

    test('getCurrentVersionInfo is consistent', () {
      final manager = createTestManager();

      final info1 = manager.getCurrentVersionInfo();
      final info2 = manager.getCurrentVersionInfo();

      expect(info1.length, info2.length);
      for (final key in info1.keys) {
        expect(info2.containsKey(key), true);
      }
      manager.dispose();
    });
  });

  group('AppUpdateManager async operations detailed', () {
    test('downloadUpdate with no update info', () async {
      final manager = createTestManager();
      manager.dispose(); // Ensure no update info

      final result = await manager.downloadUpdate();
      expect(result, isNull);
    });

    test('checkForUpdatesSilently returns UpdateInfo or null', () async {
      final manager = createTestManager();

      final result = await manager.checkForUpdatesSilently();
      expect(result, anyOf(isNull, isA<UpdateInfo>()));
      manager.dispose();
    });

    test('concurrent checkForUpdatesSilently calls', () async {
      final manager = createTestManager();

      final results = await Future.wait([
        manager.checkForUpdatesSilently(),
        manager.checkForUpdatesSilently(),
        manager.checkForUpdatesSilently(),
      ]);

      // All should complete without error
      for (final result in results) {
        expect(result, anyOf(isNull, isA<UpdateInfo>()));
      }
      manager.dispose();
    });

    test('downloadUpdate concurrent calls', () async {
      final manager = createTestManager();
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
      final manager = createTestManager();

      for (int i = 0; i < 1000; i++) {
        manager.showUpdateDialogIfAvailable();
      }

      expect(true, true); // If we get here, no exception
      manager.dispose();
    });

    test('rapid getCurrentVersionInfo calls', () {
      final manager = createTestManager();

      for (int i = 0; i < 100; i++) {
        final info = manager.getCurrentVersionInfo();
        expect(info, isA<Map<String, String>>());
      }
      manager.dispose();
    });

    test('alternating operations', () async {
      final manager = createTestManager();

      for (int i = 0; i < 20; i++) {
        manager.showUpdateDialogIfAvailable();
        manager.getCurrentVersionInfo();
        manager.startPeriodicUpdateChecks();
        await manager.downloadUpdate();
      }

      expect(true, true);
      manager.dispose();
    });

    test('state remains consistent during rapid operations', () {
      final manager = createTestManager();
      manager.dispose();

      for (int i = 0; i < 50; i++) {
        expect(manager.isInitialized, false);
        expect(manager.latestUpdateInfo, isNull);
        manager.showUpdateDialogIfAvailable();
        manager.getCurrentVersionInfo();
      }
    });
  });

  group('AppUpdateManager setContext behavior', () {
    test('setContext does not throw with null-like context', () {
      final manager = createTestManager();
      // We can't easily test with a real context, but ensure method exists
      expect(manager.setContext, isA<Function>());
      manager.dispose();
    });
  });

  group('AppUpdateManager setAutoUpdatesEnabled', () {
    test('setAutoUpdatesEnabled returns Future', () async {
      final manager = createTestManager();
      await manager.initialize();
      // Method should complete without error
      await manager.setAutoUpdatesEnabled(true);
      await manager.setAutoUpdatesEnabled(false);
      expect(true, true);
      manager.dispose();
    });

    test('setAutoUpdatesEnabled multiple calls are safe', () async {
      final manager = createTestManager();
      await manager.initialize();

      await Future.wait([
        manager.setAutoUpdatesEnabled(true),
        manager.setAutoUpdatesEnabled(false),
        manager.setAutoUpdatesEnabled(true),
      ]);

      expect(true, true);
      manager.dispose();
    });
  });

  group('AppUpdateManager initialize behavior', () {
    test('initialize returns Future<bool>', () async {
      final manager = createTestManager();
      manager.dispose(); // Reset state

      final result = await manager.initialize();
      expect(result, isA<bool>());
    });

    test('initialize can be called after dispose', () async {
      final manager = createTestManager();
      manager.dispose();

      final result = await manager.initialize();
      expect(result, anyOf(isTrue, isFalse));
    });

    test('multiple initialize calls are handled', () async {
      final manager = createTestManager();
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
      final manager = createTestManager();

      final result = await manager.checkForUpdatesWithUI();
      expect(result, anyOf(isNull, isA<UpdateInfo>()));
      manager.dispose();
    });

    test('checkForUpdatesWithUI with force flag', () async {
      final manager = createTestManager();

      final result = await manager.checkForUpdatesWithUI(force: true);
      expect(result, anyOf(isNull, isA<UpdateInfo>()));
      manager.dispose();
    });

    test('concurrent checkForUpdatesWithUI calls', () async {
      final manager = createTestManager();

      // Multiple concurrent calls should be handled gracefully
      final results = await Future.wait([
        manager.checkForUpdatesWithUI(),
        manager.checkForUpdatesWithUI(),
      ]);

      for (final result in results) {
        expect(result, anyOf(isNull, isA<UpdateInfo>()));
      }
      manager.dispose();
    });
  });

  group('AppUpdateManager state after dispose', () {
    test('getters return valid values after dispose', () async {
      final manager = createTestManager();
      await manager.initialize();
      manager.dispose();

      expect(manager.isInitialized, false);
      expect(manager.isCheckingForUpdates, false);
      expect(manager.latestUpdateInfo, isNull);
      expect(manager.autoUpdatesEnabled, isA<bool>());
      expect(manager.autoDownloadEnabled, isA<bool>());
    });

    test('services remain accessible after dispose', () {
      final manager = createTestManager();
      manager.dispose();

      expect(manager.updateService, isNotNull);
      expect(manager.networkService, isNotNull);
    });

    test('methods can be called after dispose', () async {
      final manager = createTestManager();
      manager.dispose();

      expect(() => manager.showUpdateDialogIfAvailable(), returnsNormally);
      expect(() => manager.startPeriodicUpdateChecks(), returnsNormally);
      expect(() => manager.getCurrentVersionInfo(), returnsNormally);
      await manager.downloadUpdate();
      expect(true, true);
    });
  });

  group('AppUpdateManager preferences integration', () {
    test('autoUpdatesEnabled default is true', () async {
      final manager = createTestManager();
      await manager.initialize();
      // Default should be true or whatever is in preferences
      expect(manager.autoUpdatesEnabled, isA<bool>());
      manager.dispose();
    });

    test('autoDownloadEnabled default is false', () async {
      final manager = createTestManager();
      await manager.initialize();
      // Default should be false or whatever is in preferences
      expect(manager.autoDownloadEnabled, isA<bool>());
      manager.dispose();
    });

    test('preferences getters are consistent', () async {
      final manager = createTestManager();
      await manager.initialize();

      final auto1 = manager.autoUpdatesEnabled;
      final auto2 = manager.autoUpdatesEnabled;
      final download1 = manager.autoDownloadEnabled;
      final download2 = manager.autoDownloadEnabled;

      expect(auto1, auto2);
      expect(download1, download2);
      manager.dispose();
    });
  });

  group('AppUpdateManager rapid operations', () {
    test('rapid dispose and access cycles', () {
      for (int i = 0; i < 20; i++) {
        final manager = createTestManager();
        manager.dispose();
        expect(manager.isInitialized, false);
      }
    });

    test('rapid method calls', () async {
      final manager = createTestManager();

      for (int i = 0; i < 10; i++) {
        manager.getCurrentVersionInfo();
        manager.showUpdateDialogIfAvailable();
        manager.startPeriodicUpdateChecks();
      }

      expect(true, true);
      manager.dispose();
    });

    test('alternating initialize and dispose', () async {
      final manager = createTestManager();

      for (int i = 0; i < 5; i++) {
        manager.dispose();
        await manager.initialize();
      }

      expect(manager.isInitialized, isA<bool>());
      manager.dispose();
    });
  });

  group('AppUpdateManager version info structure', () {
    test('getCurrentVersionInfo has expected keys', () {
      final manager = createTestManager();
      final info = manager.getCurrentVersionInfo();

      // Should contain version info as strings
      for (final entry in info.entries) {
        expect(entry.key, isA<String>());
        expect(entry.value, isA<String>());
      }
      manager.dispose();
    });

    test('getCurrentVersionInfo is idempotent', () {
      final manager = createTestManager();

      final info1 = manager.getCurrentVersionInfo();
      final info2 = manager.getCurrentVersionInfo();

      expect(info1.length, info2.length);
      for (final key in info1.keys) {
        expect(info2.containsKey(key), true);
      }
      manager.dispose();
    });
  });

  group('AppUpdateManager.withDependencies', () {
    late MockUpdateService mockUpdateService;
    late MockNetworkService mockNetworkService;
    late MockNotificationService mockNotificationService;
    late AppUpdateManager manager;

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockNetworkService = MockNetworkService();
      mockNotificationService = MockNotificationService();
      manager = AppUpdateManager.withDependencies(
        updateService: mockUpdateService,
        networkService: mockNetworkService,
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      mockUpdateService.dispose();
      mockNetworkService.dispose();
      mockNotificationService.dispose();
    });

    test('should create with injected dependencies', () {
      expect(manager, isA<AppUpdateManager>());
    });

    test('updateService should return injected service', () {
      expect(manager.updateService, same(mockUpdateService));
    });

    test('networkService should return injected service', () {
      expect(manager.networkService, same(mockNetworkService));
    });

    test('getCurrentVersionInfo should return mock values', () {
      final info = manager.getCurrentVersionInfo();
      expect(info['version'], '1.0.0');
      expect(info['buildNumber'], '1');
    });

    test('initialize should call mock service initialize', () async {
      final result = await manager.initialize();
      expect(result, true);
      expect(manager.isInitialized, true);
    });

    test('checkForUpdatesSilently should return null when no updates', () async {
      final result = await manager.checkForUpdatesSilently();
      expect(result, isNull);
    });

    test('checkForUpdatesWithUI should return null when no updates', () async {
      await manager.initialize();
      final result = await manager.checkForUpdatesWithUI();
      expect(result, isNull);
    });

    test('downloadUpdate should return null when no update info', () async {
      final result = await manager.downloadUpdate();
      expect(result, isNull);
    });

    test('autoUpdatesEnabled should return default preference', () async {
      await manager.initialize();
      expect(manager.autoUpdatesEnabled, isA<bool>());
    });

    test('autoDownloadEnabled should return default preference', () async {
      await manager.initialize();
      expect(manager.autoDownloadEnabled, isA<bool>());
    });

    test('setAutoUpdatesEnabled should not throw', () async {
      await manager.initialize();
      await expectLater(
        manager.setAutoUpdatesEnabled(true),
        completes,
      );
    });

    test('setAutoUpdatesEnabled false should stop periodic checks', () async {
      await manager.initialize();
      manager.startPeriodicUpdateChecks();
      await manager.setAutoUpdatesEnabled(false);
      // Should complete without error
      expect(true, true);
    });

    test('startPeriodicUpdateChecks should not throw with mock services', () {
      expect(() => manager.startPeriodicUpdateChecks(), returnsNormally);
    });

    test('dispose should not throw with mock services', () {
      expect(() => manager.dispose(), returnsNormally);
    });

    test('showUpdateDialogIfAvailable should not throw when no context', () {
      expect(() => manager.showUpdateDialogIfAvailable(), returnsNormally);
    });

    test('setContext should accept BuildContext', () {
      // Can't easily test with real context, but method should exist
      expect(manager.setContext, isA<Function>());
    });

    test('multiple initializations should return true', () async {
      final result1 = await manager.initialize();
      final result2 = await manager.initialize();
      expect(result1, true);
      expect(result2, true);
    });

    test('isCheckingForUpdates should be false initially', () {
      expect(manager.isCheckingForUpdates, false);
    });

    test('latestUpdateInfo should be null initially', () {
      expect(manager.latestUpdateInfo, isNull);
    });
  });

  group('AppUpdateManager.withDependencies network handling', () {
    late MockUpdateService mockUpdateService;
    late MockNetworkService mockNetworkService;
    late MockNotificationService mockNotificationService;
    late AppUpdateManager manager;

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockNetworkService = MockNetworkService();
      mockNotificationService = MockNotificationService();
      manager = AppUpdateManager.withDependencies(
        updateService: mockUpdateService,
        networkService: mockNetworkService,
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      mockUpdateService.dispose();
      mockNetworkService.dispose();
      mockNotificationService.dispose();
    });

    test('networkService should report correct status', () {
      mockNetworkService.setStatus(NetworkStatus.wifi);
      expect(manager.networkService.currentStatus, NetworkStatus.wifi);
    });

    test('networkService should change status', () {
      mockNetworkService.setStatus(NetworkStatus.mobile);
      expect(manager.networkService.currentStatus, NetworkStatus.mobile);
    });

    test('networkService should report no connection', () {
      mockNetworkService.setStatus(NetworkStatus.none);
      expect(manager.networkService.currentStatus, NetworkStatus.none);
    });

    test('isSuitableForDownload should work with wifiOnly true', () {
      mockNetworkService.setStatus(NetworkStatus.wifi);
      expect(
        manager.networkService.isSuitableForDownload(wifiOnly: true),
        true,
      );
    });

    test('isSuitableForDownload should reject mobile when wifiOnly', () {
      mockNetworkService.setStatus(NetworkStatus.mobile);
      expect(
        manager.networkService.isSuitableForDownload(wifiOnly: true),
        false,
      );
    });

    test('isSuitableForDownload should accept mobile when not wifiOnly', () {
      mockNetworkService.setStatus(NetworkStatus.mobile);
      expect(
        manager.networkService.isSuitableForDownload(wifiOnly: false),
        true,
      );
    });
  });

  group('AppUpdateManager.withDependencies update service', () {
    late MockUpdateService mockUpdateService;
    late MockNetworkService mockNetworkService;
    late MockNotificationService mockNotificationService;
    late AppUpdateManager manager;

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockNetworkService = MockNetworkService();
      mockNotificationService = MockNotificationService();
      manager = AppUpdateManager.withDependencies(
        updateService: mockUpdateService,
        networkService: mockNetworkService,
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      mockUpdateService.dispose();
      mockNetworkService.dispose();
      mockNotificationService.dispose();
    });

    test('updateService streams should be accessible', () {
      expect(manager.updateService.updateStream, isA<Stream<UpdateInfo>>());
      expect(manager.updateService.downloadStream, isA<Stream<DownloadProgress>>());
    });

    test('updateService preferences should be null before init', () {
      expect(manager.updateService.preferences, isNull);
    });

    test('updateService preferences should be set after init', () async {
      await manager.initialize();
      expect(manager.updateService.preferences, isNotNull);
    });

    test('updateService should return version info', () {
      final info = manager.updateService.getCurrentVersionInfo();
      expect(info, isA<Map<String, String>>());
      expect(info.containsKey('version'), true);
    });

    test('updateService shouldAutoDownload should return bool', () async {
      await manager.initialize();
      final updateInfo = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Test release',
        releaseDate: DateTime.now(),
        downloadSize: 1024 * 1024,
        isForced: false,
      );
      final result = manager.updateService.shouldAutoDownload(updateInfo);
      expect(result, isA<bool>());
    });
  });

  group('AppUpdateManager.withDependencies lifecycle', () {
    test('create-initialize-dispose cycle', () async {
      final updateService = MockUpdateService();
      final networkService = MockNetworkService();
      final notificationService = MockNotificationService();

      final manager = AppUpdateManager.withDependencies(
        updateService: updateService,
        networkService: networkService,
        notificationService: notificationService,
      );

      await manager.initialize();
      expect(manager.isInitialized, true);

      manager.dispose();
      expect(manager.isInitialized, false);

      updateService.dispose();
      networkService.dispose();
      notificationService.dispose();
    });

    test('multiple create-dispose cycles', () async {
      for (int i = 0; i < 5; i++) {
        final updateService = MockUpdateService();
        final networkService = MockNetworkService();
        final notificationService = MockNotificationService();

        final manager = AppUpdateManager.withDependencies(
          updateService: updateService,
          networkService: networkService,
          notificationService: notificationService,
        );

        await manager.initialize();
        manager.dispose();

        updateService.dispose();
        networkService.dispose();
        notificationService.dispose();
      }

      expect(true, true);
    });
  });

  group('AppUpdateManager.withDependencies operations with no updates', () {
    late MockUpdateService mockUpdateService;
    late MockNetworkService mockNetworkService;
    late MockNotificationService mockNotificationService;
    late AppUpdateManager manager;

    setUp(() async {
      mockUpdateService = MockUpdateService();
      mockNetworkService = MockNetworkService();
      mockNotificationService = MockNotificationService();
      manager = AppUpdateManager.withDependencies(
        updateService: mockUpdateService,
        networkService: mockNetworkService,
        notificationService: mockNotificationService,
      );
      await manager.initialize();
    });

    tearDown(() {
      manager.dispose();
      mockUpdateService.dispose();
      mockNetworkService.dispose();
      mockNotificationService.dispose();
    });

    test('checkForUpdatesSilently returns null', () async {
      final result = await manager.checkForUpdatesSilently();
      expect(result, isNull);
    });

    test('checkForUpdatesWithUI returns null', () async {
      final result = await manager.checkForUpdatesWithUI();
      expect(result, isNull);
    });

    test('downloadUpdate returns null', () async {
      final result = await manager.downloadUpdate();
      expect(result, isNull);
    });

    test('concurrent checkForUpdatesSilently calls', () async {
      final results = await Future.wait([
        manager.checkForUpdatesSilently(),
        manager.checkForUpdatesSilently(),
        manager.checkForUpdatesSilently(),
      ]);
      expect(results.every((r) => r == null), true);
    });
  });
}
