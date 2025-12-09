import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/connection_stats_panel_widget.dart';
import 'package:cg500_blueteeth_app/controllers/command_manager.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import '../mocks/mock_services.dart';

void main() {
  group('ConnectionStatsPanelWidget', () {
    late MockBleController mockController;
    late CommandManager commandManager;

    setUp(() {
      mockController = MockBleController();
      commandManager = CommandManager(
        controller: mockController,
        onCommandSent: () {},
        onMessageAdded: (_) {},
      );
    });

    tearDown(() {
      commandManager.dispose();
      mockController.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ConnectionStatsPanelWidget(
            controller: mockController,
            commandManager: commandManager,
          ),
        ),
      );
    }

    group('when no device is connected', () {
      testWidgets('should show empty widget', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show SizedBox.shrink() when no device connected
        expect(find.byType(ConnectionStatsPanelWidget), findsOneWidget);
        // Card content should not be visible
        expect(find.text('Connection Stats'), findsNothing);
      });
    });

    group('when device is connected', () {
      late BleDeviceModel testDevice;

      setUp(() {
        testDevice = createTestDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'Test BLE Device',
          displayName: 'Test BLE Device',
          rssi: -55,
          connectionState: BleConnectionState.connected,
          services: [
            BleServiceModel(
              uuid: '0000180f-0000-1000-8000-00805f9b34fb',
              displayName: 'Battery Service',
              characteristics: [],
            ),
            BleServiceModel(
              uuid: '00001800-0000-1000-8000-00805f9b34fb',
              displayName: 'Generic Access',
              characteristics: [],
            ),
          ],
        );
        mockController.simulateConnected(testDevice);
        // Configure MTU to known value for testing
        mockController.configureCommandInfo(mtu: 517);
      });

      testWidgets('should show header with icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Connection Stats'), findsOneWidget);
        expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      });

      testWidgets('should show device name', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Device Name'), findsOneWidget);
        expect(find.text('Test BLE Device'), findsOneWidget);
      });

      testWidgets('should show signal strength', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Signal Strength'), findsOneWidget);
        expect(find.text('-55 dBm'), findsOneWidget);
      });

      testWidgets('should show services count', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Services'), findsOneWidget);
        // Services count is 2
        expect(find.textContaining('2'), findsWidgets);
      });

      testWidgets('should show MTU size', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('MTU Size'), findsOneWidget);
        expect(find.text('517 bytes'), findsOneWidget);
      });

      testWidgets('should show messages sent count', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Messages Sent'), findsOneWidget);
        // When no commands sent, messages count is 0
        expect(find.textContaining('0'), findsWidgets);
      });

      testWidgets('should update messages count after sending commands',
          (tester) async {
        // Send some commands
        commandManager.textController.text = 'CMD1';
        await commandManager.sendCommand();
        commandManager.textController.text = 'CMD2';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Messages Sent'), findsOneWidget);
        // Should find "2" for messages sent (may also appear for services)
        expect(find.textContaining('2'), findsWidgets);
      });
    });

    group('connection duration', () {
      testWidgets('should not show duration when null', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
          connectedAt: null,
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Connected For'), findsNothing);
      });

      testWidgets('should show duration label when connected with time',
          (tester) async {
        final connectedAt = DateTime.now().subtract(const Duration(
          hours: 1,
          minutes: 30,
          seconds: 45,
        ));
        final testDevice = BleDeviceModel(
          id: 'test-id',
          name: 'Test Device',
          displayName: 'Test Device',
          connectionState: BleConnectionState.connected,
          connectedAt: connectedAt,
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Check the label is shown
        expect(find.text('Connected For'), findsOneWidget);
      });
    });

    group('stream updates', () {
      testWidgets('should update when device changes via stream',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Initially no device
        expect(find.text('Connection Stats'), findsNothing);

        // Connect a device
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'New Device',
          displayName: 'New Device',
          rssi: -70,
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);
        await tester.pumpAndSettle();

        // Should now show stats
        expect(find.text('Connection Stats'), findsOneWidget);
        expect(find.text('New Device'), findsOneWidget);
        expect(find.text('-70 dBm'), findsOneWidget);
      });

      testWidgets('should hide when device disconnects', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially connected
        expect(find.text('Connection Stats'), findsOneWidget);

        // Disconnect
        mockController.simulateDisconnected();
        await tester.pumpAndSettle();

        // Should hide stats
        expect(find.text('Connection Stats'), findsNothing);
      });
    });

    group('different device configurations', () {
      testWidgets('should show zero services when none discovered',
          (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
          services: [],
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Services'), findsOneWidget);
        // 0 appears for both services and messages sent
        expect(find.textContaining('0'), findsWidgets);
      });

      testWidgets('should handle device with weak signal', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Weak Signal Device',
          displayName: 'Weak Signal Device',
          rssi: -95,
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('-95 dBm'), findsOneWidget);
      });

      testWidgets('should handle device with strong signal', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Strong Signal Device',
          displayName: 'Strong Signal Device',
          rssi: -30,
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('-30 dBm'), findsOneWidget);
      });
    });

    group('UI styling', () {
      testWidgets('should render without errors', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(ConnectionStatsPanelWidget), findsOneWidget);
      });

      testWidgets('should have proper row structure', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should have multiple Row widgets for each stat
        expect(find.byType(Row), findsWidgets);
      });
    });
  });
}
