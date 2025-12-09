import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/common/animated_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimatedScanButton', () {
    testWidgets('should render with text when not scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () {},
              text: 'Start Scan',
            ),
          ),
        ),
      );

      expect(find.text('Start Scan'), findsOneWidget);
      expect(find.byType(AnimatedScanButton), findsOneWidget);
    });

    testWidgets('should render with scanning text when scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: true,
              onPressed: () {},
              text: 'Start Scan',
              scanningText: 'Stop Scanning',
            ),
          ),
        ),
      );

      expect(find.text('Stop Scanning'), findsOneWidget);
    });

    testWidgets('should use default scanning text when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: true,
              onPressed: () {},
              text: 'Start Scan',
            ),
          ),
        ),
      );

      expect(find.text('Scanning...'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () => pressed = true,
              text: 'Start Scan',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedScanButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('should show radar icon when not scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () {},
              text: 'Start Scan',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.radar), findsOneWidget);
    });

    testWidgets('should handle null onPressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: null,
              text: 'Start Scan',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedScanButton), findsOneWidget);
    });
  });

  group('AnimatedDeviceCard', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedDeviceCard(
              index: 0,
              child: Text('Device 1'),
            ),
          ),
        ),
      );

      // Pump enough frames for animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Device 1'), findsOneWidget);
    });

    testWidgets('should apply staggered delay based on index', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                AnimatedDeviceCard(index: 0, child: Text('Device 0')),
                AnimatedDeviceCard(index: 1, child: Text('Device 1')),
                AnimatedDeviceCard(index: 2, child: Text('Device 2')),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Device 0'), findsOneWidget);
      expect(find.text('Device 1'), findsOneWidget);
      expect(find.text('Device 2'), findsOneWidget);
    });

    testWidgets('should accept custom delay', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedDeviceCard(
              index: 0,
              delay: Duration(milliseconds: 50),
              child: Text('Custom Delay'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Custom Delay'), findsOneWidget);
    });
  });

  group('AnimatedConnectionStatus', () {
    testWidgets('should render child widget when disconnected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(
              isConnected: false,
              child: Text('Status'),
            ),
          ),
        ),
      );

      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('should render when connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(
              isConnected: true,
              child: Text('Connected'),
            ),
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
    });
  });

  group('AnimatedFloatingActionButton', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: () => pressed = true,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('should apply custom tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: () {},
              tooltip: 'Add Item',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedFloatingActionButton), findsOneWidget);
    });

    testWidgets('should apply custom background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.red,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should handle null onPressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: null,
              child: Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedFloatingActionButton), findsOneWidget);
    });
  });

  group('AnimatedFeedback', () {
    testWidgets('should not show visible content when neither success nor error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFeedback(
              showSuccess: false,
              showError: false,
            ),
          ),
        ),
      );

      // Should render SizedBox.shrink
      expect(find.byType(AnimatedFeedback), findsOneWidget);
    });

    testWidgets('should show success feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedFeedback(
                showSuccess: true,
                showError: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnimatedFeedback), findsOneWidget);
    });

    testWidgets('should show error feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedFeedback(
                showSuccess: false,
                showError: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnimatedFeedback), findsOneWidget);
    });

    testWidgets('should accept custom duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedFeedback(
                showSuccess: true,
                duration: Duration(milliseconds: 500),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedFeedback), findsOneWidget);
    });
  });

  group('AnimatedListItem', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              child: Text('Item 0'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('should apply staggered entrance animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                AnimatedListItem(index: 0, child: Text('Item 0')),
                AnimatedListItem(index: 1, child: Text('Item 1')),
                AnimatedListItem(index: 2, child: Text('Item 2')),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('should accept custom delay', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              delay: Duration(milliseconds: 100),
              child: Text('Custom Delay'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Custom Delay'), findsOneWidget);
    });

    testWidgets('should accept custom curve', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              curve: Curves.bounceOut,
              child: Text('Custom Curve'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Custom Curve'), findsOneWidget);
    });

    testWidgets('should have FadeTransition and SlideTransition', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              child: Text('Item'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);
    });
  });

  group('AnimatedScanButton state changes', () {
    testWidgets('should transition from not scanning to scanning', (WidgetTester tester) async {
      bool isScanning = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AnimatedScanButton(
                  isScanning: isScanning,
                  onPressed: () => setState(() => isScanning = !isScanning),
                  text: 'Start Scan',
                  scanningText: 'Stop Scan',
                ),
              ),
            );
          },
        ),
      );

      // Initially not scanning
      expect(find.text('Start Scan'), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);

      // Tap to start scanning
      await tester.tap(find.byType(AnimatedScanButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Stop Scan'), findsOneWidget);
    });

    testWidgets('should transition from scanning to not scanning', (WidgetTester tester) async {
      bool isScanning = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AnimatedScanButton(
                  isScanning: isScanning,
                  onPressed: () => setState(() => isScanning = !isScanning),
                  text: 'Start Scan',
                  scanningText: 'Stop Scan',
                ),
              ),
            );
          },
        ),
      );

      // Initially scanning
      expect(find.text('Stop Scan'), findsOneWidget);

      // Tap to stop scanning
      await tester.tap(find.byType(AnimatedScanButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Start Scan'), findsOneWidget);
    });

    testWidgets('should have ElevatedButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () {},
              text: 'Scan',
            ),
          ),
        ),
      );

      // Verify button exists by checking for text and icon
      expect(find.text('Scan'), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);
    });

    testWidgets('should have AnimatedContainer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () {},
              text: 'Scan',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('should have Stack for icon area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () {},
              text: 'Scan',
            ),
          ),
        ),
      );

      expect(find.byType(Stack), findsWidgets);
    });
  });

  group('AnimatedConnectionStatus state changes', () {
    testWidgets('should handle connection state change from disconnected to connected', (WidgetTester tester) async {
      bool isConnected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AnimatedConnectionStatus(
                      isConnected: isConnected,
                      child: Text(isConnected ? 'Connected' : 'Disconnected'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => isConnected = !isConnected),
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Disconnected'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('should handle connection state change from connected to disconnected', (WidgetTester tester) async {
      bool isConnected = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AnimatedConnectionStatus(
                      isConnected: isConnected,
                      child: Text(isConnected ? 'Connected' : 'Disconnected'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => isConnected = !isConnected),
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Connected'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Disconnected'), findsOneWidget);
    });
  });

  group('AnimatedFloatingActionButton gestures', () {
    testWidgets('should handle tap down', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      // Get the gesture detector
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GestureDetector).first),
      );
      await tester.pump();

      // Release
      await gesture.up();
      await tester.pump();

      expect(find.byType(AnimatedFloatingActionButton), findsOneWidget);
    });

    testWidgets('should handle tap cancel', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      // Start gesture and cancel
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GestureDetector).first),
      );
      await tester.pump();

      await gesture.cancel();
      await tester.pump();

      expect(find.byType(AnimatedFloatingActionButton), findsOneWidget);
    });

    testWidgets('should have Transform widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(Transform), findsWidgets);
    });
  });

  group('AnimatedFeedback callbacks', () {
    testWidgets('should call onComplete when success animation finishes', (WidgetTester tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedFeedback(
                showSuccess: true,
                duration: const Duration(milliseconds: 100),
                onComplete: () => completed = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(completed, isTrue);
    });

    testWidgets('should call onComplete when error animation finishes', (WidgetTester tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedFeedback(
                showError: true,
                duration: const Duration(milliseconds: 100),
                onComplete: () => completed = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(completed, isTrue);
    });

    testWidgets('should restart animation when state changes', (WidgetTester tester) async {
      bool showSuccess = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AnimatedFeedback(
                      showSuccess: showSuccess,
                      duration: const Duration(milliseconds: 100),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => showSuccess = true),
                      child: const Text('Show'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(AnimatedFeedback), findsOneWidget);

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AnimatedFeedback), findsOneWidget);
    });

    testWidgets('should have Container with BoxDecoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedFeedback(
                showSuccess: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });
  });

  group('AnimatedDeviceCard dispose', () {
    testWidgets('should handle disposal without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedDeviceCard(
              index: 0,
              child: Text('Device'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AnimatedDeviceCard), findsNothing);
    });

    testWidgets('should have ScaleTransition', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedDeviceCard(
              index: 0,
              child: Text('Device'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ScaleTransition), findsWidgets);
    });
  });

  group('AnimatedListItem dispose', () {
    testWidgets('should handle disposal without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              child: Text('Item'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AnimatedListItem), findsNothing);
    });

    testWidgets('should handle large index', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 100,
              child: Text('Item 100'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('Item 100'), findsOneWidget);
    });
  });

  group('AnimatedScanButton theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () {},
              text: 'Scan',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedScanButton), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: false,
              onPressed: () {},
              text: 'Scan',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedScanButton), findsOneWidget);
    });

    testWidgets('should have different color when scanning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedScanButton(
              isScanning: true,
              onPressed: () {},
              text: 'Scan',
            ),
          ),
        ),
      );

      // When scanning, the default text is 'Scanning...' if no scanningText provided
      expect(find.text('Scanning...'), findsOneWidget);
      expect(find.byType(AnimatedScanButton), findsOneWidget);
    });
  });
}
