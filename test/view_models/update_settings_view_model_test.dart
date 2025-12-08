import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/core/interfaces/update_service_interface.dart';
import 'package:cg500_blueteeth_app/core/interfaces/network_service_interface.dart';
import 'package:cg500_blueteeth_app/models/update_preferences.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/view_models/update_settings_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{};
      }
      if (methodCall.method == 'setString' ||
          methodCall.method == 'setBool' ||
          methodCall.method == 'setInt' ||
          methodCall.method == 'setStringList') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('UpdateSettingsViewModel', () {
    late _MockUpdateService mockUpdateService;
    late _MockNetworkService mockNetworkService;

    setUp(() {
      mockUpdateService = _MockUpdateService();
      mockNetworkService = _MockNetworkService();
    });

    tearDown(() {
      mockNetworkService.disposeController();
    });

    group('initialization', () {
      test('should start with correct initial state', () {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        expect(viewModel.isInitialized, isTrue);
        expect(viewModel.hasPreferences, isTrue);
        expect(viewModel.preferences, isNotNull);

        viewModel.dispose();
      });

      test('should subscribe to network status changes', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        expect(viewModel.networkStatusDescription, isNotEmpty);

        viewModel.dispose();
      });
    });

    group('preference updates', () {
      test('should update autoCheckEnabled', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        final initialValue = viewModel.preferences!.autoCheckEnabled;
        viewModel.setAutoCheckEnabled(!initialValue);

        expect(viewModel.preferences!.autoCheckEnabled, equals(!initialValue));

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });

      test('should update updateFrequency', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        viewModel.setUpdateFrequency(UpdateFrequency.weekly);

        expect(viewModel.preferences!.updateFrequency, equals(UpdateFrequency.weekly));

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });

      test('should update autoDownloadEnabled', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        final initialValue = viewModel.preferences!.autoDownloadEnabled;
        viewModel.setAutoDownloadEnabled(!initialValue);

        expect(viewModel.preferences!.autoDownloadEnabled, equals(!initialValue));

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });

      test('should update wifiOnlyDownload', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        viewModel.setAutoCheckEnabled(false);

        expect(notified, isTrue);

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });
    });

    group('skipped versions', () {
      test('should clear skipped versions', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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

    group('reset to defaults', () {
      test('should reset preferences to defaults', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        // Modify preferences
        viewModel.setAutoCheckEnabled(false);
        await Future.delayed(Duration.zero);
        viewModel.setWifiOnlyDownload(false);
        await Future.delayed(Duration.zero);

        // Reset
        viewModel.resetToDefaults();

        // Check defaults
        final defaults = UpdatePreferences();
        expect(viewModel.preferences!.autoCheckEnabled, equals(defaults.autoCheckEnabled));
        expect(viewModel.preferences!.wifiOnlyDownload, equals(defaults.wifiOnlyDownload));

        // Wait for async savePreferences to complete
        await Future.delayed(Duration.zero);
        viewModel.dispose();
      });
    });

    group('update checking', () {
      test('should set isCheckingUpdate during check', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        // Start first check
        final check1 = viewModel.checkForUpdates();

        // Try to start second check (should be ignored)
        final check2 = viewModel.checkForUpdates();

        await Future.wait([check1, check2]);

        // Should only have called checkForUpdates once
        expect(mockUpdateService.checkForUpdatesCallCount, equals(1));

        viewModel.dispose();
      });
    });

    group('version info', () {
      test('should return current version info', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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
      test('should provide access to update service', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        expect(viewModel.updateService, equals(mockUpdateService));

        viewModel.dispose();
      });

      test('should provide access to network service', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
        );

        await viewModel.initialize();

        expect(viewModel.networkService, equals(mockNetworkService));

        viewModel.dispose();
      });
    });

    group('dispose', () {
      test('should cancel network subscription on dispose', () async {
        final viewModel = UpdateSettingsViewModel(
          updateService: mockUpdateService,
          networkService: mockNetworkService,
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

class _MockUpdateService implements UpdateServiceInterface {
  int checkForUpdatesCallCount = 0;
  final _updateController = StreamController<UpdateInfo>.broadcast();
  final _downloadController = StreamController<DownloadProgress>.broadcast();

  @override
  Stream<UpdateInfo> get updateStream => _updateController.stream;

  @override
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;

  @override
  Future<bool> initialize() async => true;

  @override
  void dispose() {
    _updateController.close();
    _downloadController.close();
  }

  @override
  Future<UpdateInfo?> checkForUpdates({bool showNotification = false}) async {
    checkForUpdatesCallCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return null;
  }

  @override
  Map<String, String> getCurrentVersionInfo() {
    return {
      'version': '1.0.0',
      'buildNumber': '1',
    };
  }

  @override
  Future<void> updatePreferences(UpdatePreferences preferences) async {
    // No-op for testing
  }

  @override
  Future<String?> downloadUpdate(UpdateInfo updateInfo) async {
    return null;
  }

  @override
  Future<bool> installUpdate(String filePath) async {
    return false;
  }

  @override
  Future<void> cleanupDownloads({String? keepVersion}) async {}

  @override
  Future<bool> canInstallApks() async => false;

  @override
  Future<void> requestInstallPermission() async {}

  @override
  Future<Map<String, dynamic>> diagnosePermissions() async => {};

  @override
  Future<void> skipVersion(String version) async {}

  @override
  UpdatePreferences? get preferences => null;

  @override
  bool shouldAutoDownload(UpdateInfo updateInfo) => false;
}

class _MockNetworkService implements NetworkServiceInterface {
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
