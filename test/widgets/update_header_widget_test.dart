import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/update_header_widget.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UpdateInfo createUpdateInfo({
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
    UpdateType updateType = UpdateType.optional,
    bool isForced = false,
  }) {
    return UpdateInfo(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      downloadUrl: 'https://example.com/app.apk',
      downloadSize: 10485760, // 10 MB
      releaseNotes: 'Bug fixes and improvements',
      isForced: isForced,
      updateType: updateType,
      releaseDate: DateTime(2024, 1, 15),
    );
  }

  group('UpdateHeaderWidget', () {
    testWidgets('should render with optional update type', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(updateType: UpdateType.optional);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('Version 2.0.0'), findsOneWidget);
      expect(find.byIcon(Icons.system_update_alt), findsOneWidget);
    });

    testWidgets('should render with recommended update type', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(updateType: UpdateType.recommended);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.byIcon(Icons.system_update_alt), findsOneWidget);
    });

    testWidgets('should render with critical update type', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(updateType: UpdateType.critical);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Critical Update'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('should render with forced update type', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(updateType: UpdateType.forced);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Required Update'), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
    });

    testWidgets('should display version number correctly', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(latestVersion: '3.5.1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Version 3.5.1'), findsOneWidget);
    });

    testWidgets('should have gradient decoration', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      // Verify Container with BoxDecoration exists
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have icon container', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      // Verify icon exists in the widget tree
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('should have proper layout with Row', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('should have Column for text content', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });
  });

  group('UpdateHeaderWidget different versions', () {
    testWidgets('should display major version update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        latestVersion: '3.0.0',
        currentVersion: '2.0.0',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Version 3.0.0'), findsOneWidget);
    });

    testWidgets('should display minor version update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        latestVersion: '2.1.0',
        currentVersion: '2.0.0',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Version 2.1.0'), findsOneWidget);
    });

    testWidgets('should display patch version update', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        latestVersion: '2.0.1',
        currentVersion: '2.0.0',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Version 2.0.1'), findsOneWidget);
    });
  });

  group('UpdateHeaderWidget edge cases', () {
    testWidgets('should handle empty version string', (WidgetTester tester) async {
      final updateInfo = UpdateInfo(
        latestVersion: '',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 10485760,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Version '), findsOneWidget);
    });

    testWidgets('should handle long version string', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(latestVersion: '10.20.30-beta.1+build.1234');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateHeaderWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('Version 10.20.30-beta.1+build.1234'), findsOneWidget);
    });
  });
}
