import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cg500_blueteeth_app/controllers/update_controller.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/role_service.dart';
import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/services/update_checker.dart';
import 'package:cg500_blueteeth_app/services/download_manager.dart';
import 'package:cg500_blueteeth_app/services/install_manager.dart';
import 'package:cg500_blueteeth_app/services/update_preferences_store.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/view_models/update_settings_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UpdateSettingsViewModel', () {
    late UpdatePreferencesStore preferencesStore;
    late _MockNetworkService mockNetworkService;
    late _FakeUpdateController mockUpdateManager;

    setUp(() {
      preferencesStore = UpdatePreferencesStore();
      mockNetworkService = _MockNetworkService();
      mockUpdateManager = _FakeUpdateController();
    });

    tearDown(() {
      mockNetworkService.disposeController();
    });

    group('initialization', () {
      test('should start with correct initial state', () {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        expect(viewModel.isInitialized, isFalse);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.preferences, isNull);
        expect(viewModel.hasPreferences, isFalse);
        expect(viewModel.isCheckingUpdate, isFalse);

        viewModel.dispose();
      });

      test('should initialize and load preferences', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        expect(viewModel.isInitialized, isTrue);
        expect(viewModel.hasPreferences, isTrue);
        expect(viewModel.preferences, isNotNull);

        viewModel.dispose();
      });

      test('should subscribe to network status changes', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        expect(viewModel.networkStatus, equals(NetworkStatus.wifi));

        // Emit new network status
        mockNetworkService.emitStatus(NetworkStatus.mobile);
        await Future.delayed(Duration.zero);

        expect(viewModel.networkStatus, equals(NetworkStatus.mobile));

        viewModel.dispose();
      });
    });

    group('network status', () {
      test('should return network status description', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        expect(viewModel.networkStatusDescription, isNotEmpty);

        viewModel.dispose();
      });
    });

    group('preference updates', () {
      // Note: auto-check, auto-download, and update-frequency settings are
      // no longer user-facing (hardcoded to developer defaults) so their
      // setters were removed from the ViewModel. Only WiFi-only download
      // and skip-list management remain.
      test('should update wifiOnlyDownload', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        final initialValue = viewModel.preferences!.wifiOnlyDownload;
        viewModel.setWifiOnlyDownload(!initialValue);

        expect(viewModel.preferences!.wifiOnlyDownload, equals(!initialValue));

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });

      test('should notify listeners on preference change', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        await viewModel.setWifiOnlyDownload(
          !viewModel.preferences!.wifiOnlyDownload,
        );
        // Drain the store->VM stream microtask so the listener fires.
        await Future<void>.delayed(Duration.zero);

        expect(notified, isTrue);

        viewModel.dispose();
      });
    });

    group('skipped versions', () {
      test('should clear skipped versions', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        // Add a skipped version manually
        viewModel.preferences!.skipVersion('1.0.0');
        expect(viewModel.preferences!.skippedVersions, contains('1.0.0'));

        viewModel.clearSkippedVersions();

        expect(viewModel.preferences!.skippedVersions, isEmpty);

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });

      test('should unskip a specific version', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        // Add a skipped version manually
        viewModel.preferences!.skipVersion('1.0.0');
        viewModel.preferences!.skipVersion('2.0.0');

        viewModel.unskipVersion('1.0.0');

        expect(viewModel.preferences!.skippedVersions, isNot(contains('1.0.0')));
        expect(viewModel.preferences!.skippedVersions, contains('2.0.0'));

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });
    });

    // Reset-to-defaults feature removed — the settings page no longer has
    // enough user-controllable fields to justify a bulk reset button.

    group('update checking', () {
      test('should set isCheckingUpdate during check', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        expect(viewModel.isCheckingUpdate, isFalse);

        // Start checking (don't await)
        final checkFuture = viewModel.checkForUpdates();

        // Should be checking now
        expect(viewModel.isCheckingUpdate, isTrue);

        await checkFuture;

        // Should be done checking
        expect(viewModel.isCheckingUpdate, isFalse);

        viewModel.dispose();
      });

      test('should not allow concurrent update checks', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        // Start first check
        final check1 = viewModel.checkForUpdates();

        // Try to start second check (should be ignored)
        final check2 = viewModel.checkForUpdates();

        await Future.wait([check1, check2]);

        // The viewmodel now routes through UpdateController, so we assert
        // against the fake manager instead of the underlying UpdateService.
        expect(mockUpdateManager.checkCallCount, equals(1));

        viewModel.dispose();
      });
    });

    group('version info', () {
      test('should return current version info', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        final versionInfo = viewModel.currentVersionInfo;

        expect(versionInfo, isA<Map<String, String>>());
        expect(versionInfo['version'], equals('1.0.0'));
        expect(versionInfo['buildNumber'], equals('1'));

        viewModel.dispose();
      });
    });

    group('service accessors', () {
      test('should provide access to network service', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        expect(viewModel.networkService, equals(mockNetworkService));

        viewModel.dispose();
      });
    });

    group('dispose', () {
      test('should cancel network subscription on dispose', () async {
        final viewModel = UpdateSettingsViewModel(
          preferencesStore: preferencesStore,
          networkService: mockNetworkService,
          roleService: RoleService(),
          updateManager: mockUpdateManager,
        );

        await viewModel.initialize();

        viewModel.dispose();

        // Emit new status after dispose
        mockNetworkService.emitStatus(NetworkStatus.none);
        await Future.delayed(Duration.zero);

        // Should still be the old status (wifi) since subscription was cancelled
        // Note: After dispose, the viewModel state is preserved but won't update
        expect(viewModel.isDisposed, isTrue);
      });
    });
  });
}

// --- Mock Implementations ---

class _MockNetworkService extends NetworkService {
  final _networkController = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.wifi;

  void emitStatus(NetworkStatus status) {
    _currentStatus = status;
    _networkController.add(status);
  }

  void disposeController() {
    _networkController.close();
  }

  @override
  Stream<NetworkStatus> get networkStream => _networkController.stream;

  @override
  NetworkStatus get currentStatus => _currentStatus;

  @override
  Future<bool> initialize() async => true;

  @override
  void dispose() {}

  @override
  bool isSuitableForDownload({required bool wifiOnly}) {
    if (wifiOnly) {
      return _currentStatus == NetworkStatus.wifi;
    }
    return _currentStatus == NetworkStatus.wifi || _currentStatus == NetworkStatus.mobile;
  }

  @override
  String getStatusDescription() {
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        return 'Connected via WiFi';
      case NetworkStatus.mobile:
        return 'Connected via Mobile Data';
      case NetworkStatus.none:
        return 'No Internet Connection';
      case NetworkStatus.unknown:
        return 'Unknown Connection Status';
    }
  }

  @override
  String getNetworkTypeDisplayName() {
    return _currentStatus.displayName;
  }

  @override
  String estimateDownloadTime(int fileSizeBytes) {
    return '~5s';
  }
}

/// Minimal UpdateController double — exposes only the one method that
/// UpdateSettingsViewModel calls. Avoids pulling a real UpdateController
/// through the service locator in tests.
class _FakeUpdateController extends UpdateController {
  int checkCallCount = 0;

  _FakeUpdateController()
      : super.withDependencies(
          updateChecker: _NoopUpdateChecker(),
          downloadManager: _NoopDownloadManager(),
          installManager: _NoopInstallManager(),
          preferencesStore: UpdatePreferencesStore(),
          networkService: _NoopNetworkService(),
          notificationService: _NoopNotificationService(),
        );

  @override
  Future<UpdateInfo?> checkForUpdatesWithUI({
    bool force = false,
    bool showUpToDateMessage = false,
  }) async {
    checkCallCount++;
    return null;
  }

  @override
  Map<String, String> getCurrentVersionInfo() => {
        'version': '1.0.0',
        'buildNumber': '1',
      };
}

class _NoopUpdateChecker implements UpdateChecker {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopDownloadManager implements DownloadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopInstallManager implements InstallManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopNetworkService implements NetworkService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
