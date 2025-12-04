import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/responsive_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResponsiveLayout', () {
    testWidgets('should display mobile widget on mobile screen', (WidgetTester tester) async {
      // Set mobile screen size (width < 600)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should display tablet widget on tablet screen', (WidgetTester tester) async {
      // Set tablet screen size (600 <= width < 1024)
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should display desktop widget on desktop screen', (WidgetTester tester) async {
      // Set desktop screen size (width >= 1024)
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
    });

    testWidgets('should fallback to mobile when tablet is null', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
    });

    testWidgets('should fallback to tablet then mobile when desktop is null', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('should fallback to mobile when both tablet and desktop are null', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
    });
  });

  group('ResponsiveContainer', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              child: Text('Container Content'),
            ),
          ),
        ),
      );

      expect(find.text('Container Content'), findsOneWidget);
    });

    testWidgets('should apply custom padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              padding: EdgeInsets.all(20),
              child: Text('Padded Content'),
            ),
          ),
        ),
      );

      expect(find.text('Padded Content'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, const EdgeInsets.all(20));
    });

    testWidgets('should apply custom margin', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Margined Content'),
            ),
          ),
        ),
      );

      expect(find.text('Margined Content'), findsOneWidget);
    });

    testWidgets('should apply custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              color: Colors.blue,
              child: const Text('Colored Content'),
            ),
          ),
        ),
      );

      expect(find.text('Colored Content'), findsOneWidget);
    });

    testWidgets('should apply custom decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Decorated Content'),
            ),
          ),
        ),
      );

      expect(find.text('Decorated Content'), findsOneWidget);
    });
  });

  group('ResponsiveCard', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should apply custom padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCard(
              padding: EdgeInsets.all(24),
              child: Text('Padded Card'),
            ),
          ),
        ),
      );

      expect(find.text('Padded Card'), findsOneWidget);
    });

    testWidgets('should apply custom elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCard(
              elevation: 8.0,
              child: Text('Elevated Card'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 8.0);
    });

    testWidgets('should apply custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveCard(
              color: Colors.amber,
              child: const Text('Colored Card'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, Colors.amber);
    });

    testWidgets('should apply custom shape', (WidgetTester tester) async {
      final customShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveCard(
              shape: customShape,
              child: const Text('Shaped Card'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.shape, customShape);
    });
  });

  group('ResponsiveGridView', () {
    testWidgets('should render children widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGridView(
              children: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('should apply custom child aspect ratio', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGridView(
              childAspectRatio: 2.0,
              children: const [
                Text('Wide Item'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should apply custom spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGridView(
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: const [
                Text('Spaced Item 1'),
                Text('Spaced Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should apply custom padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGridView(
              padding: const EdgeInsets.all(20),
              children: const [
                Text('Padded Grid'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should apply custom physics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGridView(
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                Text('Non-scrollable Grid'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('ResponsiveText', () {
    testWidgets('should render text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              'Hello World',
              fontSize: 16,
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('should apply font weight', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              'Bold Text',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Bold Text'));
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('should apply color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              'Colored Text',
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Colored Text'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('should apply text alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              'Centered Text',
              fontSize: 16,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Centered Text'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('should apply overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              'Ellipsis Text',
              fontSize: 16,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Ellipsis Text'));
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should apply max lines', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              'Multi-line Text',
              fontSize: 16,
              maxLines: 2,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Multi-line Text'));
      expect(text.maxLines, 2);
    });

    testWidgets('should apply custom style', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveText(
              'Styled Text',
              fontSize: 16,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Styled Text'));
      expect(text.style?.fontStyle, FontStyle.italic);
    });
  });

  group('ResponsiveIcon', () {
    testWidgets('should render icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveIcon(
              Icons.home,
              size: 24,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('should apply color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveIcon(
              Icons.star,
              size: 24,
              color: Colors.yellow,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, Colors.yellow);
    });
  });

  group('ResponsiveColumn', () {
    testWidgets('should render children in column on mobile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveColumn(
              children: [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('should apply main axis alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveColumn(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Centered Item'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Centered Item'), findsOneWidget);
    });

    testWidgets('should apply cross axis alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Aligned'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Start Aligned'), findsOneWidget);
    });

    testWidgets('should apply main axis size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveColumn(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Min Size'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Min Size'), findsOneWidget);
    });

    testWidgets('should render in row on large landscape screens with 2 children', (WidgetTester tester) async {
      // Set large landscape screen (width >= 1200, height < width)
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveColumn(
              children: [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      // On large landscape, it should use Row
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('ResponsiveSafeArea', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveSafeArea(
            child: Text('Safe Content'),
          ),
        ),
      );

      expect(find.text('Safe Content'), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should apply top safe area', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveSafeArea(
            top: true,
            bottom: false,
            left: false,
            right: false,
            child: Text('Top Safe'),
          ),
        ),
      );

      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
      expect(safeArea.top, true);
      expect(safeArea.bottom, false);
      expect(safeArea.left, false);
      expect(safeArea.right, false);
    });

    testWidgets('should apply all safe area edges by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveSafeArea(
            child: Text('All Safe'),
          ),
        ),
      );

      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
      expect(safeArea.top, true);
      expect(safeArea.bottom, true);
      expect(safeArea.left, true);
      expect(safeArea.right, true);
    });

    testWidgets('should disable specific edges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveSafeArea(
            top: false,
            bottom: false,
            child: Text('Side Safe Only'),
          ),
        ),
      );

      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
      expect(safeArea.top, false);
      expect(safeArea.bottom, false);
      expect(safeArea.left, true);
      expect(safeArea.right, true);
    });
  });
}
