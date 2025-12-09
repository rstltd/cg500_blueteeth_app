import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/quick_stats_widget.dart';
import 'package:cg500_blueteeth_app/controllers/simple_ble_controller.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/services/ble_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/services/smart_notification_service.dart';

/// Mock BLE Service for testing
class MockBleService implements BleService {
  final _devicesController = StreamController<List<BleDeviceModel>>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _connectedDeviceController = StreamController<BleDeviceModel?>.broadcast();
  final _commandResponseController = StreamController<String>.broadcast();

  List<BleDeviceModel> _devices = [];
  bool _isScanning = false;
  bool _isInitialized = false;

  @override
  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;

  @override
  Stream<bool> get scanningStream => _scanningController.stream;

  @override
  Stream<BleDeviceModel?> get connectedDeviceStream => _connectedDeviceController.stream;

  @override
  Stream<String> get commandResponseStream => _commandResponseController.stream;

  @override
  BleDeviceModel? get connectedDevice => null;

  @override
  List<BleDeviceModel> get scannedDevices => _devices;

  @override
  bool get isScanning => _isScanning;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize() async {
    _isInitialized = true;
    return true;
  }

  @override
  Future<bool> isBluetoothEnabled() async => true;

  @override
  Future<void> turnOnBluetooth() async {}

  @override
  Future<bool> startScanning({Duration timeout = const Duration(seconds: 15)}) async {
    _isScanning = true;
    _scanningController.add(true);
    return true;
  }

  @override
  Future<void> stopScanning() async {
    _isScanning = false;
    _scanningController.add(false);
  }

  @override
  void clearScannedDevices() {
    _devices = [];
    _devicesController.add([]);
  }

  @override
  Future<bool> connectToDevice(String deviceId) async => true;

  @override
  Future<void> disconnectDevice() async {}

  @override
  Future<List<BleServiceModel>> discoverServices(String deviceId) async => [];

  @override
  Future<bool> sendCommand(String command) async => true;

  @override
  Map<String, dynamic> getCommandInfo() => {};

  @override
  void dispose() {
    _devicesController.close();
    _scanningController.close();
    _connectedDeviceController.close();
    _commandResponseController.close();
  }

  void addDevices(List<BleDeviceModel> devices) {
    _devices = devices;
    _devicesController.add(devices);
  }
}

/// Mock Notification Service for testing
class MockNotificationService extends NotificationService {
  final _notificationsController = StreamController<NotificationModel>.broadcast();

  @override
  Stream<NotificationModel> get notifications => _notificationsController.stream;

  @override
  void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {}

  @override
  void showError({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {}

  @override
  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {}

  @override
  void showInfo({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
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
    _notificationsController.close();
  }
}

BleDeviceModel createTestDevice({
  String id = 'device-1',
  String name = 'Test Device',
  int rssi = -50,
  BleConnectionState connectionState = BleConnectionState.disconnected,
}) {
  return BleDeviceModel(
    id: id,
    name: name,
    displayName: name.isNotEmpty ? name : 'Unknown Device',
    rssi: rssi,
    connectionState: connectionState,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuickStatsWidget', () {
    late MockBleService mockBleService;
    late MockNotificationService mockNotificationService;
    late SimpleBleController controller;

    setUp(() {
      mockBleService = MockBleService();
      mockNotificationService = MockNotificationService();
      controller = SimpleBleController.withDependencies(
        bleService: mockBleService,
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      mockBleService.dispose();
      mockNotificationService.dispose();
    });

    testWidgets('should render without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(QuickStatsWidget), findsOneWidget);
    });

    testWidgets('should display Quick Stats title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.text('Quick Stats'), findsOneWidget);
    });

    testWidgets('should display Found label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.text('Found'), findsOneWidget);
    });

    testWidgets('should display Connected label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('should display devices icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.devices), findsOneWidget);
    });

    testWidgets('should display link icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('should show 0 for found and connected initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      // Should find two '0' texts - one for Found, one for Connected
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('should update found count when devices are added', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      mockBleService.addDevices([
        createTestDevice(id: '1'),
        createTestDevice(id: '2'),
        createTestDevice(id: '3'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should update connected count when devices are connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      mockBleService.addDevices([
        createTestDevice(id: '1', connectionState: BleConnectionState.connected),
        createTestDevice(id: '2', connectionState: BleConnectionState.disconnected),
        createTestDevice(id: '3', connectionState: BleConnectionState.connected),
      ]);
      await tester.pumpAndSettle();

      // Should show 3 found and 2 connected
      expect(find.text('3'), findsOneWidget); // Found count
      expect(find.text('2'), findsOneWidget); // Connected count
    });

    testWidgets('should have Row layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should have Column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.text('Quick Stats'), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      expect(find.text('Quick Stats'), findsOneWidget);
    });

    testWidgets('should update when device list changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      // Add devices
      mockBleService.addDevices([createTestDevice(id: '1')]);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Add more
      mockBleService.addDevices([
        createTestDevice(id: '1'),
        createTestDevice(id: '2'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // Clear
      mockBleService.clearScannedDevices();
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('should handle mixed connection states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatsWidget(controller: controller),
          ),
        ),
      );

      mockBleService.addDevices([
        createTestDevice(id: '1', connectionState: BleConnectionState.connected),
        createTestDevice(id: '2', connectionState: BleConnectionState.connecting),
        createTestDevice(id: '3', connectionState: BleConnectionState.disconnected),
        createTestDevice(id: '4', connectionState: BleConnectionState.connected),
      ]);
      await tester.pumpAndSettle();

      // 4 found, 2 connected
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
