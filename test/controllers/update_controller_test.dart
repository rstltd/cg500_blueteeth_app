import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/update_controller.dart';
import 'package:cg500_blueteeth_app/models/download_progress.dart';
import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/models/update_preferences.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/update_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_services.dart';

UpdateInfo _info({
  String latest = '2.0.0',
  String current = '1.0.0',
  bool forced = false,
}) {
  return UpdateInfo(
    latestVersion: latest,
    currentVersion: current,
    downloadUrl: 'https://example.com/app.apk',
    releaseNotes: 'Notes',
    isForced: forced,
    downloadSize: 1024 * 1024,
    releaseDate: DateTime(2026, 1, 1),
  );
}

/// [MockUpdateChecker] plus a call counter, so tests can prove how many
/// times the controller actually reached the checker. The counter lives
/// here instead of in the shared mock to keep `test/mocks/mock_services.dart`
/// untouched.
class _CountingUpdateChecker extends MockUpdateChecker {
  int checkCallCount = 0;

  @override
  Future<UpdateInfo?> checkForUpdates({
    List<String> skippedVersions = const [],
    UpdateChannel channel = UpdateChannel.stable,
  }) {
    checkCallCount++;
    return super.checkForUpdates(
      skippedVersions: skippedVersions,
      channel: channel,
    );
  }
}

UpdateController _newController({
  MockUpdateChecker? updateChecker,
  MockDownloadManager? downloadManager,
  MockInstallManager? installManager,
  UpdatePreferencesStore? preferencesStore,
  MockNetworkService? networkService,
  MockNotificationService? notificationService,
  MockUpdateUIDelegate? uiDelegate,
}) {
  return UpdateController.withDependencies(
    updateChecker: updateChecker ?? MockUpdateChecker(),
    downloadManager: downloadManager ?? MockDownloadManager(),
    installManager: installManager ?? MockInstallManager(),
    preferencesStore: preferencesStore ?? UpdatePreferencesStore(),
    networkService: networkService ?? MockNetworkService(),
    notificationService: notificationService ?? MockNotificationService(),
    uiDelegate: uiDelegate ?? MockUpdateUIDelegate(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The controller's initialize() loads UpdatePreferences from disk.
    // Provide an empty mock store so the load completes synchronously.
    SharedPreferences.setMockInitialValues({});
  });

  group('UpdateController', () {
    group('initialization', () {
      test('initialize returns true and flips isInitialized', () async {
        final controller = _newController();

        expect(controller.isInitialized, isFalse);

        final ok = await controller.initialize();

        expect(ok, isTrue);
        expect(controller.isInitialized, isTrue);
        controller.dispose();
      });

      test('initialize is idempotent', () async {
        final controller = _newController();
        await controller.initialize();
        final ok = await controller.initialize();

        expect(ok, isTrue);
        controller.dispose();
      });

      test('initialize snapshots current network status', () async {
        final network = MockNetworkService();
        network.mockStatus = NetworkStatus.mobile;

        final controller = _newController(networkService: network);
        await controller.initialize();

        expect(controller.networkStatus, NetworkStatus.mobile);
        controller.dispose();
      });

      test('notifyListeners fires on initialize', () async {
        final controller = _newController();
        var notified = 0;
        controller.addListener(() => notified++);

        await controller.initialize();

        expect(notified, greaterThan(0));
        controller.dispose();
      });
    });

    group('checkForUpdatesSilently', () {
      test('returns null when no update is pending', () async {
        final controller = _newController();
        await controller.initialize();

        final result = await controller.checkForUpdatesSilently();

        expect(result, isNull);
        expect(controller.latestUpdateInfo, isNull);
        controller.dispose();
      });

      test('caches latestUpdateInfo and notifies listeners', () async {
        final updateChecker = MockUpdateChecker();
        final controller = _newController(updateChecker: updateChecker);
        await controller.initialize();

        var notified = 0;
        controller.addListener(() => notified++);

        updateChecker.setPendingUpdate(_info());

        final result = await controller.checkForUpdatesSilently();

        expect(result, isNotNull);
        expect(controller.latestUpdateInfo, isNotNull);
        expect(controller.latestUpdateInfo!.latestVersion, '2.0.0');
        expect(notified, greaterThan(0));
        controller.dispose();
      });
    });

    group('checkForUpdatesWithUI without dialog context', () {
      test('falls back to info notification when update available', () async {
        final updateChecker = MockUpdateChecker();
        final notification = MockNotificationService();
        updateChecker.setPendingUpdate(_info());

        final controller = _newController(
          updateChecker: updateChecker,
          notificationService: notification,
        );
        await controller.initialize();

        await controller.checkForUpdatesWithUI();

        expect(
          notification.allNotifications.any((n) => n.message.contains('2.0.0')),
          isTrue,
        );
        controller.dispose();
      });

      test('showUpToDateMessage triggers success toast when no update',
          () async {
        final notification = MockNotificationService();
        final controller = _newController(notificationService: notification);
        await controller.initialize();
        notification.clear();

        await controller.checkForUpdatesWithUI(showUpToDateMessage: true);

        expect(
          notification.allNotifications.any((n) => n.title.contains('最新版')),
          isTrue,
        );
        controller.dispose();
      });

      test('concurrent calls are coalesced into a single checker call',
          () async {
        final updateChecker = _CountingUpdateChecker();
        final controller = _newController(updateChecker: updateChecker);
        await controller.initialize();

        final f1 = controller.checkForUpdatesWithUI();
        final f2 = controller.checkForUpdatesWithUI();

        await Future.wait([f1, f2]);

        expect(updateChecker.checkCallCount, 1);
        controller.dispose();
      });

      test('force=true bypasses the in-flight guard', () async {
        final updateChecker = _CountingUpdateChecker();
        final controller = _newController(updateChecker: updateChecker);
        await controller.initialize();

        final f1 = controller.checkForUpdatesWithUI();
        final f2 = controller.checkForUpdatesWithUI(force: true);

        await Future.wait([f1, f2]);

        expect(updateChecker.checkCallCount, 2);
        controller.dispose();
      });

      test('isCheckingForUpdates resets to false after completion', () async {
        final controller = _newController();
        await controller.initialize();

        await controller.checkForUpdatesWithUI();

        expect(controller.isCheckingForUpdates, isFalse);
        controller.dispose();
      });
    });

    group('download progress', () {
      testWidgets('progress events update downloadProgress and downloadStatus',
          (tester) async {
        final downloadManager = MockDownloadManager();
        final controller = _newController(downloadManager: downloadManager);
        await controller.initialize();

        downloadManager.configureDownload(
          progressSequence: [
            DownloadProgress(
              progress: 0.5,
              downloadedBytes: 500,
              totalBytes: 1000,
              status: 'Downloading',
              filePath: '/mock/app.apk',
            ),
            DownloadProgress(
              progress: 1.0,
              downloadedBytes: 1000,
              totalBytes: 1000,
              status: 'Complete',
              filePath: '/mock/app.apk',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  controller.startUpdate(_info(), ctx);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        expect(controller.downloadProgress, 1.0);
        // The reported status wins over the byte counter, so callers can
        // surface "Verifying" / "Download failed" instead of a size string.
        expect(controller.downloadStatus, 'Complete');
        controller.dispose();
      });

      testWidgets('startUpdate forwards wifiOnly preference to DownloadManager',
          (tester) async {
        final store = UpdatePreferencesStore();
        await store.load();
        await store.setWifiOnlyDownload(false);

        final downloadManager = MockDownloadManager();
        final controller = _newController(
          downloadManager: downloadManager,
          preferencesStore: store,
        );
        await controller.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  controller.startUpdate(_info(), ctx);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(downloadManager.wifiOnlyArgs, contains(false));
        controller.dispose();
      });
    });

    group('network changes', () {
      test('network status updates propagate and notify listeners', () async {
        final network = MockNetworkService();
        final controller = _newController(networkService: network);
        await controller.initialize();

        var notified = 0;
        controller.addListener(() => notified++);

        network.setStatus(NetworkStatus.mobile);
        await Future<void>.delayed(Duration.zero);

        expect(controller.networkStatus, NetworkStatus.mobile);
        expect(notified, greaterThan(0));
        controller.dispose();
      });
    });

    group('skipVersion', () {
      testWidgets('cancelled confirmation does not persist a skip',
          (tester) async {
        final store = UpdatePreferencesStore();
        await store.load();

        final ui = MockUpdateUIDelegate();
        ui.skipVersionConfirmationResult = false;

        final controller = _newController(
          preferencesStore: store,
          uiDelegate: ui,
        );
        await controller.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  controller.skipVersion(_info(), ctx, null);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(store.current!.skippedVersions, isEmpty);
        expect(ui.versionSkippedCalls, isEmpty);
        controller.dispose();
      });

      testWidgets(
          'confirmed: closes dialogs, persists skip, shows undo toast',
          (tester) async {
        final store = UpdatePreferencesStore();
        await store.load();

        final ui = MockUpdateUIDelegate();
        ui.skipVersionConfirmationResult = true;

        final controller = _newController(
          preferencesStore: store,
          uiDelegate: ui,
        );
        await controller.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  controller.skipVersion(_info(latest: '3.0.0'), ctx, null);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(store.current!.skippedVersions, contains('3.0.0'));
        // Only the parent update dialog needs closing — the confirmation
        // dialog already popped itself when the user chose "Skip".
        expect(ui.closeDialogsCalls, contains(1));
        expect(ui.versionSkippedCalls, contains('3.0.0'));
        controller.dispose();
      });
    });

    group('dispose', () {
      test('does NOT dispose injected services (no double-dispose)', () async {
        final downloadManager = MockDownloadManager();
        final network = MockNetworkService();

        final controller = _newController(
          downloadManager: downloadManager,
          networkService: network,
        );
        await controller.initialize();

        controller.dispose();

        // If the controller had disposed these, the next call would throw
        // because the underlying StreamControllers would already be closed.
        expect(() => downloadManager.dispose(), returnsNormally);
        expect(() => network.dispose(), returnsNormally);
      });

      test('isInitialized resets to false after dispose', () async {
        final controller = _newController();
        await controller.initialize();

        controller.dispose();

        expect(controller.isInitialized, isFalse);
      });
    });
  });
}
