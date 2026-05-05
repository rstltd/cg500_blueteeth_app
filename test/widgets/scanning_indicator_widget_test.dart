import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/scanning_indicator_widget.dart';
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
  Stream<bool> get adapterOnStream => const Stream<bool>.empty();

  @override
  BleDeviceModel? get connectedDevice => null;

  @override
  List<BleDeviceModel> get scannedDevices => [];

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
  void clearScannedDevices() {}

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

  void setScanning(bool isScanning) {
    _isScanning = isScanning;
    _scanningController.add(isScanning);
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
  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {}

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

  group('ScanningIndicatorWidget', () {
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
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(ScanningIndicatorWidget), findsOneWidget);
    });

    testWidgets('should be hidden when not scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      // Should show SizedBox.shrink when not scanning
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text(AppStrings.scanningForDevices), findsNothing);
    });

    testWidgets('should show scanning text when scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      // Start scanning
      mockBleService.setScanning(true);
      // Use pump() instead of pumpAndSettle() because CircularProgressIndicator has infinite animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.scanningForDevices), findsOneWidget);
    });

    testWidgets('should show progress indicator when scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      mockBleService.setScanning(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have AnimatedContainer when scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      mockBleService.setScanning(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('should have Row layout when scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      mockBleService.setScanning(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should toggle visibility based on scanning state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      // Initially not scanning
      expect(find.text(AppStrings.scanningForDevices), findsNothing);

      // Start scanning
      mockBleService.setScanning(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStrings.scanningForDevices), findsOneWidget);

      // Stop scanning
      mockBleService.setScanning(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStrings.scanningForDevices), findsNothing);
    });

    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      mockBleService.setScanning(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.scanningForDevices), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      mockBleService.setScanning(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.scanningForDevices), findsOneWidget);
    });

    testWidgets('should show shrink box for false initial data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      // StreamBuilder initialData is false, so should show nothing
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(AppStrings.scanningForDevices), findsNothing);
    });

    testWidgets('should handle rapid state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanningIndicatorWidget(controller: controller),
          ),
        ),
      );

      // Rapid state changes
      mockBleService.setScanning(true);
      await tester.pump();
      mockBleService.setScanning(false);
      await tester.pump();
      mockBleService.setScanning(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Final state should be scanning
      expect(find.text(AppStrings.scanningForDevices), findsOneWidget);
    });
  });
}
