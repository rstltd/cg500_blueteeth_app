import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:cg500_blueteeth_app/widgets/update/update_notification_banner.dart';
import 'package:cg500_blueteeth_app/controllers/update_controller.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import '../mocks/mock_services.dart';

/// Helper function to create test UpdateController with mock services
UpdateController createTestManager({
  MockUpdateService? updateService,
  MockNetworkService? networkService,
  MockNotificationService? notificationService,
}) {
  return UpdateController.withDependencies(
    updateService: updateService ?? MockUpdateService(),
    networkService: networkService ?? MockNetworkService(),
    notificationService: notificationService ?? MockNotificationService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create test manager with mock services
  late UpdateController updateManager;

  setUpAll(() {
    // Register mock services for testing
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<UpdateService>()) {
      getIt.registerSingleton<UpdateService>(MockUpdateService());
    }
    if (!getIt.isRegistered<NetworkService>()) {
      getIt.registerSingleton<NetworkService>(MockNetworkService());
    }
    if (!getIt.isRegistered<NotificationService>()) {
      getIt.registerSingleton<NotificationService>(MockNotificationService());
    }
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  setUp(() {
    updateManager = createTestManager();
  });

  group('UpdateNotificationBanner', () {
    testWidgets('should create without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should render as SizedBox.shrink when no update info',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When no update info, should render as empty
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should have required updateManager parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Verify widget created successfully with required parameter
      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should work within Column', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UpdateNotificationBanner(
                  updateManager: updateManager,
                ),
                const Text('Content below banner'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
      expect(find.text('Content below banner'), findsOneWidget);
    });

    testWidgets('should work within ListView', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                UpdateNotificationBanner(
                  updateManager: updateManager,
                ),
                const Text('Item 1'),
                const Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      // Widget may render as SizedBox.shrink if no update info
      // Just verify it doesn't crash and list items are present
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('should accept key parameter', (WidgetTester tester) async {
      const key = Key('update-banner-key');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              key: key,
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('should handle widget rebuild', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Rebuild the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should handle dispose and recreate',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Remove widget (triggers dispose)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsNothing);

      // Re-add widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });
  });

  group('UpdateNotificationBanner layout', () {
    testWidgets('should work in constrained space', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 100,
              child: UpdateNotificationBanner(
                updateManager: updateManager,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should work in expanded space', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: UpdateNotificationBanner(
                updateManager: updateManager,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should render on mobile screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should render on tablet screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should render on desktop screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });
  });

  group('UpdateNotificationBanner animation', () {
    testWidgets('should handle animation controller',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Pump a few frames for animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should handle pumpAndSettle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });
  });

  group('UpdateNotificationBanner edge cases', () {
    testWidgets('should handle rapid parent rebuilds',
        (WidgetTester tester) async {
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  UpdateNotificationBanner(
                    updateManager: updateManager,
                  ),
                  Text('Rebuild $i'),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
      }

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should handle multiple instances',
        (WidgetTester tester) async {
      // Note: This tests that multiple banner widgets can coexist
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UpdateNotificationBanner(
                  key: const Key('banner-1'),
                  updateManager: updateManager,
                ),
                UpdateNotificationBanner(
                  key: const Key('banner-2'),
                  updateManager: updateManager,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsNWidgets(2));
    });
  });

  group('UpdateNotificationBanner theming', () {
    testWidgets('should render with custom colorScheme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
            ),
          ),
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });

    testWidgets('should render with high contrast theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.highContrastLight(),
          ),
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateNotificationBanner), findsOneWidget);
    });
  });

  group('UpdateNotificationBanner state', () {
    testWidgets('should maintain state with GlobalKey',
        (WidgetTester tester) async {
      final key = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              key: key,
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Get the state
      final state1 = key.currentState;
      expect(state1, isNotNull);

      // Rebuild
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              key: key,
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // State should be same instance
      final state2 = key.currentState;
      expect(identical(state1, state2), true);
    });
  });

  group('UpdateController integration', () {
    test('UpdateController DI pattern creates independent instances', () {
      final instance1 = createTestManager();
      final instance2 = createTestManager();
      // With DI pattern, each call creates a new instance
      expect(identical(instance1, instance2), false);
    });

    test('UpdateController latestUpdateInfo should be nullable', () {
      final manager = UpdateController();
      // Initially should be null
      expect(manager.latestUpdateInfo, isNull);
    });

    test('UpdateController isCheckingForUpdates should be boolean', () {
      final manager = UpdateController();
      expect(manager.isCheckingForUpdates, isA<bool>());
    });

    test('UpdateController isInitialized should be boolean', () {
      final manager = UpdateController();
      expect(manager.isInitialized, isA<bool>());
    });

    test('UpdateController updateService should be accessible', () {
      final manager = UpdateController();
      expect(manager.updateService, isNotNull);
    });

    test('UpdateController networkService should be accessible', () {
      final manager = UpdateController();
      expect(manager.networkService, isNotNull);
    });

    test('UpdateController getCurrentVersionInfo should return map', () {
      final manager = UpdateController();
      final versionInfo = manager.getCurrentVersionInfo();
      expect(versionInfo, isA<Map<String, String>>());
    });

    test('UpdateController autoUpdatesEnabled should be boolean', () {
      final manager = UpdateController();
      expect(manager.autoUpdatesEnabled, isA<bool>());
    });

    test('UpdateController autoDownloadEnabled should be boolean', () {
      final manager = UpdateController();
      expect(manager.autoDownloadEnabled, isA<bool>());
    });
  });

  group('UpdateNotificationBanner string constants', () {
    testWidgets('should use AppStrings for update available title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // Verify AppStrings constants are defined correctly
      expect(AppStrings.updateAvailable, equals('有可用更新'));
    });

    testWidgets('should use AppStrings for important update title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // Verify AppStrings constants are defined correctly
      expect(AppStrings.importantUpdateAvailable, equals('重要更新可用'));
    });

    testWidgets('should use AppStrings for required update title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // Verify AppStrings constants are defined correctly
      expect(AppStrings.requiredUpdate, equals('必要更新'));
    });

    testWidgets('should use AppStrings for optional update title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // Verify AppStrings constants are defined correctly
      expect(AppStrings.optionalUpdate, equals('可選更新'));
    });

    testWidgets('should use AppStrings for update button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // Verify AppStrings constants are defined correctly
      expect(AppStrings.update, equals('更新'));
    });

    testWidgets('should use AppStrings for later button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // Verify AppStrings constants are defined correctly
      expect(AppStrings.later, equals('稍後'));
    });

    testWidgets('should use AppStrings for skip button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateManager: updateManager,
            ),
          ),
        ),
      );

      // Give time for async initialization
      await tester.pumpAndSettle();

      // Verify AppStrings constants are defined correctly
      expect(AppStrings.skip, equals('跳過'));
    });

    testWidgets('should verify all AppStrings constants used by UpdateNotificationBanner', (WidgetTester tester) async {
      // Verify that all constants used by UpdateNotificationBanner exist in AppStrings
      expect(AppStrings.updateAvailable, isNotNull);
      expect(AppStrings.importantUpdateAvailable, isNotNull);
      expect(AppStrings.requiredUpdate, isNotNull);
      expect(AppStrings.optionalUpdate, isNotNull);
      expect(AppStrings.update, isNotNull);
      expect(AppStrings.updateNow, isNotNull);
      expect(AppStrings.later, isNotNull);
      expect(AppStrings.skip, isNotNull);
      expect(AppStrings.close, isNotNull);

      // Verify the updateDescription function works
      final result = AppStrings.updateDescription('2.0.0');
      expect(result, contains('版本'));
      expect(result, contains('2.0.0'));
    });
  });
}
