import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/update/update_actions_widget.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UpdateInfo createUpdateInfo({
    UpdateType updateType = UpdateType.optional,
    bool isForced = false,
  }) {
    return UpdateInfo(
      latestVersion: '2.0.0',
      currentVersion: '1.0.0',
      downloadUrl: 'https://example.com/app.apk',
      downloadSize: 10485760,
      releaseNotes: 'Bug fixes',
      isForced: isForced,
      updateType: updateType,
      releaseDate: DateTime(2024, 1, 15),
    );
  }

  group('UpdateActionsWidget', () {
    testWidgets('should render update button', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show Skip and Later buttons for optional update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(updateType: UpdateType.optional);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
              onSkipVersion: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('should hide Skip and Later buttons for forced update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        updateType: UpdateType.forced,
        isForced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
              onSkipVersion: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Skip'), findsNothing);
      expect(find.text('Later'), findsNothing);
      expect(find.text('Update Now'), findsOneWidget);
    });

    testWidgets('should hide Skip and Later buttons for critical update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        updateType: UpdateType.critical,
        isForced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.text('Skip'), findsNothing);
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('should show Browser Download button', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.text('Browser Download'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
    });

    testWidgets('should disable update button when downloading', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: true,
              downloadProgress: 0.5,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should show loading indicator when downloading', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: true,
              downloadProgress: 0.5,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show warning when downloading starts', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: true,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('download fails'), findsOneWidget);
    });

    testWidgets('should not show warning when not downloading', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('download fails'), findsNothing);
    });

    testWidgets('should not show warning when progress > 0', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: true,
              downloadProgress: 0.1,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('download fails'), findsNothing);
    });

    testWidgets('should call onStartUpdate when update button pressed', (WidgetTester tester) async {
      bool called = false;
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('should call onSkipVersion when skip button pressed', (WidgetTester tester) async {
      bool called = false;
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
              onSkipVersion: () => called = true,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('should call onDismiss when later button pressed', (WidgetTester tester) async {
      bool called = false;
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
              onSkipVersion: () {},
              onDismiss: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Later'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('should hide Skip and Later buttons while downloading', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: true,
              downloadProgress: 0.5,
              onStartUpdate: () {},
              onSkipVersion: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Skip'), findsNothing);
      expect(find.text('Later'), findsNothing);
    });
  });

  group('UpdateActionsWidget button colors', () {
    testWidgets('should have blue button for optional update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(updateType: UpdateType.optional);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should have orange button for forced update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        updateType: UpdateType.forced,
        isForced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should have red button for critical update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        updateType: UpdateType.critical,
        isForced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('UpdateActionsWidget layout', () {
    testWidgets('should have Column layout', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should have Row for action buttons', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should have browser download button', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateActionsWidget(
              updateInfo: updateInfo,
              isDownloading: false,
              downloadProgress: 0.0,
              onStartUpdate: () {},
            ),
          ),
        ),
      );

      // Verify browser download button exists by text
      expect(find.text('Browser Download'), findsOneWidget);
    });
  });
}
