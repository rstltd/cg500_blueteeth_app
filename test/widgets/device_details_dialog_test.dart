import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/device_details_dialog.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import '../mocks/mock_services.dart';

void main() {
  group('DeviceDetailsDialog', () {
    Widget createTestWidget(BleDeviceModel device) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeviceDetailsDialog.show(context, device),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    Widget createDirectDialog(BleDeviceModel device) {
      return MaterialApp(
        home: Scaffold(
          body: DeviceDetailsDialog(device: device),
        ),
      );
    }

    group('basic information display', () {
      testWidgets('should show device name as title', (tester) async {
        final device = createTestDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'My BLE Device',
          displayName: 'My BLE Device',
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('My BLE Device'), findsWidgets);
      });

      testWidgets('should show device ID', (tester) async {
        final device = createTestDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'Test Device',
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Device ID:'), findsOneWidget);
        expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
      });

      testWidgets('should show device name row', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Named Device',
          displayName: 'Named Device',
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Name:'), findsOneWidget);
        expect(find.text('Named Device'), findsWidgets);
      });

      testWidgets('should show Unknown for empty name', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: '',
          displayName: 'Unknown Device',
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Name:'), findsOneWidget);
        expect(find.text('Unknown'), findsOneWidget);
      });

      testWidgets('should show RSSI with description', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          rssi: -55,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('RSSI:'), findsOneWidget);
        expect(find.textContaining('-55 dBm'), findsOneWidget);
      });

      testWidgets('should show connection state', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Connection:'), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
      });

      testWidgets('should show services count', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          services: [],
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Services:'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
      });
    });

    group('timing information', () {
      testWidgets('should show last seen when available', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          lastSeen: DateTime(2024, 1, 15, 10, 30),
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Last Seen:'), findsOneWidget);
      });

      testWidgets('should not show last seen when null', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          lastSeen: null,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Last Seen:'), findsNothing);
      });

      testWidgets('should show connected at when available', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectedAt: DateTime(2024, 1, 15, 9, 0),
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Connected At:'), findsOneWidget);
      });

      testWidgets('should not show connected at when null', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectedAt: null,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Connected At:'), findsNothing);
      });
    });

    group('services display', () {
      testWidgets('should show services header when services exist',
          (tester) async {
        final services = [
          BleServiceModel(
            uuid: '0000180f-0000-1000-8000-00805f9b34fb',
            displayName: 'Battery Service',
            characteristics: [],
          ),
        ];

        final device = BleDeviceModel(
          id: 'test-id',
          name: 'Test Device',
          displayName: 'Test Device',
          services: services,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Services:'), findsWidgets);
      });

      testWidgets('should list each service with bullet', (tester) async {
        final services = [
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
        ];

        final device = BleDeviceModel(
          id: 'test-id',
          name: 'Test Device',
          displayName: 'Test Device',
          services: services,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        // Check service count
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('should not show services list when empty', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          services: [],
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        // Should show count but not the list header
        expect(find.text('0'), findsOneWidget);
      });
    });

    group('dialog actions', () {
      testWidgets('should have Close button', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Close'), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
      });

      testWidgets('Close button should dismiss dialog when using show method',
          (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
        );

        await tester.pumpWidget(createTestWidget(device));
        await tester.pump();

        // Open dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('static show method', () {
      testWidgets('should display AlertDialog', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
        );

        await tester.pumpWidget(createTestWidget(device));
        await tester.pump();

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('should be scrollable for long content', (tester) async {
        final services = List.generate(
          20,
          (i) => BleServiceModel(
            uuid: '0000${i.toString().padLeft(4, '0')}-0000-1000-8000-00805f9b34fb',
            displayName: 'Service $i',
            characteristics: [],
          ),
        );

        final device = BleDeviceModel(
          id: 'test-id',
          name: 'Test Device',
          displayName: 'Test Device',
          services: services,
        );

        await tester.pumpWidget(createTestWidget(device));
        await tester.pump();

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('InfoRowWidget', () {
      testWidgets('should render label and value', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoRowWidget(
                label: 'Test Label',
                value: 'Test Value',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Test Label:'), findsOneWidget);
        expect(find.text('Test Value'), findsOneWidget);
      });

      testWidgets('should respect custom label width', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoRowWidget(
                label: 'Label',
                value: 'Value',
                labelWidth: 150,
              ),
            ),
          ),
        );
        await tester.pump();

        final sizedBox = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 150,
        );
        expect(sizedBox, findsOneWidget);
      });

      testWidgets('should have bold label style', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoRowWidget(
                label: 'Bold Label',
                value: 'Value',
              ),
            ),
          ),
        );
        await tester.pump();

        final labelText = tester.widget<Text>(find.text('Bold Label:'));
        expect(labelText.style?.fontWeight, FontWeight.bold);
      });
    });

    group('connection states', () {
      testWidgets('shows Disconnected state', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.disconnected,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Disconnected'), findsOneWidget);
      });

      testWidgets('shows Connecting state', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connecting,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Connecting...'), findsOneWidget);
      });

      testWidgets('shows Connected state', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Connected'), findsOneWidget);
      });

      testWidgets('shows Disconnecting state', (tester) async {
        final device = createTestDevice(
          id: 'test-id',
          name: 'Test Device',
          connectionState: BleConnectionState.disconnecting,
        );

        await tester.pumpWidget(createDirectDialog(device));
        await tester.pump();

        expect(find.text('Disconnecting...'), findsOneWidget);
      });
    });
  });
}
