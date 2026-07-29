import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:cg500_blueteeth_app/widgets/update/update_notification_banner.dart';
import 'package:cg500_blueteeth_app/controllers/update_controller.dart';
import 'package:cg500_blueteeth_app/services/update_checker.dart';
import 'package:cg500_blueteeth_app/services/download_manager.dart';
import 'package:cg500_blueteeth_app/services/install_manager.dart';
import 'package:cg500_blueteeth_app/services/update_preferences_store.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/models/update_type.dart';
import '../mocks/mock_services.dart';

/// Helper function to create test UpdateController with mock services
UpdateController createTestManager({
  MockUpdateChecker? updateChecker,
  MockDownloadManager? downloadManager,
  MockInstallManager? installManager,
  UpdatePreferencesStore? preferencesStore,
  MockNetworkService? networkService,
  MockNotificationService? notificationService,
}) {
  return UpdateController.withDependencies(
    updateChecker: updateChecker ?? MockUpdateChecker(),
    downloadManager: downloadManager ?? MockDownloadManager(),
    installManager: installManager ?? MockInstallManager(),
    preferencesStore: preferencesStore ?? UpdatePreferencesStore(),
    networkService: networkService ?? MockNetworkService(),
    notificationService: notificationService ?? MockNotificationService(),
  );
}

/// Builds a minimal but valid [UpdateInfo] for tests that need the banner
/// to actually render its "update available" content instead of collapsing
/// to `SizedBox.shrink()`.
UpdateInfo _makeUpdateInfo({
  String version = '26.08.0',
  UpdateType type = UpdateType.recommended,
  bool isForced = false,
}) {
  return UpdateInfo(
    latestVersion: version,
    currentVersion: '26.07.0',
    downloadUrl: 'https://example.com/app.apk',
    downloadSize: 1024,
    releaseNotes: 'Test release notes',
    isForced: isForced,
    updateType: type,
    releaseDate: DateTime(2026, 7, 1),
  );
}

Widget _wrapBanner(UpdateController manager) {
  return MaterialApp(
    home: Scaffold(
      body: UpdateNotificationBanner(updateManager: manager),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create test manager with mock services
  late UpdateController updateManager;

  setUpAll(() {
    // Register mock services so the default UpdateController() constructor
    // (which pulls every dependency from getIt) can resolve.
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<UpdateChecker>()) {
      getIt.registerSingleton<UpdateChecker>(MockUpdateChecker());
    }
    if (!getIt.isRegistered<DownloadManager>()) {
      getIt.registerSingleton<DownloadManager>(MockDownloadManager());
    }
    if (!getIt.isRegistered<InstallManager>()) {
      getIt.registerSingleton<InstallManager>(MockInstallManager());
    }
    if (!getIt.isRegistered<UpdatePreferencesStore>()) {
      getIt.registerSingleton<UpdatePreferencesStore>(UpdatePreferencesStore());
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

    test('UpdateController preferencesStore should be accessible', () {
      final manager = UpdateController();
      expect(manager.preferencesStore, isNotNull);
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

  // The 726 lines above this point only ever exercise the banner with
  // `latestUpdateInfo == null`, so the entire "banner is actually visible"
  // path — including the ListenableBuilder rebuild and the post-frame
  // slide-in reveal introduced by the rewrite — has zero coverage. These
  // groups fill that gap.
  group('UpdateNotificationBanner visible state', () {
    testWidgets(
        'shows the banner content once latestUpdateInfo becomes available',
        (WidgetTester tester) async {
      final info = _makeUpdateInfo(
        version: '26.08.0',
        type: UpdateType.recommended,
      );
      final checker = MockUpdateChecker()..setPendingUpdate(info);
      final manager = createTestManager(updateChecker: checker);

      await tester.pumpWidget(_wrapBanner(manager));

      // No update known yet: banner must be collapsed.
      expect(find.text(AppStrings.updateAvailable), findsNothing);

      await manager.checkForUpdatesSilently();
      await tester.pump();

      // Recommended (non-forced) update: title, version text, dismiss (X)
      // button and the "Update" (not "Update Now") button should all be
      // present.
      expect(find.text(AppStrings.updateAvailable), findsOneWidget);
      expect(find.textContaining('26.08.0'), findsOneWidget);
      expect(find.text(AppStrings.update), findsOneWidget);
      expect(find.text(AppStrings.updateNow), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
    });

    testWidgets(
        'shows "Update Now" and hides the dismiss button for a forced update',
        (WidgetTester tester) async {
      final info = _makeUpdateInfo(
        version: '26.09.0',
        type: UpdateType.forced,
        isForced: true,
      );
      final checker = MockUpdateChecker()..setPendingUpdate(info);
      final manager = createTestManager(updateChecker: checker);

      await tester.pumpWidget(_wrapBanner(manager));
      await manager.checkForUpdatesSilently();
      await tester.pump();

      expect(find.text(AppStrings.updateNow), findsOneWidget);
      expect(find.text(AppStrings.update), findsNothing);
      // Forced updates must not offer a dismiss button.
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
        'banner disappears once the controller clears latestUpdateInfo (skip flow)',
        (WidgetTester tester) async {
      final info = _makeUpdateInfo(version: '26.10.0');
      final checker = MockUpdateChecker()..setPendingUpdate(info);
      final uiDelegate = MockUpdateUIDelegate()
        ..skipVersionConfirmationResult = true;
      final manager = UpdateController.withDependencies(
        updateChecker: checker,
        downloadManager: MockDownloadManager(),
        installManager: MockInstallManager(),
        preferencesStore: UpdatePreferencesStore(),
        networkService: MockNetworkService(),
        notificationService: MockNotificationService(),
        uiDelegate: uiDelegate,
      );

      await tester.pumpWidget(_wrapBanner(manager));
      await manager.checkForUpdatesSilently();
      await tester.pump();

      expect(find.text(AppStrings.updateAvailable), findsOneWidget);
      expect(manager.latestUpdateInfo, isNotNull);

      // Drive the real skip-version flow (this is the exact scenario the
      // rewrite fixes: skipping a version must make the banner vanish and
      // must not let it push the just-skipped version back at the user).
      final context = tester.element(find.byType(Scaffold));
      await manager.skipVersion(info, context, null);
      await tester.pump();

      expect(manager.latestUpdateInfo, isNull);
      expect(find.text(AppStrings.updateAvailable), findsNothing);
      expect(find.textContaining('26.10.0'), findsNothing);
    });

    testWidgets(
        'slide-in animation advances the banner into place after the reveal callback fires',
        (WidgetTester tester) async {
      final info = _makeUpdateInfo();
      final checker = MockUpdateChecker()..setPendingUpdate(info);
      final manager = createTestManager(updateChecker: checker);

      await tester.pumpWidget(_wrapBanner(manager));
      await manager.checkForUpdatesSilently();

      // This single pump both (a) rebuilds the banner now that
      // latestUpdateInfo is non-null, which schedules the post-frame reveal
      // callback, and (b) — because Flutter runs scheduled post-frame
      // callbacks at the end of the very same frame — executes that
      // callback, which calls AnimationController.forward(). The ticker
      // itself has not advanced yet, so the banner should still be sitting
      // at its off-screen starting position.
      await tester.pump();

      final titleFinder = find.text(AppStrings.updateAvailable);
      expect(titleFinder, findsOneWidget);
      final startY = tester.getTopLeft(titleFinder).dy;

      // The underlying Ticker stamps its own start time on its first
      // subsequent tick, so the very next pump reports zero elapsed time
      // and the banner does not appear to move yet; it only primes the
      // ticker's baseline for the pump after it.
      await tester.pump(const Duration(milliseconds: 10));

      // With a real baseline established, elapsing further time now
      // actually drives the animation forward.
      await tester.pump(const Duration(milliseconds: 140));
      final midY = tester.getTopLeft(titleFinder).dy;
      expect(
        midY,
        greaterThan(startY),
        reason:
            'slide-in animation should have moved the banner toward its resting position by ~150ms',
      );

      // Let the animation finish.
      await tester.pumpAndSettle();
      final endY = tester.getTopLeft(titleFinder).dy;
      expect(endY, greaterThan(midY));
    });

    testWidgets(
        'does not throw when the widget is torn down before a pending update notification is rendered',
        (WidgetTester tester) async {
      final info = _makeUpdateInfo();
      final checker = MockUpdateChecker()..setPendingUpdate(info);
      final manager = createTestManager(updateChecker: checker);

      await tester.pumpWidget(_wrapBanner(manager));

      // checkForUpdatesSilently() calls notifyListeners() synchronously,
      // which marks the banner's ListenableBuilder dirty — but nothing has
      // pumped a frame yet, so the rebuild (and the post-frame reveal
      // callback it would schedule) is still only "pending".
      await manager.checkForUpdatesSilently();

      // Tear the whole tree down (worst case for the addPostFrameCallback
      // pattern: the widget is gone before its pending, update-triggered
      // rebuild/reveal ever gets a chance to run).
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);

      // Pump a few more frames in case anything was left scheduled; must
      // not throw even though the State that would have handled it is
      // long disposed.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'local dismissal persists even when the controller notifies again with the same update',
        (WidgetTester tester) async {
      final info = _makeUpdateInfo(version: '26.11.0');
      final checker = MockUpdateChecker()..setPendingUpdate(info);
      final manager = createTestManager(updateChecker: checker);

      await tester.pumpWidget(_wrapBanner(manager));
      await manager.checkForUpdatesSilently();
      await tester.pump();

      expect(find.text(AppStrings.updateAvailable), findsOneWidget);

      // Tap the close (X) button: _dismissBanner() reverses the animation
      // and then sets the widget-local `_isDismissed` flag.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.updateAvailable), findsNothing);

      // Simulate a background re-check that finds the same update still
      // available (the MockUpdateChecker still has the same pending info)
      // and notifies listeners again.
      await manager.checkForUpdatesSilently();
      await tester.pump();
      await tester.pumpAndSettle();

      // The controller itself does not know the banner was dismissed
      // locally, so latestUpdateInfo is still set...
      expect(manager.latestUpdateInfo, isNotNull);
      // ...but the widget-local dismissal must stick: the banner must not
      // resurrect itself.
      expect(find.text(AppStrings.updateAvailable), findsNothing);
    });
  });
}
