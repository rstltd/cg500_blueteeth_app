import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/connected_device_card_widget.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BleDeviceModel createTestDevice({
    String id = 'AA:BB:CC:DD:EE:FF',
    String name = 'Test Device',
    String displayName = 'Test Device',
    int rssi = -50,
    List<BleServiceModel> services = const [],
    BleConnectionState connectionState = BleConnectionState.connected,
  }) {
    return BleDeviceModel(
      id: id,
      name: name,
      displayName: displayName,
      rssi: rssi,
      services: services,
      connectionState: connectionState,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    BleDeviceModel device,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectedDeviceCardWidget(device: device),
        ),
      ),
    );
  }

  group('ConnectedDeviceCardWidget', () {
    testWidgets('renders without error', (tester) async {
      await pumpCard(tester, createTestDevice());
      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('displays connected label', (tester) async {
      await pumpCard(tester, createTestDevice());
      expect(find.text(AppStrings.connected), findsOneWidget);
    });

    testWidgets('displays device name', (tester) async {
      await pumpCard(
        tester,
        createTestDevice(displayName: 'My BLE Device'),
      );
      expect(find.text('My BLE Device'), findsOneWidget);
    });

    testWidgets('displays device MAC', (tester) async {
      await pumpCard(
        tester,
        createTestDevice(id: '11:22:33:44:55:66'),
      );
      expect(find.text('11:22:33:44:55:66'), findsOneWidget);
    });

    testWidgets('shows bluetooth connected icon', (tester) async {
      await pumpCard(tester, createTestDevice());
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('does not render a command interface button', (tester) async {
      // The command interface is entered via the scanner AppBar filled
      // chat icon. This card is informational only.
      await pumpCard(tester, createTestDevice());
      expect(find.byIcon(Icons.chat), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('ConnectedDeviceCardWidget edge cases', () {
    testWidgets('handles long device name without crashing', (tester) async {
      await pumpCard(
        tester,
        createTestDevice(
          displayName: 'A Very Long Device Name That Might Overflow',
        ),
      );
      expect(
        find.text('A Very Long Device Name That Might Overflow'),
        findsOneWidget,
      );
    });

    testWidgets('handles unicode and emoji in name', (tester) async {
      await pumpCard(
        tester,
        createTestDevice(displayName: '📱 設備 デバイス 장치'),
      );
      expect(find.textContaining('設備'), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: createTestDevice()),
          ),
        ),
      );
      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });
  });
}
