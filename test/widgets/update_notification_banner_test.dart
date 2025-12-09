import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:cg500_blueteeth_app/widgets/update_notification_banner.dart';
import 'package:cg500_blueteeth_app/controllers/app_update_manager.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import '../mocks/mock_services.dart';

/// Helper function to create test AppUpdateManager with mock services
AppUpdateManager createTestManager({
  MockUpdateService? updateService,
  MockNetworkService? networkService,
  MockNotificationService? notificationService,
}) {
  return AppUpdateManager.withDependencies(
    updateService: updateService ?? MockUpdateService(),
    networkService: networkService ?? MockNetworkService(),
    notificationService: notificationService ?? MockNotificationService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create test manager with mock services
  late AppUpdateManager updateManager;

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

  group('AppUpdateManager integration', () {
    test('AppUpdateManager DI pattern creates independent instances', () {
      final instance1 = createTestManager();
      final instance2 = createTestManager();
      // With DI pattern, each call creates a new instance
      expect(identical(instance1, instance2), false);
    });

    test('AppUpdateManager latestUpdateInfo should be nullable', () {
      final manager = AppUpdateManager();
      // Initially should be null
      expect(manager.latestUpdateInfo, isNull);
    });

    test('AppUpdateManager isCheckingForUpdates should be boolean', () {
      final manager = AppUpdateManager();
      expect(manager.isCheckingForUpdates, isA<bool>());
    });

    test('AppUpdateManager isInitialized should be boolean', () {
      final manager = AppUpdateManager();
      expect(manager.isInitialized, isA<bool>());
    });

    test('AppUpdateManager updateService should be accessible', () {
      final manager = AppUpdateManager();
      expect(manager.updateService, isNotNull);
    });

    test('AppUpdateManager networkService should be accessible', () {
      final manager = AppUpdateManager();
      expect(manager.networkService, isNotNull);
    });

    test('AppUpdateManager getCurrentVersionInfo should return map', () {
      final manager = AppUpdateManager();
      final versionInfo = manager.getCurrentVersionInfo();
      expect(versionInfo, isA<Map<String, String>>());
    });

    test('AppUpdateManager autoUpdatesEnabled should be boolean', () {
      final manager = AppUpdateManager();
      expect(manager.autoUpdatesEnabled, isA<bool>());
    });

    test('AppUpdateManager autoDownloadEnabled should be boolean', () {
      final manager = AppUpdateManager();
      expect(manager.autoDownloadEnabled, isA<bool>());
    });
  });
}
