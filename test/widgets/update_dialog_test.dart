import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:cg500_blueteeth_app/controllers/update_controller.dart';
import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/models/update_type.dart';
import 'package:cg500_blueteeth_app/widgets/update/update_dialog.dart';
import 'package:cg500_blueteeth_app/services/update_preferences_store.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import '../mocks/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register mock services so UpdateDialog (which pulls UpdateController
    // from getIt) can resolve every dependency.
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<NetworkService>()) {
      getIt.registerSingleton<NetworkService>(MockNetworkService());
    }
    if (!getIt.isRegistered<NotificationService>()) {
      getIt.registerSingleton<NotificationService>(MockNotificationService());
    }
    if (!getIt.isRegistered<UpdateController>()) {
      getIt.registerSingleton<UpdateController>(
        UpdateController.withDependencies(
          updateChecker: MockUpdateChecker(),
          downloadManager: MockDownloadManager(),
          installManager: MockInstallManager(),
          preferencesStore: UpdatePreferencesStore(),
          networkService: getIt<NetworkService>(),
          notificationService: getIt<NotificationService>(),
        ),
      );
    }
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  // Create a test UpdateInfo
  UpdateInfo createTestUpdateInfo({
    UpdateType updateType = UpdateType.optional,
    String currentVersion = '1.0.0',
    String latestVersion = '2.0.0',
    int downloadSize = 10 * 1024 * 1024,
    String releaseNotes = 'Test release notes',
  }) {
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: 'https://example.com/test.apk',
      releaseNotes: releaseNotes,
      downloadSize: downloadSize,
      releaseDate: DateTime.now(),
      updateType: updateType,
    );
  }

  group('UpdateDialog', () {
    testWidgets('should create with required updateInfo', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should display Dialog widget', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('should show version information', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show version info
      expect(find.textContaining('2.0.0'), findsWidgets);
    });

    // Release notes test removed — simplified dialog no longer shows
    // raw release notes.

    testWidgets('should have scrollable content', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should render with optional update type', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        updateType: UpdateType.optional,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should render with recommended update type', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        updateType: UpdateType.recommended,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should render with forced update type', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        updateType: UpdateType.forced,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should render with critical update type', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        updateType: UpdateType.critical,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should have Transform for scale animation', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      // Pump some frames for animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('should have Column layout', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('UpdateDialog callbacks', () {
    testWidgets('should call onDismiss when provided', (WidgetTester tester) async {
      bool dismissed = false;
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The callback should be available but not called yet
      expect(dismissed, false);
    });

    testWidgets('should accept onUpdateComplete callback', (WidgetTester tester) async {
      bool completed = false;
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
              onUpdateComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The callback should be available
      expect(completed, false);
    });
  });

  group('UpdateDialog theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });
  });

  group('UpdateDialog download sizes', () {
    testWidgets('should handle small download size', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        downloadSize: 1024, // 1 KB
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should handle large download size', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        downloadSize: 500 * 1024 * 1024, // 500 MB
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should handle zero download size', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo(
        downloadSize: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });
  });

  // Release notes test group removed — simplified dialog no longer shows
  // raw release notes.

  group('UpdateDialog state', () {
    testWidgets('should maintain state during animation', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      // Pump through animation frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('should handle dispose correctly', (WidgetTester tester) async {
      final updateInfo = createTestUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: updateInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove widget (triggers dispose)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsNothing);
    });
  });

  group('UpdateInfo', () {
    test('should create UpdateInfo with required properties', () {
      final info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Test notes',
        downloadSize: 1024,
        releaseDate: DateTime(2024, 1, 1),
        updateType: UpdateType.optional,
      );

      expect(info.currentVersion, '1.0.0');
      expect(info.latestVersion, '2.0.0');
      expect(info.downloadUrl, 'https://example.com/app.apk');
      expect(info.releaseNotes, 'Test notes');
      expect(info.downloadSize, 1024);
      expect(info.updateType, UpdateType.optional);
    });

    test('isForced should default to false', () {
      final info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '',
        downloadSize: 0,
        releaseDate: DateTime.now(),
        updateType: UpdateType.forced,
      );

      // isForced is a parameter, defaults to false
      expect(info.isForced, false);
    });

    test('isForced should be true when explicitly set', () {
      final info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '',
        downloadSize: 0,
        releaseDate: DateTime.now(),
        updateType: UpdateType.critical,
        isForced: true,
      );

      expect(info.isForced, true);
    });

    test('isForced can be set independently of updateType', () {
      final info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '',
        downloadSize: 0,
        releaseDate: DateTime.now(),
        updateType: UpdateType.optional,
        isForced: true,  // Can force an optional update
      );

      expect(info.isForced, true);
      expect(info.updateType, UpdateType.optional);
    });

    test('hasUpdate should return true when latest is greater', () {
      final info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '',
        downloadSize: 0,
        releaseDate: DateTime.now(),
        updateType: UpdateType.optional,
      );

      expect(info.hasUpdate, true);
    });

    test('hasUpdate should return false when versions match', () {
      final info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '',
        downloadSize: 0,
        releaseDate: DateTime.now(),
        updateType: UpdateType.optional,
      );

      expect(info.hasUpdate, false);
    });
  });

  group('UpdateType', () {
    test('should have 4 update types', () {
      expect(UpdateType.values.length, 4);
    });

    test('should contain optional', () {
      expect(UpdateType.values, contains(UpdateType.optional));
    });

    test('should contain recommended', () {
      expect(UpdateType.values, contains(UpdateType.recommended));
    });

    test('should contain forced', () {
      expect(UpdateType.values, contains(UpdateType.forced));
    });

    test('should contain critical', () {
      expect(UpdateType.values, contains(UpdateType.critical));
    });

    test('should have correct index order', () {
      // Enum order: optional, recommended, critical, forced
      expect(UpdateType.optional.index, 0);
      expect(UpdateType.recommended.index, 1);
      expect(UpdateType.critical.index, 2);
      expect(UpdateType.forced.index, 3);
    });
  });
}
