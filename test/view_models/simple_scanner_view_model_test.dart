import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/ble_controller_interface.dart';
import 'package:cg500_blueteeth_app/controllers/update_controller.dart';
import 'package:cg500_blueteeth_app/core/interfaces/ble_notification_delegate.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/services/error_handling_service.dart';
import 'package:cg500_blueteeth_app/services/layout_preference_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/services/update_checker.dart';
import 'package:cg500_blueteeth_app/services/download_manager.dart';
import 'package:cg500_blueteeth_app/services/install_manager.dart';
import 'package:cg500_blueteeth_app/services/update_preferences_store.dart';
import 'package:cg500_blueteeth_app/view_models/simple_scanner_view_model.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimpleScannerViewModel', () {
    late _MockBleController mockController;
    late _MockThemeService mockThemeService;
    late _MockUpdateController mockUpdateManager;
    late ErrorHandlingService errorHandlingService;
    late LayoutPreferenceService layoutService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockController = _MockBleController();
      mockThemeService = _MockThemeService();
      mockUpdateManager = _MockUpdateController();
      errorHandlingService = ErrorHandlingService.forTesting(
        notificationService: _MockNotificationService(),
      );
      layoutService = LayoutPreferenceService.forTesting();
      await layoutService.init();
    });

    tearDown(() {
      mockController.dispose();
      mockThemeService.dispose();
      errorHandlingService.dispose();
    });

    group('initialization', () {
      test('should start with correct initial state', () {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        expect(viewModel.isInitialized, isFalse);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.devices, isEmpty);
        expect(viewModel.isScanning, isFalse);
        expect(viewModel.connectedDevice, isNull);
        expect(viewModel.hasConnectedDevice, isFalse);

        viewModel.dispose();
      });

      test('should initialize and set up streams', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.isInitialized, isTrue);
        expect(viewModel.controller, equals(mockController));
        expect(viewModel.themeService, equals(mockThemeService));
        expect(viewModel.updateManager, equals(mockUpdateManager));

        viewModel.dispose();
      });

      test('should subscribe to device stream changes', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.devices, isEmpty);

        // Emit devices
        final testDevices = [
          BleDeviceModel(id: '1', name: 'Device 1', displayName: 'Device 1'),
          BleDeviceModel(id: '2', name: 'Device 2', displayName: 'Device 2'),
        ];
        mockController.emitDevices(testDevices);
        await Future.delayed(Duration.zero);

        expect(viewModel.devices.length, equals(2));

        viewModel.dispose();
      });

      test('should subscribe to scanning state changes', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.isScanning, isFalse);

        mockController.emitScanning(true);
        await Future.delayed(Duration.zero);

        expect(viewModel.isScanning, isTrue);

        mockController.emitScanning(false);
        await Future.delayed(Duration.zero);

        expect(viewModel.isScanning, isFalse);

        viewModel.dispose();
      });

      test('should subscribe to connected device changes', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.connectedDevice, isNull);
        expect(viewModel.hasConnectedDevice, isFalse);

        final testDevice = BleDeviceModel(
          id: 'test-1',
          name: 'Test Device',
          displayName: 'Test Device',
        );
        mockController.emitConnectedDevice(testDevice);
        await Future.delayed(Duration.zero);

        expect(viewModel.connectedDevice, isNotNull);
        expect(viewModel.connectedDevice!.id, equals('test-1'));
        expect(viewModel.hasConnectedDevice, isTrue);

        viewModel.dispose();
      });

      test('should subscribe to theme mode changes', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.themeMode, equals(AppThemeMode.system));

        mockThemeService.emitThemeMode(AppThemeMode.dark);
        await Future.delayed(Duration.zero);

        expect(viewModel.themeMode, equals(AppThemeMode.dark));

        viewModel.dispose();
      });
    });

    group('BLE actions', () {
      test('should start scanning', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        final result = await viewModel.startScanning();

        expect(result, isTrue);
        expect(mockController.startScanningCallCount, equals(1));

        viewModel.dispose();
      });

      test('should stop scanning', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        await viewModel.stopScanning();

        expect(mockController.stopScanningCallCount, equals(1));

        viewModel.dispose();
      });

      test('should connect to device', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        final result = await viewModel.connectToDevice('test-id');

        expect(result, isTrue);
        expect(mockController.connectCallCount, equals(1));
        expect(mockController.lastConnectedDeviceId, equals('test-id'));

        viewModel.dispose();
      });

      test('should disconnect device', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        await viewModel.disconnectDevice();

        expect(mockController.disconnectCallCount, equals(1));

        viewModel.dispose();
      });

      test('should clear devices', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        viewModel.clearDevices();

        expect(mockController.clearDevicesCallCount, equals(1));

        viewModel.dispose();
      });

      test('should toggle device favorite', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        final device = BleDeviceModel(
          id: 'test-1',
          name: 'Test Device',
          displayName: 'Test Device',
          isFavorite: false,
        );

        final result = viewModel.toggleDeviceFavorite(device);

        expect(result.isFavorite, isTrue);

        viewModel.dispose();
      });
    });

    group('theme actions', () {
      test('should toggle theme', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        viewModel.toggleTheme();

        expect(mockThemeService.toggleThemeCallCount, equals(1));

        viewModel.dispose();
      });

      test('should provide theme mode icon', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        final icon = viewModel.themeModeIcon;

        expect(icon, isA<IconData>());

        viewModel.dispose();
      });

      test('should provide theme mode description', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        final description = viewModel.themeModeDescription;

        expect(description, isNotEmpty);

        viewModel.dispose();
      });
    });

    group('update actions', () {
      test('should check for updates', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        await viewModel.checkForUpdates(force: true);

        expect(mockUpdateManager.checkForUpdatesWithUICallCount, equals(1));

        viewModel.dispose();
      });
    });

    group('stream getters', () {
      test('should provide devices stream', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.devicesStream, isA<Stream<List<BleDeviceModel>>>());

        viewModel.dispose();
      });

      test('should provide scanning stream', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.scanningStream, isA<Stream<bool>>());

        viewModel.dispose();
      });

      test('should provide connected device stream', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.connectedDeviceStream, isA<Stream<BleDeviceModel?>>());

        viewModel.dispose();
      });

      test('should provide theme mode stream', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.themeModeStream, isA<Stream<AppThemeMode>>());

        viewModel.dispose();
      });

      test('should provide notification stream', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        expect(viewModel.notificationStream, isA<Stream<NotificationModel>>());

        viewModel.dispose();
      });
    });

    group('filteredDevices — type-grouped ordering (ADR-0008)', () {
      // Sort tests focus on ordering across groups including unknown,
      // so they disable the whitelist filter (which would otherwise hide
      // unknown devices). Whitelist behaviour is covered by its own group.
      Future<SimpleScannerViewModel> initVm() async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );
        await viewModel.initialize();
        await viewModel.toggleScannerWhitelist(); // off — show all
        return viewModel;
      }

      BleDeviceModel mk(String id, String name) =>
          BleDeviceModel(id: id, name: name, displayName: name);

      test(
          'cross-group: GNSS → accel → unknown regardless of discovery order',
          () async {
        final viewModel = await initVm();

        // Discovered out of order: unknown, GNSS, accel, unknown, GNSS.
        mockController.emitDevices([
          mk('u1', 'GenericBLE-1'),
          mk('g1', 'A01LT00001'),
          mk('a1', 'B01LT00001'),
          mk('u2', 'SonyHeadphones'),
          mk('g2', 'A01LT00002'),
        ]);
        await Future<void>.delayed(Duration.zero);

        final ids = viewModel.filteredDevices.map((d) => d.id).toList();
        // GNSS (g1, g2) → accel (a1) → unknown (u1, u2). Intra-group
        // discovery order: g1 before g2 (both GNSS); u1 before u2.
        expect(ids, ['g1', 'g2', 'a1', 'u1', 'u2']);

        viewModel.dispose();
      });

      test('intra-group order matches discovery order (stable sort)',
          () async {
        final viewModel = await initVm();

        // Two devices of the same group, discovered in a specific order.
        mockController.emitDevices([
          mk('g2', 'A01LT00002'),
          mk('g1', 'A01LT00001'),
          mk('g3', 'A01LT00003'),
        ]);
        await Future<void>.delayed(Duration.zero);

        // Intra-GNSS order matches the order they were emitted: g2, g1, g3.
        expect(
          viewModel.filteredDevices.map((d) => d.id).toList(),
          ['g2', 'g1', 'g3'],
        );

        viewModel.dispose();
      });

      test('search-name filter composes with type-grouped sort', () async {
        final viewModel = await initVm();

        mockController.emitDevices([
          mk('u1', 'GenericBLE'),
          mk('g1', 'A01LT-Apple'),
          mk('a1', 'B01LT-Banana'),
          mk('g2', 'A01LT-Avocado'),
        ]);
        await Future<void>.delayed(Duration.zero);

        // Search "lt" matches all three RST devices and excludes GenericBLE.
        viewModel.setSearchQuery('lt');

        final ids = viewModel.filteredDevices.map((d) => d.id).toList();
        // Order after search: GNSS group first, then accel.
        expect(ids, ['g1', 'g2', 'a1']);

        viewModel.dispose();
      });

      test(
          'all-same-type list keeps discovery order without spurious '
          'reordering', () async {
        final viewModel = await initVm();

        mockController.emitDevices([
          mk('g3', 'A01LT-Charlie'),
          mk('g1', 'A01LT-Alpha'),
          mk('g2', 'A01LT-Bravo'),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(
          viewModel.filteredDevices.map((d) => d.id).toList(),
          ['g3', 'g1', 'g2'],
        );

        viewModel.dispose();
      });
    });

    group('scanner whitelist filter (ADR-0008)', () {
      // Uses the outer setUp's layoutService and reset SharedPreferences.

      Future<SimpleScannerViewModel> initVm() async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );
        await viewModel.initialize();
        return viewModel;
      }

      BleDeviceModel mk(String id, String name) =>
          BleDeviceModel(id: id, name: name, displayName: name);

      test('default is enabled — list excludes unknown / non-RST devices',
          () async {
        final viewModel = await initVm();

        expect(viewModel.scannerWhitelistEnabled, isTrue,
            reason: 'ADR-0008 default is whitelist on.');

        mockController.emitDevices([
          mk('g1', 'A01LT00001'),
          mk('u1', 'GenericBLE'),
          mk('a1', 'B01LT00001'),
          mk('u2', 'AnotherBLE'),
        ]);
        await Future<void>.delayed(Duration.zero);

        final ids = viewModel.filteredDevices.map((d) => d.id).toList();
        expect(ids, ['g1', 'a1'],
            reason: 'Unknown devices must be hidden when whitelist is on.');

        viewModel.dispose();
      });

      test(
          'toggleScannerWhitelist flips state and surfaces unknown devices',
          () async {
        final viewModel = await initVm();

        mockController.emitDevices([
          mk('g1', 'A01LT00001'),
          mk('u1', 'GenericBLE'),
        ]);
        await Future<void>.delayed(Duration.zero);

        // Whitelist on by default — unknown hidden.
        expect(viewModel.filteredDevices.map((d) => d.id), ['g1']);

        await viewModel.toggleScannerWhitelist();

        expect(viewModel.scannerWhitelistEnabled, isFalse);
        // Order: GNSS first, then unknown.
        expect(
          viewModel.filteredDevices.map((d) => d.id).toList(),
          ['g1', 'u1'],
        );

        viewModel.dispose();
      });

      test('toggle persists across VM instances (cold-start preservation)',
          () async {
        final viewModel1 = await initVm();
        await viewModel1.toggleScannerWhitelist(); // -> false
        expect(viewModel1.scannerWhitelistEnabled, isFalse);
        viewModel1.dispose();

        // Recreate the VM (simulating cold start) sharing the same
        // LayoutPreferenceService — the persisted preference must stick.
        final viewModel2 = await initVm();
        expect(viewModel2.scannerWhitelistEnabled, isFalse);
        viewModel2.dispose();
      });

      test('search + whitelist filters compose without one breaking the other',
          () async {
        final viewModel = await initVm();
        await viewModel.toggleScannerWhitelist(); // off — show all

        mockController.emitDevices([
          mk('g1', 'A01LT-Apple'),
          mk('u1', 'AppleHeadphones'),
          mk('g2', 'A01LT-Banana'),
        ]);
        await Future<void>.delayed(Duration.zero);

        viewModel.setSearchQuery('apple');

        // Both Apples match the search; whitelist is off so unknown
        // is included. GNSS group first.
        final ids = viewModel.filteredDevices.map((d) => d.id).toList();
        expect(ids, ['g1', 'u1']);

        // Re-enable whitelist; AppleHeadphones (unknown) drops out.
        await viewModel.toggleScannerWhitelist();
        expect(
          viewModel.filteredDevices.map((d) => d.id).toList(),
          ['g1'],
        );

        viewModel.dispose();
      });
    });

    group('dispose', () {
      test('should cancel subscriptions on dispose', () async {
        final viewModel = SimpleScannerViewModel(
          controller: mockController,
          themeService: mockThemeService,
          updateManager: mockUpdateManager,
          errorHandlingService: errorHandlingService,
          layoutPreferenceService: layoutService,
        );

        await viewModel.initialize();

        viewModel.dispose();

        // Emit after dispose - should not update state
        mockController.emitScanning(true);
        await Future.delayed(Duration.zero);

        expect(viewModel.isDisposed, isTrue);
      });
    });
  });
}

// --- Mock Implementations ---

class _MockBleController implements BleControllerInterface {
  final _devicesController = StreamController<List<BleDeviceModel>>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _connectedDeviceController = StreamController<BleDeviceModel?>.broadcast();
  final _commandResponseController = StreamController<String>.broadcast();
  final _notificationController = StreamController<NotificationModel>.broadcast();
  final _adapterOnController = StreamController<bool>.broadcast();

  List<BleDeviceModel> _devices = [];
  bool _isScanning = false;
  BleDeviceModel? _connectedDevice;
  bool _isInitialized = false;

  int startScanningCallCount = 0;
  int stopScanningCallCount = 0;
  int connectCallCount = 0;
  int disconnectCallCount = 0;
  int clearDevicesCallCount = 0;
  String? lastConnectedDeviceId;

  void emitDevices(List<BleDeviceModel> devices) {
    _devices = devices;
    _devicesController.add(devices);
  }

  void emitScanning(bool isScanning) {
    _isScanning = isScanning;
    _scanningController.add(isScanning);
  }

  void emitConnectedDevice(BleDeviceModel? device) {
    _connectedDevice = device;
    _connectedDeviceController.add(device);
  }

  @override
  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;

  @override
  Stream<bool> get scanningStream => _scanningController.stream;

  @override
  Stream<BleDeviceModel?> get connectedDeviceStream => _connectedDeviceController.stream;

  @override
  Stream<String> get commandResponseStream => _commandResponseController.stream;

  @override
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  @override
  Stream<bool> get adapterOnStream => _adapterOnController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  BleDeviceModel? get connectedDevice => _connectedDevice;

  @override
  List<BleDeviceModel> get scannedDevices => _devices;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize() async {
    _isInitialized = true;
    return true;
  }

  @override
  Future<bool> startScanning({Duration? timeout}) async {
    startScanningCallCount++;
    _isScanning = true;
    _scanningController.add(true);
    return true;
  }

  @override
  Future<void> stopScanning() async {
    stopScanningCallCount++;
    _isScanning = false;
    _scanningController.add(false);
  }

  @override
  Future<bool> connectToDevice(String deviceId) async {
    connectCallCount++;
    lastConnectedDeviceId = deviceId;
    return true;
  }

  @override
  Future<void> disconnectDevice() async {
    disconnectCallCount++;
    _connectedDevice = null;
    _connectedDeviceController.add(null);
  }

  @override
  Future<List<BleServiceModel>> discoverServices(String deviceId) async {
    return [];
  }

  @override
  Future<bool> sendCommand(String command) async {
    return true;
  }

  @override
  Map<String, dynamic> getCommandInfo() {
    return {};
  }

  @override
  void clearDevices() {
    clearDevicesCallCount++;
    _devices = [];
    _devicesController.add([]);
  }

  @override
  void dispose() {
    _devicesController.close();
    _scanningController.close();
    _connectedDeviceController.close();
    _commandResponseController.close();
    _notificationController.close();
    _adapterOnController.close();
  }

  BleNotificationVerbosity _notificationVerbosity = BleNotificationVerbosity.minimal;

  @override
  BleNotificationVerbosity? get notificationVerbosity => _notificationVerbosity;

  @override
  void setNotificationVerbosity(BleNotificationVerbosity verbosity) {
    _notificationVerbosity = verbosity;
  }
}

class _MockThemeService extends ThemeService {
  final _themeModeController = StreamController<AppThemeMode>.broadcast();
  AppThemeMode _currentMode = AppThemeMode.system;
  int toggleThemeCallCount = 0;

  _MockThemeService() : super.forTesting();

  void emitThemeMode(AppThemeMode mode) {
    _currentMode = mode;
    _themeModeController.add(mode);
  }

  @override
  Stream<AppThemeMode> get themeModeStream => _themeModeController.stream;

  @override
  AppThemeMode get currentThemeMode => _currentMode;

  @override
  void toggleTheme() {
    toggleThemeCallCount++;
    switch (_currentMode) {
      case AppThemeMode.light:
        _currentMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        _currentMode = AppThemeMode.system;
        break;
      case AppThemeMode.system:
        _currentMode = AppThemeMode.light;
        break;
    }
    _themeModeController.add(_currentMode);
  }

  @override
  IconData get themeModeIcon => Icons.brightness_auto;

  @override
  String get themeModeDescription => 'System Theme';

  @override
  void dispose() {
    _themeModeController.close();
  }
}

class _MockUpdateController extends UpdateController {
  int checkForUpdatesWithUICallCount = 0;

  _MockUpdateController()
      : super.withDependencies(
          updateChecker: _NoopUpdateChecker(),
          downloadManager: _NoopDownloadManager(),
          installManager: _NoopInstallManager(),
          preferencesStore: UpdatePreferencesStore(),
          networkService: _MockNetworkService(),
          notificationService: _MockNotificationService(),
        );

  @override
  Future<UpdateInfo?> checkForUpdatesWithUI({
    bool force = false,
    bool showUpToDateMessage = false,
  }) async {
    checkForUpdatesWithUICallCount++;
    return null;
  }
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

class _MockNetworkService extends NetworkService {
  final _networkController = StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get networkStream => _networkController.stream;

  @override
  NetworkStatus get currentStatus => NetworkStatus.wifi;

  @override
  Future<bool> initialize() async => true;

  @override
  void dispose() {
    _networkController.close();
  }

  @override
  bool isSuitableForDownload({required bool wifiOnly}) => true;

  @override
  String getStatusDescription() => 'Connected via WiFi';

  @override
  String getNetworkTypeDisplayName() => 'WiFi';

  @override
  String estimateDownloadTime(int fileSizeBytes) => '~5s';
}

class _MockNotificationService extends NotificationService {
  final _notificationController = StreamController<NotificationModel>.broadcast();

  @override
  Stream<NotificationModel> get notifications => _notificationController.stream;

  @override
  void showInfo({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {}

  @override
  void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {}

  @override
  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {}

  @override
  void showError({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {}

  @override
  void showConnectionStatus({
    required String title,
    required String message,
    required bool isConnected,
  }) {}

  @override
  void showScanningStatus({
    required String title,
    required String message,
    required bool isScanning,
  }) {}

  @override
  void dispose() {
    _notificationController.close();
  }
}
