import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/update/version_info_widget.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UpdateInfo createUpdateInfo({
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
    int downloadSize = 10485760, // 10 MB
    String releaseNotes = 'Bug fixes and improvements',
    DateTime? releaseDate,
  }) {
    return UpdateInfo(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      downloadUrl: 'https://example.com/app.apk',
      downloadSize: downloadSize,
      releaseNotes: releaseNotes,
      releaseDate: releaseDate ?? DateTime(2024, 1, 15),
    );
  }

  group('VersionInfoWidget', () {
    testWidgets('should display current version', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(currentVersion: '1.5.0');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('Current Version:'), findsOneWidget);
      expect(find.text('1.5.0'), findsOneWidget);
    });

    testWidgets('should display new version', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(latestVersion: '2.5.0');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('New Version:'), findsOneWidget);
      expect(find.text('2.5.0'), findsOneWidget);
    });

    testWidgets('should display download size in MB', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(downloadSize: 15728640); // 15 MB

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('Download Size:'), findsOneWidget);
      expect(find.text('15.0 MB'), findsOneWidget);
    });

    testWidgets('should display release date', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        releaseDate: DateTime(2024, 3, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('Release Date:'), findsOneWidget);
      expect(find.text('20/3/2024'), findsOneWidget);
    });

    testWidgets('should display release notes section', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        releaseNotes: 'New feature: Dark mode support',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text("What's New:"), findsOneWidget);
      expect(find.text('New feature: Dark mode support'), findsOneWidget);
    });

    testWidgets('should display default release notes when empty', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(releaseNotes: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('Bug fixes and performance improvements'), findsOneWidget);
    });

    testWidgets('should have Column layout', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should have info row structure', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      // There should be multiple Row widgets for info rows
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('VersionInfoWidget download size formatting', () {
    testWidgets('should format small download size correctly', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(downloadSize: 1048576); // 1 MB

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('1.0 MB'), findsOneWidget);
    });

    testWidgets('should format large download size correctly', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(downloadSize: 104857600); // 100 MB

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('100.0 MB'), findsOneWidget);
    });

    testWidgets('should format fractional download size correctly', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(downloadSize: 5242880); // 5 MB

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('5.0 MB'), findsOneWidget);
    });
  });

  group('VersionInfoWidget date formatting', () {
    testWidgets('should format single digit day correctly', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        releaseDate: DateTime(2024, 1, 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('5/1/2024'), findsOneWidget);
    });

    testWidgets('should format single digit month correctly', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        releaseDate: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('15/3/2024'), findsOneWidget);
    });

    testWidgets('should format double digit month correctly', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        releaseDate: DateTime(2024, 12, 25),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('25/12/2024'), findsOneWidget);
    });
  });

  group('VersionInfoWidget edge cases', () {
    testWidgets('should handle zero download size', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(downloadSize: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text('0.0 MB'), findsOneWidget);
    });

    testWidgets('should handle very long release notes', (WidgetTester tester) async {
      final longNotes = 'A' * 500;
      final updateInfo = createUpdateInfo(releaseNotes: longNotes);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.text(longNotes), findsOneWidget);
    });

    testWidgets('should handle release notes with newlines', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        releaseNotes: 'Feature 1\nFeature 2\nFeature 3',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.textContaining('Feature 1'), findsOneWidget);
    });

    testWidgets('should handle unicode in release notes', (WidgetTester tester) async {
      final updateInfo = createUpdateInfo(
        releaseNotes: '新功能：中文支持 🎉',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VersionInfoWidget(updateInfo: updateInfo),
            ),
          ),
        ),
      );

      expect(find.textContaining('新功能'), findsOneWidget);
    });
  });
}
