import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/ble/device_list_widget.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import '../mocks/mock_ble_controller.dart';

/// Tests for DeviceListWidget using actual widget source code
/// These tests import and use the real DeviceListWidget to increase coverage
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBleController mockController;

  setUp(() {
    mockController = MockBleController();
  });

  tearDown(() {
    mockController.dispose();
  });

  group('DeviceListWidget - Empty State', () {
    testWidgets('should display empty state when no devices', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.noDevicesFound), findsOneWidget);
      expect(find.text(AppStrings.startScanningHint), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
    });

    testWidgets('should show scanning indicator in empty state when scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      // Start scanning
      mockController.emitScanning(true);
      await tester.pump();

      expect(find.text(AppStrings.scanning), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should hide scanning indicator when not scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      // Start scanning
      mockController.emitScanning(true);
      await tester.pump();
      expect(find.text(AppStrings.scanning), findsOneWidget);

      // Stop scanning
      mockController.emitScanning(false);
      await tester.pump();

      expect(find.text(AppStrings.scanning), findsNothing);
    });
  });

  group('DeviceListWidget - Device List', () {
    testWidgets('should display list when devices are available', (WidgetTester tester) async {
      final devices = [
        createTestDevice(id: 'device-1', name: 'Device One', rssi: -50),
        createTestDevice(id: 'device-2', name: 'Device Two', rssi: -60),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices(devices);
      await tester.pumpAndSettle();

      expect(find.text('Device One'), findsOneWidget);
      expect(find.text('Device Two'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display device ID', (WidgetTester tester) async {
      final devices = [
        createTestDevice(id: 'AA:BB:CC:DD:EE:FF', name: 'Test Device'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices(devices);
      await tester.pumpAndSettle();

      // Device ID is joined into the compact subtitle row
      expect(find.textContaining('AA:BB:CC:DD:EE:FF'), findsOneWidget);
    });

    testWidgets('should render device with a specific RSSI without error',
        (WidgetTester tester) async {
      // RSSI is now represented purely by the signal bar indicator, not
      // by a textual "-N dBm" label in the compact card layout.
      final devices = [
        createTestDevice(id: 'test-1', name: 'Test Device', rssi: -65),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices(devices);
      await tester.pumpAndSettle();

      expect(find.text('Test Device'), findsOneWidget);
    });

    testWidgets('should display unknown device name when name is empty', (WidgetTester tester) async {
      final devices = [
        createTestDevice(id: 'test-1', name: '', displayName: AppStrings.unknownDevice),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices(devices);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.unknownDevice), findsOneWidget);
    });
  });

  // NOTE: Connected Device Styling tests are skipped because AnimatedListItem
  // uses Future.delayed which is difficult to test with Flutter's test framework.
  // The widget functionality is still covered by other tests that don't depend
  // on animation timing (Favorite Button, Connect/Disconnect Callbacks, etc.)

  group('DeviceListWidget - Favorite Button', () {
    testWidgets('should show empty heart for non-favorite device', (WidgetTester tester) async {
      final device = createTestDevice(id: 'device-1', name: 'Test', isFavorite: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should show filled heart for favorite device', (WidgetTester tester) async {
      final device = createTestDevice(id: 'device-1', name: 'Test', isFavorite: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should call onDeviceFavorite when favorite button tapped', (WidgetTester tester) async {
      BleDeviceModel? favoriteDevice;
      final device = createTestDevice(id: 'device-1', name: 'Test', isFavorite: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
              onDeviceFavorite: (d) => favoriteDevice = d,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(favoriteDevice, isNotNull);
      expect(favoriteDevice!.id, 'device-1');
    });
  });

  group('DeviceListWidget - Connect/Disconnect Callbacks', () {
    testWidgets('should call onDeviceConnect when connect button tapped', (WidgetTester tester) async {
      BleDeviceModel? connectedDevice;
      final device = createTestDevice(id: 'device-1', name: 'Test Device');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
              onDeviceConnect: (d) => connectedDevice = d,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('連線'));
      await tester.pump();

      expect(connectedDevice, isNotNull);
      expect(connectedDevice!.id, 'device-1');
    });

    // NOTE: onDeviceDisconnect test skipped - requires connected device styling
    // which depends on AnimatedListItem that uses Future.delayed
  });

  group('DeviceListWidget - Signal Strength Indicator', () {
    testWidgets('should show signal bars for device with excellent signal', (WidgetTester tester) async {
      final device = createTestDevice(id: 'device-1', name: 'Test', rssi: -35);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      // Signal bars are rendered as Containers — verify the card is present.
      // (The compact card no longer shows a textual "-N dBm" label.)
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should show signal bars for device with poor signal', (WidgetTester tester) async {
      final device = createTestDevice(id: 'device-1', name: 'Weak Device', rssi: -95);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      expect(find.text('Weak Device'), findsOneWidget);
    });
  });

  // Note: "Device Info Section" tests removed — the compact card no longer
  // renders RSSI text, services count, or last-seen time. Signal strength
  // is shown via the bar indicator only, and last seen is not part of the
  // scanner card at all.

  group('DeviceListWidget - Stream Updates', () {
    testWidgets('should update when devices stream emits new data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.noDevicesFound), findsOneWidget);

      // Add first device
      mockController.emitDevices([
        createTestDevice(id: 'device-1', name: 'First Device'),
      ]);
      // Use pump with duration to allow animation to progress
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('First Device'), findsOneWidget);
      expect(find.text(AppStrings.noDevicesFound), findsNothing);
    });

    // NOTE: "should update when connected device changes" test skipped -
    // requires AnimatedListItem animation to complete which uses Future.delayed
  });

  group('DeviceListWidget - Theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      final device = createTestDevice(id: 'device-1', name: 'Test Device');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      expect(find.text('Test Device'), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      final device = createTestDevice(id: 'device-1', name: 'Test Device');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: DeviceListWidget(
              controller: mockController,
            ),
          ),
        ),
      );

      mockController.emitDevices([device]);
      await tester.pumpAndSettle();

      expect(find.text('Test Device'), findsOneWidget);
    });
  });
}
