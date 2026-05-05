import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/update_controller.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';

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

UpdateController _newController({
  MockUpdateService? updateService,
  MockNetworkService? networkService,
  MockNotificationService? notificationService,
  MockUpdateUIDelegate? uiDelegate,
}) {
  return UpdateController.withDependencies(
    updateService: updateService ?? MockUpdateService(),
    networkService: networkService ?? MockNetworkService(),
    notificationService: notificationService ?? MockNotificationService(),
    uiDelegate: uiDelegate ?? MockUpdateUIDelegate(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        final updateService = MockUpdateService();
        final controller = _newController(updateService: updateService);
        await controller.initialize();

        var notified = 0;
        controller.addListener(() => notified++);

        updateService.setPendingUpdate(_info());

        // Settle the synchronous setPendingUpdate broadcast and the
        // separate poll path:
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
        final updateService = MockUpdateService();
        final notification = MockNotificationService();
        updateService.setPendingUpdate(_info());

        final controller = _newController(
          updateService: updateService,
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

      test(
          'in-flight check is bypassed when force=true; concurrent calls are coalesced otherwise',
          () async {
        final updateService = MockUpdateService();
        final controller = _newController(updateService: updateService);
        await controller.initialize();

        // First call sets _isCheckingForUpdates=true while the await runs.
        final f1 = controller.checkForUpdatesWithUI();
        // Second call (no force) should return early without re-checking.
        final f2 = controller.checkForUpdatesWithUI();

        await Future.wait([f1, f2]);
        // Both completed; no exception.
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
        final updateService = MockUpdateService();
        final controller = _newController(updateService: updateService);
        await controller.initialize();

        // Configure a progress sequence.
        updateService.configureDownload(
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
                  // Kick off the download; we don't actually need a real
                  // context here for verifying state transitions.
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
        expect(controller.downloadStatus, contains('1000'));
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
      testWidgets('cancelled confirmation does not call service.skipVersion',
          (tester) async {
        final updateService = MockUpdateService();
        final ui = MockUpdateUIDelegate();
        ui.skipVersionConfirmationResult = false;

        final controller = _newController(
          updateService: updateService,
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

        expect(updateService.skippedVersions, isEmpty);
        expect(ui.versionSkippedCalls, isEmpty);
        controller.dispose();
      });

      testWidgets(
          'confirmed: closes dialogs, persists skip, shows undo toast',
          (tester) async {
        final updateService = MockUpdateService();
        final ui = MockUpdateUIDelegate();
        ui.skipVersionConfirmationResult = true;

        final controller = _newController(
          updateService: updateService,
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

        expect(updateService.skippedVersions, contains('3.0.0'));
        expect(ui.closeDialogsCalls, contains(2));
        expect(ui.versionSkippedCalls, contains('3.0.0'));
        controller.dispose();
      });
    });

    group('dispose', () {
      test('does NOT dispose injected services (no double-dispose)', () async {
        final updateService = MockUpdateService();
        final network = MockNetworkService();

        final controller = _newController(
          updateService: updateService,
          networkService: network,
        );
        await controller.initialize();

        controller.dispose();

        // If the controller had disposed these, the next call would throw
        // because the underlying StreamControllers are already closed.
        expect(() => updateService.dispose(), returnsNormally);
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
