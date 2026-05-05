import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/update/version_info_widget.dart';
import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UpdateInfo createUpdateInfo({
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
    int downloadSize = 10485760, // 10 MB
  }) {
    return UpdateInfo(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      downloadUrl: 'https://example.com/app.apk',
      downloadSize: downloadSize,
      releaseNotes: '',
      releaseDate: DateTime(2024, 1, 15),
    );
  }

  group('VersionInfoWidget', () {
    testWidgets('should display current version', (tester) async {
      final updateInfo = createUpdateInfo(currentVersion: '1.5.0');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VersionInfoWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.textContaining(AppStrings.currentVersionLabel), findsOneWidget);
      expect(find.text('1.5.0'), findsOneWidget);
    });

    testWidgets('should display new version', (tester) async {
      final updateInfo = createUpdateInfo(latestVersion: '2.5.0');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VersionInfoWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.textContaining(AppStrings.newVersionLabel), findsOneWidget);
      expect(find.text('2.5.0'), findsOneWidget);
    });

    testWidgets('should display download size in MB', (tester) async {
      final updateInfo = createUpdateInfo(downloadSize: 15728640); // 15 MB

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VersionInfoWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.textContaining(AppStrings.downloadSizeLabel), findsOneWidget);
      expect(find.text('15.0 MB'), findsOneWidget);
    });

    testWidgets('should handle zero download size', (tester) async {
      final updateInfo = createUpdateInfo(downloadSize: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VersionInfoWidget(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.byType(VersionInfoWidget), findsOneWidget);
    });

    testWidgets('should not display release notes or SHA256', (tester) async {
      final updateInfo = createUpdateInfo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VersionInfoWidget(updateInfo: updateInfo),
          ),
        ),
      );

      // The simplified widget should NOT show these
      expect(find.textContaining('What'), findsNothing);
      expect(find.textContaining('SHA'), findsNothing);
      expect(find.textContaining('Release Date'), findsNothing);
    });
  });
}
