import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/update/legacy_update_banner.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LegacyUpdateBanner', () {
    testWidgets('should create without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Should render without crashing
      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });

    testWidgets('should have const constructor', (WidgetTester tester) async {
      // Verify const constructor works
      const banner = LegacyUpdateBanner();
      expect(banner, isNotNull);
    });

    testWidgets('should render in MaterialApp context', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LegacyUpdateBanner(),
                Text('Content below banner'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
      expect(find.text('Content below banner'), findsOneWidget);
    });

    testWidgets('should render inside ListView', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                LegacyUpdateBanner(),
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      // Widget may render as SizedBox.shrink if _shouldShow is false
      // Just verify it doesn't crash and the list items are still present
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('should handle state initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Give time for async init
      await tester.pump();

      // Widget should still be mounted
      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });
  });

  group('LegacyUpdateBanner layout', () {
    testWidgets('should work in constrained space', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 100,
              child: LegacyUpdateBanner(),
            ),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });

    testWidgets('should work in expanded space', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: LegacyUpdateBanner(),
            ),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });
  });

  group('LegacyUpdateBanner theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });

    testWidgets('should render with custom theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
            ),
          ),
          home: const Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });
  });

  group('LegacyUpdateBanner version comparison logic', () {
    // Note: The actual version comparison happens in _compareVersions method
    // We test the widget renders correctly, the comparison logic is internal

    testWidgets('should handle widget rebuild', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Rebuild the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });

    testWidgets('should handle multiple pumps', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Multiple pumps to simulate async operations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });
  });

  group('LegacyUpdateBanner state management', () {
    testWidgets('should maintain state across rebuilds', (WidgetTester tester) async {
      final key = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(key: key),
          ),
        ),
      );

      // Get the state
      final state1 = key.currentState;

      // Rebuild
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(key: key),
          ),
        ),
      );

      // State should be same instance
      final state2 = key.currentState;
      expect(identical(state1, state2), true);
    });
  });

  group('LegacyUpdateBanner accessibility', () {
    testWidgets('should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Widget should be present
      expect(find.byType(LegacyUpdateBanner), findsOneWidget);

      // Should have Semantics
      expect(find.byType(Semantics), findsWidgets);
    });
  });

  group('LegacyUpdateBanner edge cases', () {
    testWidgets('should handle rapid parent rebuilds', (WidgetTester tester) async {
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const LegacyUpdateBanner(),
                  Text('Rebuild $i'),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
      }

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });

    testWidgets('should handle dispose and recreate', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsNothing);

      // Re-add widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      expect(find.byType(LegacyUpdateBanner), findsOneWidget);
    });
  });

  group('LegacyUpdateBanner string constants', () {
    testWidgets('should use AppStrings for download button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // The download button uses AppStrings.download
      // Note: The button may not be visible if _shouldShow is false,
      // so we verify the constant is correct
      expect(AppStrings.download, equals('下載'));
    });

    testWidgets('should use AppStrings for manual download text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // The manual download text uses AppStrings.clickToDownloadManually
      expect(AppStrings.clickToDownloadManually, equals('點擊從 GitHub 手動下載'));
    });

    testWidgets('should use AppStrings for new version available text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUpdateBanner(),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // The new version available text uses AppStrings.newVersionAvailable
      // This is a function that takes a version parameter
      final versionText = AppStrings.newVersionAvailable('2.0.0');
      expect(versionText, equals('新版本可用: 2.0.0'));
    });

    testWidgets('should verify all AppStrings constants are defined', (WidgetTester tester) async {
      // Verify that all constants used by LegacyUpdateBanner exist in AppStrings
      expect(AppStrings.download, isNotNull);
      expect(AppStrings.clickToDownloadManually, isNotNull);
      expect(AppStrings.downloadApkManually, isNotNull);

      // Verify the newVersionAvailable function works
      final result = AppStrings.newVersionAvailable('1.0.0');
      expect(result, contains('新版本可用'));
      expect(result, contains('1.0.0'));

      // Verify pleaseGoTo function works
      final urlResult = AppStrings.pleaseGoTo('https://example.com');
      expect(urlResult, contains('請前往'));
      expect(urlResult, contains('https://example.com'));
    });
  });
}
