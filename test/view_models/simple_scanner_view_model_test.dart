import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/ble_controller_interface.dart';
import 'package:cg500_blueteeth_app/controllers/app_update_manager.dart';
import 'package:cg500_blueteeth_app/core/interfaces/ble_notification_delegate.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/services/error_handling_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/services/theme_service.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/view_models/simple_scanner_view_model.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/models/update_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimpleScannerViewModel', () {
    late _MockBleController mockController;
    late _MockThemeService mockThemeService;
    late _MockAppUpdateManager mockUpdateManager;
    late ErrorHandlingService errorHandlingService;

    setUp(() {
      mockController = _MockBleController();
      mockThemeService = _MockThemeService();
      mockUpdateManager = _MockAppUpdateManager();
      errorHandlingService = ErrorHandlingService.forTesting(
        notificationService: _MockNotificationService(),
      );
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
        );

        await viewModel.initialize();

        expect(viewModel.notificationStream, isA<Stream<NotificationModel>>());

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

class _MockAppUpdateManager extends AppUpdateManager {
  int checkForUpdatesWithUICallCount = 0;

  _MockAppUpdateManager() : super.withDependencies(
    updateService: _MockUpdateService(),
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

class _MockUpdateService implements UpdateService {
  final _updateController = StreamController<UpdateInfo>.broadcast();
  final _downloadController = StreamController<DownloadProgress>.broadcast();

  @override
  Stream<UpdateInfo> get updateStream => _updateController.stream;

  @override
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;

  @override
  bool get isDownloading => false;

  @override
  Future<bool> initialize() async => true;

  @override
  void dispose() {
    _updateController.close();
    _downloadController.close();
  }

  @override
  Future<UpdateInfo?> checkForUpdates({bool showNotification = false}) async => null;

  @override
  Map<String, String> getCurrentVersionInfo() => {'version': '1.0.0', 'buildNumber': '1'};

  @override
  Future<void> updatePreferences(UpdatePreferences preferences) async {}

  @override
  Future<String?> downloadUpdate(UpdateInfo updateInfo) async => null;

  @override
  Future<bool> installUpdate(String filePath) async => false;

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
  }) {}

  @override
  void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {}

  @override
  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {}

  @override
  void showError({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
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
