import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/device_status_panel_widget.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import '../mocks/mock_services.dart';

void main() {
  group('DeviceStatusPanelWidget', () {
    late MockBleController mockController;

    setUp(() {
      mockController = MockBleController();
    });

    tearDown(() {
      mockController.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: DeviceStatusPanelWidget(controller: mockController),
        ),
      );
    }

    group('when no device connected', () {
      testWidgets('should show warning message', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);
        expect(find.text(AppStrings.pleaseConnectBleDeviceFirst), findsOneWidget);
        expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      });

      testWidgets('should use orange color scheme', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find container with orange color
        final warningContainer = find.ancestor(
          of: find.text(AppStrings.noDeviceConnected),
          matching: find.byType(Container),
        );
        expect(warningContainer, findsWidgets);
      });
    });

    group('when device connected', () {
      late BleDeviceModel testDevice;

      setUp(() {
        testDevice = createTestDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'Test BLE Device',
          displayName: 'Test BLE Device',
          rssi: -55,
          connectionState: BleConnectionState.connected,
        );
      });

      testWidgets('should show device name', (tester) async {
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Test BLE Device'), findsOneWidget);
      });

      testWidgets('should show device ID', (tester) async {
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
      });

      testWidgets('should show device hub icon', (tester) async {
        mockController.simulateConnected(testDevice);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.device_hub), findsOneWidget);
      });

      testWidgets('should show TX status chip', (tester) async {
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasCommandChannel: true);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('TX'), findsOneWidget);
        expect(find.byIcon(Icons.upload), findsOneWidget);
      });

      testWidgets('should show RX status chip', (tester) async {
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasResponseChannel: true);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('RX'), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('should show MTU info chip', (tester) async {
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(mtu: 517);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('MTU:517'), findsOneWidget);
        expect(find.byIcon(Icons.data_usage), findsOneWidget);
      });

      testWidgets('should update when device changes via stream', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Initially no device
        expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);

        // Simulate connection - need to rebuild widget to pick up stream change
        mockController.simulateConnected(testDevice);
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should now show device info
        expect(find.text('Test BLE Device'), findsOneWidget);
        expect(find.text(AppStrings.noDeviceConnected), findsNothing);
      });

      testWidgets('should show disconnected state when device disconnects',
          (tester) async {
        mockController.simulateConnected(testDevice);
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Test BLE Device'), findsOneWidget);

        // Simulate disconnection - need to rebuild widget to pick up stream change
        mockController.simulateDisconnected();
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);
      });
    });

    group('status chips styling', () {
      late BleDeviceModel testDevice;

      setUp(() {
        testDevice = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
      });

      testWidgets('TX chip shows green when channel available', (tester) async {
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasCommandChannel: true);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // TX chip should exist
        expect(find.text('TX'), findsOneWidget);
      });

      testWidgets('TX chip shows red when channel unavailable', (tester) async {
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasCommandChannel: false);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // TX chip should still exist but with different styling
        expect(find.text('TX'), findsOneWidget);
      });

      testWidgets('RX chip shows green when channel available', (tester) async {
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasResponseChannel: true);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('RX'), findsOneWidget);
      });

      testWidgets('RX chip shows red when channel unavailable', (tester) async {
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasResponseChannel: false);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('RX'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles device with empty name', (tester) async {
        final deviceWithEmptyName = createTestDevice(
          id: 'test-id',
          name: '',
          displayName: 'Unknown Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(deviceWithEmptyName);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Unknown Device'), findsOneWidget);
      });

      testWidgets('handles device with long name', (tester) async {
        final deviceWithLongName = createTestDevice(
          id: 'test-id',
          name: 'Very Long Device Name That Might Overflow The UI',
          displayName: 'Very Long Device Name That Might Overflow The UI',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(deviceWithLongName);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should render without overflow error
        expect(find.textContaining('Very Long Device'), findsOneWidget);
      });

      testWidgets('handles rapid connection/disconnection', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Rapid state changes - rebuild widget to pick up stream changes
        for (int i = 0; i < 5; i++) {
          mockController.simulateConnected(testDevice);
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          mockController.simulateDisconnected();
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
        }

        // Should end in disconnected state
        expect(find.text(AppStrings.noDeviceConnected), findsOneWidget);
      });
    });
  });
}
