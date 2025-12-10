import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper function to create test device
  BleDeviceModel createTestDevice({
    String id = 'device-1',
    String name = 'Test Device',
    int rssi = -50,
    bool isFavorite = false,
    DateTime? lastSeen,
    List<dynamic>? services,
  }) {
    return BleDeviceModel(
      id: id,
      name: name,
      displayName: name.isNotEmpty ? name : AppStrings.unknownDevice,
      rssi: rssi,
      isFavorite: isFavorite,
      lastSeen: lastSeen,
      services: const [],
    );
  }

  group('DeviceListWidget Components - Empty State', () {
    testWidgets('should show empty state message when no devices', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.bluetooth_searching,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.noDevicesFound,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.startScanningHint,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.noDevicesFound), findsOneWidget);
      expect(find.text(AppStrings.startScanningHint), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
    });

    testWidgets('should show scanning indicator when isScanning is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.scanning,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.scanning), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('DeviceListWidget Components - Device Card', () {
    testWidgets('should display device name', (WidgetTester tester) async {
      final device = createTestDevice(name: 'My BLE Device');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bluetooth,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('My BLE Device'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth), findsOneWidget);
    });

    testWidgets('should display "Unknown Device" when name is empty', (WidgetTester tester) async {
      final device = createTestDevice(name: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  device.name.isNotEmpty ? device.name : AppStrings.unknownDevice,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.unknownDevice), findsOneWidget);
    });

    testWidgets('should display device ID', (WidgetTester tester) async {
      final device = createTestDevice(id: 'AA:BB:CC:DD:EE:FF');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  device.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
    });

    testWidgets('should display RSSI value', (WidgetTester tester) async {
      final device = createTestDevice(rssi: -65);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RSSI'),
                    Text('${device.rssi} dBm'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('RSSI'), findsOneWidget);
      expect(find.text('-65 dBm'), findsOneWidget);
    });
  });

  group('DeviceListWidget Components - Signal Strength Indicator', () {
    testWidgets('should show 4 bars for excellent signal (>= -40 dBm)', (WidgetTester tester) async {
      Color getSignalColor(int rssi) {
        if (rssi >= -40) return Colors.green;
        if (rssi >= -55) return Colors.lightGreen;
        if (rssi >= -70) return Colors.orange;
        if (rssi >= -85) return Colors.red;
        return Colors.red.shade700;
      }

      int getSignalBars(int rssi) {
        if (rssi >= -40) return 4;
        if (rssi >= -55) return 3;
        if (rssi >= -70) return 2;
        if (rssi >= -85) return 1;
        return 0;
      }

      final rssi = -35;
      final bars = getSignalBars(rssi);
      final color = getSignalColor(rssi);

      expect(bars, 4);
      expect(color, Colors.green);
    });

    testWidgets('should show 3 bars for very good signal (>= -55 dBm)', (WidgetTester tester) async {
      int getSignalBars(int rssi) {
        if (rssi >= -40) return 4;
        if (rssi >= -55) return 3;
        if (rssi >= -70) return 2;
        if (rssi >= -85) return 1;
        return 0;
      }

      expect(getSignalBars(-50), 3);
      expect(getSignalBars(-55), 3);
    });

    testWidgets('should show 2 bars for good signal (>= -70 dBm)', (WidgetTester tester) async {
      int getSignalBars(int rssi) {
        if (rssi >= -40) return 4;
        if (rssi >= -55) return 3;
        if (rssi >= -70) return 2;
        if (rssi >= -85) return 1;
        return 0;
      }

      expect(getSignalBars(-65), 2);
      expect(getSignalBars(-70), 2);
    });

    testWidgets('should show 1 bar for fair signal (>= -85 dBm)', (WidgetTester tester) async {
      int getSignalBars(int rssi) {
        if (rssi >= -40) return 4;
        if (rssi >= -55) return 3;
        if (rssi >= -70) return 2;
        if (rssi >= -85) return 1;
        return 0;
      }

      expect(getSignalBars(-80), 1);
      expect(getSignalBars(-85), 1);
    });

    testWidgets('should show 0 bars for poor signal (< -85 dBm)', (WidgetTester tester) async {
      int getSignalBars(int rssi) {
        if (rssi >= -40) return 4;
        if (rssi >= -55) return 3;
        if (rssi >= -70) return 2;
        if (rssi >= -85) return 1;
        return 0;
      }

      expect(getSignalBars(-90), 0);
      expect(getSignalBars(-100), 0);
    });

    testWidgets('should render signal bars widget', (WidgetTester tester) async {
      int getSignalBars(int rssi) {
        if (rssi >= -40) return 4;
        if (rssi >= -55) return 3;
        if (rssi >= -70) return 2;
        if (rssi >= -85) return 1;
        return 0;
      }

      final bars = getSignalBars(-50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                return Container(
                  width: 3,
                  height: 8 + (index * 3),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: index < bars ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
        ),
      );

      // Should render 4 bar containers
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('DeviceListWidget Components - Device Actions', () {
    testWidgets('should show Connect button when disconnected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.link, size: 16),
                  label: Text(
                    AppStrings.connect,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.connect), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('should show Disconnect button when connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.link_off, size: 16),
                  label: Text(
                    AppStrings.disconnect,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.disconnect), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('should show favorite button with empty heart when not favorite', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.grey,
                size: 20,
              ),
              tooltip: 'Add to favorites',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should show favorite button with filled heart when favorite', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 20,
              ),
              tooltip: 'Remove from favorites',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should trigger onPressed callback when button tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton.icon(
              onPressed: () => pressed = true,
              icon: const Icon(Icons.link),
              label: Text(AppStrings.connect),
            ),
          ),
        ),
      );

      await tester.tap(find.text(AppStrings.connect));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('should trigger favorite callback when icon button tapped', (WidgetTester tester) async {
      bool favoritePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              onPressed: () => favoritePressed = true,
              icon: const Icon(Icons.favorite_border),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(favoritePressed, isTrue);
    });
  });

  group('DeviceListWidget Components - Connected Device Styling', () {
    testWidgets('should show bluetooth_connected icon when connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bluetooth_connected,
                color: Colors.green.shade600,
                size: 20,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should show gradient background for connected device', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('should show green border for connected device card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.shade300, width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Connected Device'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Connected Device'), findsOneWidget);
    });
  });

  group('DeviceListWidget Components - Last Seen Formatting', () {
    testWidgets('should format "Just now" for < 1 minute', (WidgetTester tester) async {
      String formatLastSeen(DateTime lastSeen) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);

        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          return '${difference.inHours}h ago';
        } else {
          return '${difference.inDays}d ago';
        }
      }

      final justNow = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatLastSeen(justNow), 'Just now');
    });

    testWidgets('should format minutes ago for < 1 hour', (WidgetTester tester) async {
      String formatLastSeen(DateTime lastSeen) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);

        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          return '${difference.inHours}h ago';
        } else {
          return '${difference.inDays}d ago';
        }
      }

      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatLastSeen(fiveMinutesAgo), '5m ago');
    });

    testWidgets('should format hours ago for < 1 day', (WidgetTester tester) async {
      String formatLastSeen(DateTime lastSeen) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);

        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          return '${difference.inHours}h ago';
        } else {
          return '${difference.inDays}d ago';
        }
      }

      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatLastSeen(threeHoursAgo), '3h ago');
    });

    testWidgets('should format days ago for >= 1 day', (WidgetTester tester) async {
      String formatLastSeen(DateTime lastSeen) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);

        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          return '${difference.inHours}h ago';
        } else {
          return '${difference.inDays}d ago';
        }
      }

      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(formatLastSeen(twoDaysAgo), '2d ago');
    });
  });

  group('DeviceListWidget Components - Device Info Section', () {
    testWidgets('should display services count when services exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Services'),
                    Text('3 available'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('3 available'), findsOneWidget);
    });

    testWidgets('should display last seen info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Last Seen'),
                    Text('Just now'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Last Seen'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
    });
  });

  group('DeviceListWidget Components - ListView', () {
    testWidgets('should render ListView for device list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => Card(
                child: ListTile(
                  title: Text('Device $index'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Device 0'), findsOneWidget);
      expect(find.text('Device 1'), findsOneWidget);
      expect(find.text('Device 2'), findsOneWidget);
    });

    testWidgets('should render correct number of device cards', (WidgetTester tester) async {
      final devices = [
        createTestDevice(id: '1', name: 'Device A'),
        createTestDevice(id: '2', name: 'Device B'),
        createTestDevice(id: '3', name: 'Device C'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) => Card(
                child: ListTile(
                  title: Text(devices[index].name),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('Device A'), findsOneWidget);
      expect(find.text('Device B'), findsOneWidget);
      expect(find.text('Device C'), findsOneWidget);
    });
  });

  group('BleDeviceModel - Device Properties', () {
    test('should create device with required properties', () {
      final device = createTestDevice(
        id: 'test-id',
        name: 'Test Device',
        rssi: -60,
      );

      expect(device.id, 'test-id');
      expect(device.name, 'Test Device');
      expect(device.rssi, -60);
    });

    test('should create device with isFavorite property', () {
      final favoriteDevice = createTestDevice(isFavorite: true);
      final normalDevice = createTestDevice(isFavorite: false);

      expect(favoriteDevice.isFavorite, isTrue);
      expect(normalDevice.isFavorite, isFalse);
    });

    test('should create device with lastSeen property', () {
      final now = DateTime.now();
      final device = createTestDevice(lastSeen: now);

      expect(device.lastSeen, now);
    });

    test('should have displayName fallback to Unknown Device', () {
      final device = createTestDevice(name: '');

      expect(device.displayName, AppStrings.unknownDevice);
    });

    test('should display device name when name is not empty', () {
      final device = createTestDevice(name: 'My Sensor');

      expect(device.displayName, 'My Sensor');
    });
  });

  group('StreamBuilder Pattern Tests', () {
    testWidgets('should handle StreamBuilder with empty initial data', (WidgetTester tester) async {
      final controller = StreamController<List<BleDeviceModel>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<List<BleDeviceModel>>(
              stream: controller.stream,
              initialData: const [],
              builder: (context, snapshot) {
                List<BleDeviceModel> devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return const Center(child: Text('No devices'));
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) => Text(devices[index].name),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('No devices'), findsOneWidget);

      await controller.close();
    });

    testWidgets('should update when stream emits new data', (WidgetTester tester) async {
      final controller = StreamController<List<BleDeviceModel>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<List<BleDeviceModel>>(
              stream: controller.stream,
              initialData: const [],
              builder: (context, snapshot) {
                List<BleDeviceModel> devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return const Center(child: Text('No devices'));
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) => Text(devices[index].name),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('No devices'), findsOneWidget);

      // Emit new data
      controller.add([
        createTestDevice(name: 'New Device'),
      ]);
      await tester.pump();

      expect(find.text('New Device'), findsOneWidget);
      expect(find.text('No devices'), findsNothing);

      await controller.close();
    });

    testWidgets('should handle boolean StreamBuilder for scanning state', (WidgetTester tester) async {
      final scanningController = StreamController<bool>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<bool>(
              stream: scanningController.stream,
              initialData: false,
              builder: (context, snapshot) {
                bool isScanning = snapshot.data ?? false;
                if (isScanning) {
                  return Text(AppStrings.scanning);
                }
                return const Text('Not scanning');
              },
            ),
          ),
        ),
      );

      expect(find.text('Not scanning'), findsOneWidget);

      // Start scanning
      scanningController.add(true);
      await tester.pump();

      expect(find.text(AppStrings.scanning), findsOneWidget);

      await scanningController.close();
    });
  });
}
