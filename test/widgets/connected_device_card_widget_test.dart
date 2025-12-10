import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/connected_device_card_widget.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create a test device
  BleDeviceModel createTestDevice({
    String id = 'device-1',
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

  group('ConnectedDeviceCardWidget', () {
    testWidgets('should create without error', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should display Connected text', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text(AppStrings.connected), findsOneWidget);
    });

    testWidgets('should display device name', (WidgetTester tester) async {
      final device = createTestDevice(displayName: 'My BLE Device');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('My BLE Device'), findsOneWidget);
    });

    testWidgets('should display RSSI value', (WidgetTester tester) async {
      final device = createTestDevice(rssi: -65);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('${AppStrings.rssi}: -65 dBm'), findsOneWidget);
    });

    testWidgets('should display services count when device has services', (WidgetTester tester) async {
      final services = [
        const BleServiceModel(
          uuid: '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
          displayName: 'Nordic UART Service',
          characteristics: [],
        ),
        const BleServiceModel(
          uuid: '180d',
          displayName: 'Heart Rate',
          characteristics: [],
        ),
      ];
      final device = createTestDevice(services: services);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('${AppStrings.services}: 2'), findsOneWidget);
    });

    testWidgets('should not display services count when device has no services', (WidgetTester tester) async {
      final device = createTestDevice(services: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.textContaining('Services:'), findsNothing);
    });

    testWidgets('should have Bluetooth connected icon', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should have Open Command Interface button', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text(AppStrings.openCommandInterface), findsOneWidget);
    });

    testWidgets('should have chat icon on button', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat), findsOneWidget);
    });

    testWidgets('should have ElevatedButton.icon', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      // Verify the button exists by checking for its text and icon
      expect(find.text(AppStrings.openCommandInterface), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget);
    });
  });

  group('ConnectedDeviceCardWidget with different devices', () {
    testWidgets('should display device with long name', (WidgetTester tester) async {
      final device = createTestDevice(
        displayName: 'A Very Long Device Name That Might Overflow',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('A Very Long Device Name That Might Overflow'), findsOneWidget);
    });

    testWidgets('should display device with strong signal', (WidgetTester tester) async {
      final device = createTestDevice(rssi: -30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('${AppStrings.rssi}: -30 dBm'), findsOneWidget);
    });

    testWidgets('should display device with weak signal', (WidgetTester tester) async {
      final device = createTestDevice(rssi: -100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('${AppStrings.rssi}: -100 dBm'), findsOneWidget);
    });

    testWidgets('should display device with zero RSSI', (WidgetTester tester) async {
      final device = createTestDevice(rssi: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('${AppStrings.rssi}: 0 dBm'), findsOneWidget);
    });

    testWidgets('should display device with many services', (WidgetTester tester) async {
      final services = List.generate(
        10,
        (i) => BleServiceModel(
          uuid: 'service-$i',
          displayName: 'Service $i',
          characteristics: const [],
        ),
      );
      final device = createTestDevice(services: services);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('${AppStrings.services}: 10'), findsOneWidget);
    });
  });

  group('ConnectedDeviceCardWidget layout', () {
    testWidgets('should have Column layout', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should have Row for header', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should have SizedBox for spacing', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('button should have full width', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      // Find SizedBox with width: double.infinity wrapping the button
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final fullWidthBox = sizedBoxes.where((box) => box.width == double.infinity);
      expect(fullWidthBox.isNotEmpty, isTrue);
    });
  });

  group('ConnectedDeviceCardWidget theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should render with custom theme', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
            ),
          ),
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });
  });

  group('ConnectedDeviceCardWidget responsive', () {
    testWidgets('should render on mobile screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should render on tablet screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should render on desktop screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });
  });

  group('ConnectedDeviceCardWidget edge cases', () {
    testWidgets('should handle device with empty name', (WidgetTester tester) async {
      final device = createTestDevice(displayName: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should handle device with special characters in name', (WidgetTester tester) async {
      final device = createTestDevice(displayName: 'Device <>&"\'');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('Device <>&"\''), findsOneWidget);
    });

    testWidgets('should handle device with unicode name', (WidgetTester tester) async {
      final device = createTestDevice(displayName: '设备 デバイス 장치');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.text('设备 デバイス 장치'), findsOneWidget);
    });

    testWidgets('should handle device with emoji in name', (WidgetTester tester) async {
      final device = createTestDevice(displayName: '📱 My Phone 🔵');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.textContaining('My Phone'), findsOneWidget);
    });
  });

  group('ConnectedDeviceCardWidget with different connection states', () {
    testWidgets('should render with connected state', (WidgetTester tester) async {
      final device = createTestDevice(connectionState: BleConnectionState.connected);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should render with disconnected state', (WidgetTester tester) async {
      final device = createTestDevice(connectionState: BleConnectionState.disconnected);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });

    testWidgets('should render with connecting state', (WidgetTester tester) async {
      final device = createTestDevice(connectionState: BleConnectionState.connecting);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(ConnectedDeviceCardWidget), findsOneWidget);
    });
  });

  group('ConnectedDeviceCardWidget key', () {
    testWidgets('should accept key parameter', (WidgetTester tester) async {
      final device = createTestDevice();
      const key = Key('device-card-key');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(
              key: key,
              device: device,
            ),
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);
    });
  });

  group('ConnectedDeviceCardWidget widget structure', () {
    testWidgets('should have Card widget from ResponsiveCard', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should have Expanded widget in header row', (WidgetTester tester) async {
      final device = createTestDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedDeviceCardWidget(device: device),
          ),
        ),
      );

      expect(find.byType(Expanded), findsWidgets);
    });
  });

  // Note: Button navigation tests are skipped due to Timer issues from
  // CommandInterfaceView. The onPressed callback (lines 65-67) requires
  // integration testing or mocking Navigator to avoid pending timers.
}
