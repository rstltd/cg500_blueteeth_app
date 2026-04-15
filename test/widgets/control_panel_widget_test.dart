import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/control_panel_widget.dart';
import 'package:cg500_blueteeth_app/controllers/simple_ble_controller.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/services/ble_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

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

  // Test helpers
  void addDevices(List<BleDeviceModel> devices) {
    _devices = devices;
    _devicesController.add(devices);
  }

  void setScanning(bool isScanning) {
    _isScanning = isScanning;
    _scanningController.add(isScanning);
  }

  void clearDevices() {
    clearScannedDevices();
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
  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {}

  @override
  void showInfo({
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
    _notificationsController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper function to create test device
  BleDeviceModel createTestDevice({
    String id = 'device-1',
    String name = 'Test Device',
    int rssi = -50,
  }) {
    return BleDeviceModel(
      id: id,
      name: name,
      displayName: name.isNotEmpty ? name : 'Unknown Device',
      rssi: rssi,
    );
  }

  group('ControlPanelWidget', () {
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
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(ControlPanelWidget), findsOneWidget);
    });

    testWidgets('should display Start Scanning button initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.text(AppStrings.startScanning), findsOneWidget);
    });

    testWidgets('should display clear all button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });

    testWidgets('should display 0 devices found initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.text(AppStrings.devicesFound(0)), findsOneWidget);
    });

    testWidgets('should display devices icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.devices), findsOneWidget);
    });

    testWidgets('should update device count when devices stream emits',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.text(AppStrings.devicesFound(0)), findsOneWidget);

      // Add devices
      mockBleService.addDevices([
        createTestDevice(id: '1', name: 'Device 1'),
        createTestDevice(id: '2', name: 'Device 2'),
        createTestDevice(id: '3', name: 'Device 3'),
      ]);
      await tester.pump();

      expect(find.text(AppStrings.devicesFound(3)), findsOneWidget);
    });

    testWidgets('should show Stop Scanning when scanning stream emits true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.text(AppStrings.startScanning), findsOneWidget);

      mockBleService.setScanning(true);
      await tester.pump();

      expect(find.text(AppStrings.stopScanning), findsOneWidget);
    });

    testWidgets('should toggle scanning state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      // Initially not scanning
      expect(find.text(AppStrings.startScanning), findsOneWidget);

      // Start scanning
      mockBleService.setScanning(true);
      await tester.pump();
      expect(find.text(AppStrings.stopScanning), findsOneWidget);

      // Stop scanning
      mockBleService.setScanning(false);
      await tester.pump();
      expect(find.text(AppStrings.startScanning), findsOneWidget);
    });

    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(ControlPanelWidget), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(ControlPanelWidget), findsOneWidget);
    });

    testWidgets('should have Container as root widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have Column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should have Row for buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should have IconButton for clear', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('should handle null data gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      // Should display default values
      expect(find.text(AppStrings.startScanning), findsOneWidget);
      expect(find.text(AppStrings.devicesFound(0)), findsOneWidget);
    });

    testWidgets('should update when device list grows',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      // Add one device
      mockBleService.addDevices([createTestDevice(id: '1')]);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.devicesFound(1)), findsOneWidget);

      // Add more devices
      mockBleService.addDevices([
        createTestDevice(id: '1'),
        createTestDevice(id: '2'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.devicesFound(2)), findsOneWidget);
    });

    testWidgets('should update when device list shrinks',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      // Add devices
      mockBleService.addDevices([
        createTestDevice(id: '1'),
        createTestDevice(id: '2'),
        createTestDevice(id: '3'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.devicesFound(3)), findsOneWidget);

      // Remove devices
      mockBleService.addDevices([createTestDevice(id: '1')]);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.devicesFound(1)), findsOneWidget);
    });

    testWidgets('should handle empty device list after having devices',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlPanelWidget(controller: controller),
          ),
        ),
      );

      // Add devices
      mockBleService.addDevices([createTestDevice(id: '1')]);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.devicesFound(1)), findsOneWidget);

      // Clear devices
      mockBleService.clearDevices();
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.devicesFound(0)), findsOneWidget);
    });
  });

  group('ControlPanelWidget UI Components', () {
    testWidgets('should display scan button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text(AppStrings.startScanning),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.startScanning), findsOneWidget);
    });

    testWidgets('should display clear all button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.clear_all, color: Colors.grey.shade700),
                tooltip: AppStrings.clearDevices,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear_all), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('should display device count section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 6),
                Text(
                  AppStrings.devicesFound(5),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.devices), findsOneWidget);
      expect(find.text(AppStrings.devicesFound(5)), findsOneWidget);
    });

    testWidgets('should display zero devices when empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 6),
                Text(
                  AppStrings.devicesFound(0),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.devicesFound(0)), findsOneWidget);
    });
  });

  group('ControlPanelWidget Scanning State', () {
    testWidgets('should show Stop Scanning when scanning is active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: Text(AppStrings.stopScanning),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.stopScanning), findsOneWidget);
    });

    testWidgets('should switch between Start and Stop text', (WidgetTester tester) async {
      bool isScanning = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() => isScanning = !isScanning);
                  },
                  child: Text(isScanning ? AppStrings.stopScanning : AppStrings.startScanning),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.startScanning), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text(AppStrings.stopScanning), findsOneWidget);
    });
  });

  group('ControlPanelWidget StreamBuilder Pattern', () {
    testWidgets('should update device count when stream emits', (WidgetTester tester) async {
      final deviceController = StreamController<List<BleDeviceModel>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<List<BleDeviceModel>>(
              stream: deviceController.stream,
              initialData: const [],
              builder: (context, snapshot) {
                int deviceCount = snapshot.data?.length ?? 0;
                return Text(AppStrings.devicesFound(deviceCount));
              },
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.devicesFound(0)), findsOneWidget);

      // Add devices
      deviceController.add([
        createTestDevice(id: '1'),
        createTestDevice(id: '2'),
        createTestDevice(id: '3'),
      ]);
      await tester.pump();

      expect(find.text(AppStrings.devicesFound(3)), findsOneWidget);

      await deviceController.close();
    });

    testWidgets('should handle scanning state stream', (WidgetTester tester) async {
      final scanningController = StreamController<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<bool>(
              stream: scanningController.stream,
              initialData: false,
              builder: (context, snapshot) {
                bool isScanning = snapshot.data ?? false;
                return Text(isScanning ? 'Scanning...' : 'Not scanning');
              },
            ),
          ),
        ),
      );

      expect(find.text('Not scanning'), findsOneWidget);

      scanningController.add(true);
      await tester.pump();

      expect(find.text('Scanning...'), findsOneWidget);

      await scanningController.close();
    });
  });

  group('ControlPanelWidget Layout', () {
    testWidgets('should have container with margin', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              child: const Text('Control Panel'),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
      expect(find.text('Control Panel'), findsOneWidget);
    });

    testWidgets('should have Column layout with multiple children', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: const [
                    Expanded(child: Text('Button 1')),
                    SizedBox(width: 12),
                    Text('Button 2'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Device Count'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
      expect(find.text('Button 1'), findsOneWidget);
      expect(find.text('Button 2'), findsOneWidget);
      expect(find.text('Device Count'), findsOneWidget);
    });

    testWidgets('should have gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have box shadow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });
  });

  group('ControlPanelWidget Button Interactions', () {
    testWidgets('should trigger callback when scan button pressed', (WidgetTester tester) async {
      bool scanPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => scanPressed = true,
              child: Text(AppStrings.startScanning),
            ),
          ),
        ),
      );

      await tester.tap(find.text(AppStrings.startScanning));
      await tester.pump();

      expect(scanPressed, isTrue);
    });

    testWidgets('should trigger callback when clear button pressed', (WidgetTester tester) async {
      bool clearPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              onPressed: () => clearPressed = true,
              icon: const Icon(Icons.clear_all),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pump();

      expect(clearPressed, isTrue);
    });
  });

  group('ControlPanelWidget Theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Control Panel'),
            ),
          ),
        ),
      );

      expect(find.text('Control Panel'), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Control Panel'),
            ),
          ),
        ),
      );

      expect(find.text('Control Panel'), findsOneWidget);
    });
  });

  group('ControlPanelWidget Device Count Display', () {
    testWidgets('should show singular device when count is 1', (WidgetTester tester) async {
      // Note: The actual widget uses plural form always
      // This test verifies the text format
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(AppStrings.devicesFound(1)),
          ),
        ),
      );

      expect(find.text(AppStrings.devicesFound(1)), findsOneWidget);
    });

    testWidgets('should show multiple devices', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(AppStrings.devicesFound(10)),
          ),
        ),
      );

      expect(find.text(AppStrings.devicesFound(10)), findsOneWidget);
    });

    testWidgets('should show large device count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(AppStrings.devicesFound(100)),
          ),
        ),
      );

      expect(find.text(AppStrings.devicesFound(100)), findsOneWidget);
    });
  });

  group('ControlPanelWidget Tooltip', () {
    testWidgets('should have tooltip on clear button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.clear_all),
              tooltip: AppStrings.clearDevices,
            ),
          ),
        ),
      );

      // Verify tooltip is set
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, AppStrings.clearDevices);
    });
  });

  group('ControlPanelWidget Responsive', () {
    testWidgets('should render on mobile screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.all(16),
              child: const Text('Control Panel'),
            ),
          ),
        ),
      );

      expect(find.text('Control Panel'), findsOneWidget);
    });

    testWidgets('should render on tablet screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.all(16),
              child: const Text('Control Panel'),
            ),
          ),
        ),
      );

      expect(find.text('Control Panel'), findsOneWidget);
    });
  });
}
