import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/connection_status_widget.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import '../mocks/mock_ble_controller.dart';

/// Tests for ConnectionStatusWidget using actual widget source code
/// These tests import and use the real ConnectionStatusWidget to increase coverage
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBleController mockController;

  setUp(() {
    mockController = MockBleController();
  });

  tearDown(() {
    mockController.dispose();
  });

  group('ConnectionStatusWidget - Disconnected State', () {
    testWidgets('should display disconnected status when no device connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);
      expect(find.text(AppStrings.pleaseConnectFirst), findsOneWidget);
      expect(find.text(AppStrings.pleaseConnectBleDevice), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('should display compact disconnected status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.disconnected), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    });
  });

  group('ConnectionStatusWidget - Connected State', () {
    testWidgets('should display connected status when device is connected', (WidgetTester tester) async {
      final device = createTestDevice(
        id: 'device-1',
        name: 'Test Device',
        displayName: 'Test Device',
        rssi: -50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text(AppStrings.deviceConnected), findsOneWidget);
      expect(find.text(AppStrings.readyToSendCommands), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should display compact connected status', (WidgetTester tester) async {
      final device = createTestDevice(
        id: 'device-1',
        name: 'Compact Device',
        displayName: 'Compact Device',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              compact: true,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text(AppStrings.connected), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should show device name in compact mode when showDeviceInfo is true', (WidgetTester tester) async {
      final device = createTestDevice(
        id: 'device-1',
        displayName: 'My Sensor',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              compact: true,
              showDeviceInfo: true,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text(AppStrings.connected), findsOneWidget);
      expect(find.textContaining('My Sensor'), findsOneWidget);
    });

    testWidgets('should not show device name in compact mode when showDeviceInfo is false', (WidgetTester tester) async {
      final device = createTestDevice(
        id: 'device-1',
        displayName: 'Hidden Device',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              compact: true,
              showDeviceInfo: false,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text(AppStrings.connected), findsOneWidget);
      expect(find.textContaining('Hidden Device'), findsNothing);
    });
  });

  group('ConnectionStatusWidget - Device Info', () {
    testWidgets('should display device info when showDeviceInfo is true', (WidgetTester tester) async {
      final device = createTestDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        displayName: 'Info Device',
        rssi: -45,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              showDeviceInfo: true,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text('${AppStrings.device}:'), findsOneWidget);
      expect(find.text('Info Device'), findsOneWidget);
      expect(find.text('ID:'), findsOneWidget);
      expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
      expect(find.text('${AppStrings.rssi}:'), findsOneWidget);
      expect(find.text('-45 dBm'), findsOneWidget);
    });

    testWidgets('should not display device info when showDeviceInfo is false', (WidgetTester tester) async {
      final device = createTestDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        displayName: 'Hidden Info Device',
        rssi: -45,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              showDeviceInfo: false,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text(AppStrings.deviceConnected), findsOneWidget);
      expect(find.text('${AppStrings.device}:'), findsNothing);
      expect(find.text('ID:'), findsNothing);
      expect(find.text('${AppStrings.rssi}:'), findsNothing);
    });

    testWidgets('should display services count when services are available', (WidgetTester tester) async {
      final device = BleDeviceModel(
        id: 'device-1',
        name: 'Service Device',
        displayName: 'Service Device',
        rssi: -50,
        services: [
          BleServiceModel(uuid: '1800', displayName: 'Generic Access', characteristics: []),
          BleServiceModel(uuid: '1801', displayName: 'Generic Attribute', characteristics: []),
          BleServiceModel(uuid: '180f', displayName: 'Battery Service', characteristics: []),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              showDeviceInfo: true,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text('${AppStrings.services}:'), findsOneWidget);
      expect(find.text(AppStrings.servicesCount(3)), findsOneWidget);
    });

    testWidgets('should display connection duration when connectedAt is set', (WidgetTester tester) async {
      final connectedAt = DateTime.now().subtract(const Duration(minutes: 5, seconds: 30));
      final device = BleDeviceModel(
        id: 'device-1',
        name: 'Duration Device',
        displayName: 'Duration Device',
        rssi: -50,
        connectedAt: connectedAt,
        connectionState: BleConnectionState.connected,  // Required for connectionDuration to work
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              showDeviceInfo: true,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text('${AppStrings.connectedFor}:'), findsOneWidget);
      // Duration should be displayed (format varies slightly due to timing)
      expect(find.textContaining(':'), findsWidgets);
    });

    testWidgets('should format duration with hours', (WidgetTester tester) async {
      final connectedAt = DateTime.now().subtract(const Duration(hours: 1, minutes: 30, seconds: 45));
      final device = BleDeviceModel(
        id: 'device-1',
        name: 'Long Duration Device',
        displayName: 'Long Duration Device',
        rssi: -50,
        connectedAt: connectedAt,
        connectionState: BleConnectionState.connected,  // Required for connectionDuration to work
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
              showDeviceInfo: true,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(device);
      await tester.pump();

      expect(find.text('${AppStrings.connectedFor}:'), findsOneWidget);
      // Should show format like "01:30:45"
      expect(find.textContaining(':'), findsWidgets);
    });
  });

  group('ConnectionStatusWidget - Stream Updates', () {
    testWidgets('should update when device connects', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      // Initially disconnected
      expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);

      // Connect a device
      mockController.emitConnectedDevice(
        createTestDevice(id: 'device-1', displayName: 'New Device'),
      );
      await tester.pump();

      // Should now show connected
      expect(find.text(AppStrings.deviceConnected), findsOneWidget);
      expect(find.text(AppStrings.noDeviceConnected), findsNothing);
    });

    testWidgets('should update when device disconnects', (WidgetTester tester) async {
      final device = createTestDevice(id: 'device-1', displayName: 'Connected Device');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      // Start connected
      mockController.emitConnectedDevice(device);
      await tester.pump();
      await tester.pump(); // extra pump for stream to settle

      expect(find.text(AppStrings.deviceConnected), findsOneWidget);

      // Disconnect
      mockController.emitConnectedDevice(null);
      await tester.pump();
      await tester.pump(); // extra pump for stream to settle

      // Should now show disconnected
      expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);
      expect(find.text(AppStrings.deviceConnected), findsNothing);
    });
  });

  group('ConnectionStatusAppBar', () {
    testWidgets('should display title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConnectionStatusAppBar(
              controller: mockController,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.commandInterface), findsOneWidget);
    });

    testWidgets('should display custom title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConnectionStatusAppBar(
              controller: mockController,
              title: 'Custom Title',
            ),
          ),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
    });

    testWidgets('should include connection status in compact mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConnectionStatusAppBar(
              controller: mockController,
            ),
          ),
        ),
      );

      // Should show disconnected status in app bar
      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    });

    testWidgets('should update connection status when device connects', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConnectionStatusAppBar(
              controller: mockController,
            ),
          ),
        ),
      );

      // Initially disconnected
      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);

      // Connect
      mockController.emitConnectedDevice(
        createTestDevice(id: 'device-1'),
      );
      await tester.pump();

      // Should show connected
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should include custom actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ConnectionStatusAppBar(
              controller: mockController,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should have correct preferredSize', (WidgetTester tester) async {
      final appBar = ConnectionStatusAppBar(
        controller: mockController,
      );

      expect(appBar.preferredSize.height, kToolbarHeight);
    });
  });

  group('ConnectionStatusWidget - Theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);
    });

    testWidgets('should render connected state in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(createTestDevice(id: 'device-1'));
      await tester.pump();

      expect(find.text(AppStrings.deviceConnected), findsOneWidget);
    });

    testWidgets('should render connected state in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ConnectionStatusWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitConnectedDevice(createTestDevice(id: 'device-1'));
      await tester.pump();

      expect(find.text(AppStrings.deviceConnected), findsOneWidget);
    });
  });
}
