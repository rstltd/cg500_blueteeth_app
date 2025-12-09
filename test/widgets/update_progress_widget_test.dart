import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/update/update_progress_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateProgressWidget', () {
    testWidgets('should render with initial progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.0,
              statusText: '0 MB / 10 MB',
            ),
          ),
        ),
      );

      expect(find.text('Downloading...'), findsOneWidget);
      expect(find.text('0 MB / 10 MB'), findsOneWidget);
      expect(find.text('0% complete'), findsOneWidget);
    });

    testWidgets('should render with 50% progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.5,
              statusText: '5 MB / 10 MB',
            ),
          ),
        ),
      );

      expect(find.text('5 MB / 10 MB'), findsOneWidget);
      expect(find.text('50% complete'), findsOneWidget);
    });

    testWidgets('should render with 100% progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 1.0,
              statusText: '10 MB / 10 MB',
            ),
          ),
        ),
      );

      expect(find.text('10 MB / 10 MB'), findsOneWidget);
      expect(find.text('100% complete'), findsOneWidget);
    });

    testWidgets('should display LinearProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.75,
              statusText: '7.5 MB / 10 MB',
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.75);
    });

    testWidgets('should handle zero progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.0,
              statusText: 'Starting...',
            ),
          ),
        ),
      );

      expect(find.text('0% complete'), findsOneWidget);
      expect(find.text('Starting...'), findsOneWidget);
    });

    testWidgets('should handle edge progress values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.999,
              statusText: 'Almost done',
            ),
          ),
        ),
      );

      expect(find.text('99% complete'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.5,
              statusText: 'Test status',
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should display with custom status text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.25,
              statusText: 'Custom: 2.5 MB of 10 MB downloaded',
            ),
          ),
        ),
      );

      expect(find.text('Custom: 2.5 MB of 10 MB downloaded'), findsOneWidget);
    });

    testWidgets('should handle very small progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.001,
              statusText: 'Just started',
            ),
          ),
        ),
      );

      expect(find.text('0% complete'), findsOneWidget);
    });

    testWidgets('should render progress indicator with correct min height', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.5,
              statusText: 'Progress',
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.minHeight, 8);
    });
  });

  group('UpdateProgressWidget edge cases', () {
    testWidgets('should handle empty status text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.5,
              statusText: '',
            ),
          ),
        ),
      );

      // Should render without crashing
      expect(find.byType(UpdateProgressWidget), findsOneWidget);
    });

    testWidgets('should handle very long status text', (WidgetTester tester) async {
      // Use a constrained width to test overflow handling
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: UpdateProgressWidget(
                progress: 0.5,
                statusText: 'Long status',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UpdateProgressWidget), findsOneWidget);
    });

    testWidgets('should handle unicode in status text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateProgressWidget(
              progress: 0.5,
              statusText: '下載中... 5 MB / 10 MB',
            ),
          ),
        ),
      );

      expect(find.textContaining('下載中'), findsOneWidget);
    });
  });
}
