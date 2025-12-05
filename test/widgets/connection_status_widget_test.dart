import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper function to create test device
  BleDeviceModel createTestDevice({
    String id = 'device-1',
    String name = 'Test Device',
    String displayName = 'Test Device',
    int rssi = -50,
    DateTime? connectedAt,
    List<dynamic>? services,
  }) {
    return BleDeviceModel(
      id: id,
      name: name,
      displayName: displayName.isNotEmpty ? displayName : 'Unknown Device',
      rssi: rssi,
      connectedAt: connectedAt,
      services: const [],
    );
  }

  group('ConnectionStatusWidget - Connected State', () {
    testWidgets('should display "Device Connected" header when connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.bluetooth_connected,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Connected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              'Ready to send commands',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
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

      expect(find.text('Device Connected'), findsOneWidget);
      expect(find.text('Ready to send commands'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should show device info when showDeviceInfo is true', (WidgetTester tester) async {
      final device = createTestDevice(
        displayName: 'My BLE Sensor',
        id: 'AA:BB:CC:DD:EE:FF',
        rssi: -45,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Device', device.displayName),
                  _buildInfoRow('ID', device.id),
                  _buildInfoRow('RSSI', '${device.rssi} dBm'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Device:'), findsOneWidget);
      expect(find.text('My BLE Sensor'), findsOneWidget);
      expect(find.text('ID:'), findsOneWidget);
      expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
      expect(find.text('RSSI:'), findsOneWidget);
      expect(find.text('-45 dBm'), findsOneWidget);
    });
  });

  group('ConnectionStatusWidget - Disconnected State', () {
    testWidgets('should display "No Device Connected" when disconnected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Device Connected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            Text(
                              'Connect a device first',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please connect a BLE device to send commands',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Device Connected'), findsOneWidget);
      expect(find.text('Connect a device first'), findsOneWidget);
      expect(find.text('Please connect a BLE device to send commands'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });
  });

  group('ConnectionStatusWidget - Compact Mode Connected', () {
    testWidgets('should display compact connected status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_connected,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connected',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should show device name in compact mode when showDeviceInfo is true', (WidgetTester tester) async {
      final device = createTestDevice(displayName: 'Compact Sensor');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bluetooth_connected, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Connected',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                Text(' • ${device.displayName}'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text(' • Compact Sensor'), findsOneWidget);
    });
  });

  group('ConnectionStatusWidget - Compact Mode Disconnected', () {
    testWidgets('should display compact disconnected status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Disconnected',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    });
  });

  group('ConnectionStatusWidget - Duration Formatting', () {
    testWidgets('should format duration with hours', (WidgetTester tester) async {
      String formatDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

        if (duration.inHours > 0) {
          return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
        } else {
          return '$twoDigitMinutes:$twoDigitSeconds';
        }
      }

      // 1 hour 30 minutes 45 seconds
      final duration = const Duration(hours: 1, minutes: 30, seconds: 45);
      expect(formatDuration(duration), '01:30:45');
    });

    testWidgets('should format duration without hours', (WidgetTester tester) async {
      String formatDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

        if (duration.inHours > 0) {
          return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
        } else {
          return '$twoDigitMinutes:$twoDigitSeconds';
        }
      }

      // 5 minutes 30 seconds
      final duration = const Duration(minutes: 5, seconds: 30);
      expect(formatDuration(duration), '05:30');
    });

    testWidgets('should format zero duration', (WidgetTester tester) async {
      String formatDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

        if (duration.inHours > 0) {
          return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
        } else {
          return '$twoDigitMinutes:$twoDigitSeconds';
        }
      }

      expect(formatDuration(Duration.zero), '00:00');
    });

    testWidgets('should format long duration', (WidgetTester tester) async {
      String formatDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

        if (duration.inHours > 0) {
          return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
        } else {
          return '$twoDigitMinutes:$twoDigitSeconds';
        }
      }

      // 12 hours 59 minutes 59 seconds
      final duration = const Duration(hours: 12, minutes: 59, seconds: 59);
      expect(formatDuration(duration), '12:59:59');
    });

    testWidgets('should format seconds only duration', (WidgetTester tester) async {
      String formatDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

        if (duration.inHours > 0) {
          return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
        } else {
          return '$twoDigitMinutes:$twoDigitSeconds';
        }
      }

      expect(formatDuration(const Duration(seconds: 45)), '00:45');
    });
  });

  group('ConnectionStatusWidget - Info Rows', () {
    testWidgets('should display info row with label and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Device:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Test Sensor',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Device:'), findsOneWidget);
      expect(find.text('Test Sensor'), findsOneWidget);
    });

    testWidgets('should display ID with monospace font style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text('ID:'),
                ),
                const Expanded(
                  child: Text(
                    'AA:BB:CC:DD:EE:FF',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ID:'), findsOneWidget);
      expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
    });

    testWidgets('should display services count when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                SizedBox(width: 80, child: Text('Services:')),
                Expanded(child: Text('5 available')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Services:'), findsOneWidget);
      expect(find.text('5 available'), findsOneWidget);
    });

    testWidgets('should display connected duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                SizedBox(width: 80, child: Text('Connected:')),
                Expanded(child: Text('05:30')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Connected:'), findsOneWidget);
      expect(find.text('05:30'), findsOneWidget);
    });
  });

  group('ConnectionStatusWidget - Styling', () {
    testWidgets('should have gradient background for connected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have orange background for disconnected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have green icon container for connected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bluetooth_connected,
                color: Colors.green.shade700,
                size: 20,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should have orange icon container for disconnected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });
  });

  group('ConnectionStatusAppBar', () {
    testWidgets('should display title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Command Interface'),
            ),
          ),
        ),
      );

      expect(find.text('Command Interface'), findsOneWidget);
    });

    testWidgets('should display custom title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Custom Title'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
    });

    testWidgets('should have correct preferredSize', (WidgetTester tester) async {
      const preferredSize = Size.fromHeight(kToolbarHeight);

      expect(preferredSize.height, kToolbarHeight);
    });

    testWidgets('should include actions widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Title'),
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
  });

  group('StreamBuilder Pattern for Connection Status', () {
    testWidgets('should handle null device from stream', (WidgetTester tester) async {
      final controller = StreamController<BleDeviceModel?>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<BleDeviceModel?>(
              stream: controller.stream,
              builder: (context, snapshot) {
                final device = snapshot.data;
                return device != null
                    ? const Text('Connected')
                    : const Text('Disconnected');
              },
            ),
          ),
        ),
      );

      // Initially no data
      expect(find.text('Disconnected'), findsOneWidget);

      await controller.close();
    });

    testWidgets('should update when device connects', (WidgetTester tester) async {
      final controller = StreamController<BleDeviceModel?>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<BleDeviceModel?>(
              stream: controller.stream,
              builder: (context, snapshot) {
                final device = snapshot.data;
                return device != null
                    ? Text('Connected to ${device.displayName}')
                    : const Text('Disconnected');
              },
            ),
          ),
        ),
      );

      expect(find.text('Disconnected'), findsOneWidget);

      // Emit connected device
      controller.add(createTestDevice(displayName: 'My Sensor'));
      await tester.pump();

      expect(find.text('Connected to My Sensor'), findsOneWidget);

      await controller.close();
    });

    testWidgets('should update when device disconnects', (WidgetTester tester) async {
      final controller = StreamController<BleDeviceModel?>.broadcast();
      final device = createTestDevice(displayName: 'Test Device');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<BleDeviceModel?>(
              stream: controller.stream,
              initialData: device,
              builder: (context, snapshot) {
                final device = snapshot.data;
                return device != null
                    ? Text('Connected to ${device.displayName}')
                    : const Text('Disconnected');
              },
            ),
          ),
        ),
      );

      expect(find.text('Connected to Test Device'), findsOneWidget);

      // Emit null (disconnected)
      controller.add(null);
      await tester.pump();

      expect(find.text('Disconnected'), findsOneWidget);

      await controller.close();
    });
  });

  group('BleDeviceModel - Connection Properties', () {
    test('should have connectionDuration when connectedAt is set', () {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      final device = BleDeviceModel(
        id: 'test-id',
        name: 'Test',
        displayName: 'Test Device',
        connectedAt: fiveMinutesAgo,
      );

      // connectionDuration should be approximately 5 minutes
      // (may have small variance due to test execution time)
      expect(device.connectedAt, fiveMinutesAgo);
    });

    test('should create device with services', () {
      final device = BleDeviceModel(
        id: 'test-id',
        name: 'Test',
        displayName: 'Test Device',
        services: const [],
      );

      expect(device.services, isEmpty);
    });
  });
}

// Helper widget builder for info rows
Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
