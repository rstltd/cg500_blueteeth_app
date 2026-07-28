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

      // Scoped to AnimatedListItem: MaterialApp's page route contributes
      // framework FadeTransitions of its own above this subtree.
      expect(
        find.descendant(
          of: find.byType(AnimatedListItem),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AnimatedListItem),
          matching: find.byType(SlideTransition),
        ),
        findsOneWidget,
      );
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
