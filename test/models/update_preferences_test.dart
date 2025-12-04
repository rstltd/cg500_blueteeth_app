import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cg500_blueteeth_app/models/update_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('UpdatePreferences', () {
    group('constructor', () {
      test('should create with default values', () {
        final prefs = UpdatePreferences();
        expect(prefs.autoCheckEnabled, true);
        expect(prefs.autoDownloadEnabled, false);
        expect(prefs.wifiOnlyDownload, true);
        expect(prefs.skippedVersions, isEmpty);
        expect(prefs.updateFrequency, UpdateFrequency.daily);
      });

      test('should create with custom values', () {
        final prefs = UpdatePreferences(
          autoCheckEnabled: false,
          autoDownloadEnabled: true,
          wifiOnlyDownload: false,
          skippedVersions: ['1.0.0', '1.1.0'],
          updateFrequency: UpdateFrequency.weekly,
        );

        expect(prefs.autoCheckEnabled, false);
        expect(prefs.autoDownloadEnabled, true);
        expect(prefs.wifiOnlyDownload, false);
        expect(prefs.skippedVersions, ['1.0.0', '1.1.0']);
        expect(prefs.updateFrequency, UpdateFrequency.weekly);
      });
    });

    group('skipVersion', () {
      test('should add version to skipped list', () {
        final prefs = UpdatePreferences();
        prefs.skipVersion('1.0.0');
        expect(prefs.skippedVersions, contains('1.0.0'));
      });

      test('should not add duplicate version', () {
        final prefs = UpdatePreferences(skippedVersions: ['1.0.0']);
        prefs.skipVersion('1.0.0');
        expect(prefs.skippedVersions.length, 1);
      });

      test('should add multiple different versions', () {
        final prefs = UpdatePreferences();
        prefs.skipVersion('1.0.0');
        prefs.skipVersion('1.1.0');
        prefs.skipVersion('2.0.0');
        expect(prefs.skippedVersions.length, 3);
        expect(prefs.skippedVersions, containsAll(['1.0.0', '1.1.0', '2.0.0']));
      });
    });

    group('unskipVersion', () {
      test('should remove version from skipped list', () {
        final prefs = UpdatePreferences(skippedVersions: ['1.0.0', '1.1.0']);
        prefs.unskipVersion('1.0.0');
        expect(prefs.skippedVersions, isNot(contains('1.0.0')));
        expect(prefs.skippedVersions, contains('1.1.0'));
      });

      test('should handle non-existent version gracefully', () {
        final prefs = UpdatePreferences(skippedVersions: ['1.0.0']);
        prefs.unskipVersion('2.0.0');
        expect(prefs.skippedVersions, ['1.0.0']);
      });

      test('should handle empty list gracefully', () {
        final prefs = UpdatePreferences();
        prefs.unskipVersion('1.0.0');
        expect(prefs.skippedVersions, isEmpty);
      });
    });

    group('shouldSkipVersion', () {
      test('should return true for skipped version', () {
        final prefs = UpdatePreferences(skippedVersions: ['1.0.0']);
        expect(prefs.shouldSkipVersion('1.0.0'), true);
      });

      test('should return false for non-skipped version', () {
        final prefs = UpdatePreferences(skippedVersions: ['1.0.0']);
        expect(prefs.shouldSkipVersion('2.0.0'), false);
      });

      test('should return false for empty skipped list', () {
        final prefs = UpdatePreferences();
        expect(prefs.shouldSkipVersion('1.0.0'), false);
      });
    });

    group('clearSkippedVersions', () {
      test('should clear all skipped versions', () {
        final prefs = UpdatePreferences(
          skippedVersions: ['1.0.0', '1.1.0', '2.0.0'],
        );
        prefs.clearSkippedVersions();
        expect(prefs.skippedVersions, isEmpty);
      });

      test('should handle already empty list', () {
        final prefs = UpdatePreferences();
        prefs.clearSkippedVersions();
        expect(prefs.skippedVersions, isEmpty);
      });
    });

    group('copyWith', () {
      test('should copy with new autoCheckEnabled', () {
        final prefs = UpdatePreferences();
        final copied = prefs.copyWith(autoCheckEnabled: false);
        expect(copied.autoCheckEnabled, false);
        expect(copied.autoDownloadEnabled, prefs.autoDownloadEnabled);
      });

      test('should copy with new autoDownloadEnabled', () {
        final prefs = UpdatePreferences();
        final copied = prefs.copyWith(autoDownloadEnabled: true);
        expect(copied.autoDownloadEnabled, true);
      });

      test('should copy with new wifiOnlyDownload', () {
        final prefs = UpdatePreferences();
        final copied = prefs.copyWith(wifiOnlyDownload: false);
        expect(copied.wifiOnlyDownload, false);
      });

      test('should copy with new skippedVersions', () {
        final prefs = UpdatePreferences();
        final copied = prefs.copyWith(skippedVersions: ['1.0.0']);
        expect(copied.skippedVersions, ['1.0.0']);
      });

      test('should copy with new updateFrequency', () {
        final prefs = UpdatePreferences();
        final copied = prefs.copyWith(updateFrequency: UpdateFrequency.never);
        expect(copied.updateFrequency, UpdateFrequency.never);
      });

      test('should preserve original values when no changes', () {
        final prefs = UpdatePreferences(
          autoCheckEnabled: false,
          autoDownloadEnabled: true,
          wifiOnlyDownload: false,
          skippedVersions: ['1.0.0'],
          updateFrequency: UpdateFrequency.weekly,
        );
        final copied = prefs.copyWith();
        expect(copied.autoCheckEnabled, prefs.autoCheckEnabled);
        expect(copied.autoDownloadEnabled, prefs.autoDownloadEnabled);
        expect(copied.wifiOnlyDownload, prefs.wifiOnlyDownload);
        expect(copied.skippedVersions, prefs.skippedVersions);
        expect(copied.updateFrequency, prefs.updateFrequency);
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final prefs = UpdatePreferences();
        final str = prefs.toString();
        expect(str, contains('UpdatePreferences'));
        expect(str, contains('autoCheck:'));
        expect(str, contains('autoDownload:'));
        expect(str, contains('wifiOnly:'));
        expect(str, contains('skipped:'));
        expect(str, contains('frequency:'));
      });

      test('should include correct values', () {
        final prefs = UpdatePreferences(
          autoCheckEnabled: true,
          autoDownloadEnabled: false,
          wifiOnlyDownload: true,
          skippedVersions: ['1.0.0', '2.0.0'],
          updateFrequency: UpdateFrequency.weekly,
        );
        final str = prefs.toString();
        expect(str, contains('autoCheck: true'));
        expect(str, contains('autoDownload: false'));
        expect(str, contains('wifiOnly: true'));
        expect(str, contains('2 versions'));
        expect(str, contains('weekly'));
      });
    });
  });

  group('UpdateFrequency', () {
    group('enum values', () {
      test('should have 4 frequency options', () {
        expect(UpdateFrequency.values.length, 4);
      });

      test('should contain never option', () {
        expect(UpdateFrequency.values, contains(UpdateFrequency.never));
      });

      test('should contain daily option', () {
        expect(UpdateFrequency.values, contains(UpdateFrequency.daily));
      });

      test('should contain weekly option', () {
        expect(UpdateFrequency.values, contains(UpdateFrequency.weekly));
      });

      test('should contain manual option', () {
        expect(UpdateFrequency.values, contains(UpdateFrequency.manual));
      });
    });

    group('displayName', () {
      test('never should display "Never"', () {
        expect(UpdateFrequency.never.displayName, 'Never');
      });

      test('daily should display "Daily"', () {
        expect(UpdateFrequency.daily.displayName, 'Daily');
      });

      test('weekly should display "Weekly"', () {
        expect(UpdateFrequency.weekly.displayName, 'Weekly');
      });

      test('manual should display "Manual only"', () {
        expect(UpdateFrequency.manual.displayName, 'Manual only');
      });
    });
  });

  group('UpdatePreferences persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('load', () {
      test('should load default values when no preferences exist', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await UpdatePreferences.load();
        expect(prefs.autoCheckEnabled, true);
        expect(prefs.autoDownloadEnabled, false);
        expect(prefs.wifiOnlyDownload, true);
        expect(prefs.skippedVersions, isEmpty);
        expect(prefs.updateFrequency, UpdateFrequency.daily);
      });

      test('should load saved autoCheckEnabled', () async {
        SharedPreferences.setMockInitialValues({
          'update_auto_check': false,
        });
        final prefs = await UpdatePreferences.load();
        expect(prefs.autoCheckEnabled, false);
      });

      test('should load saved autoDownloadEnabled', () async {
        SharedPreferences.setMockInitialValues({
          'update_auto_download': true,
        });
        final prefs = await UpdatePreferences.load();
        expect(prefs.autoDownloadEnabled, true);
      });

      test('should load saved wifiOnlyDownload', () async {
        SharedPreferences.setMockInitialValues({
          'update_wifi_only': false,
        });
        final prefs = await UpdatePreferences.load();
        expect(prefs.wifiOnlyDownload, false);
      });

      test('should load saved skippedVersions', () async {
        SharedPreferences.setMockInitialValues({
          'update_skip_versions': ['1.0.0', '2.0.0'],
        });
        final prefs = await UpdatePreferences.load();
        expect(prefs.skippedVersions, ['1.0.0', '2.0.0']);
      });

      test('should load saved updateFrequency', () async {
        SharedPreferences.setMockInitialValues({
          'update_frequency': 'weekly',
        });
        final prefs = await UpdatePreferences.load();
        expect(prefs.updateFrequency, UpdateFrequency.weekly);
      });

      test('should use default for invalid frequency', () async {
        SharedPreferences.setMockInitialValues({
          'update_frequency': 'invalid_value',
        });
        final prefs = await UpdatePreferences.load();
        expect(prefs.updateFrequency, UpdateFrequency.daily);
      });

      test('should load all saved values together', () async {
        SharedPreferences.setMockInitialValues({
          'update_auto_check': false,
          'update_auto_download': true,
          'update_wifi_only': false,
          'update_skip_versions': ['1.0.0'],
          'update_frequency': 'never',
        });
        final prefs = await UpdatePreferences.load();
        expect(prefs.autoCheckEnabled, false);
        expect(prefs.autoDownloadEnabled, true);
        expect(prefs.wifiOnlyDownload, false);
        expect(prefs.skippedVersions, ['1.0.0']);
        expect(prefs.updateFrequency, UpdateFrequency.never);
      });
    });

    group('save', () {
      test('should save all preferences', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = UpdatePreferences(
          autoCheckEnabled: false,
          autoDownloadEnabled: true,
          wifiOnlyDownload: false,
          skippedVersions: ['1.0.0', '2.0.0'],
          updateFrequency: UpdateFrequency.weekly,
        );
        await prefs.save();

        // Load again to verify
        final loaded = await UpdatePreferences.load();
        expect(loaded.autoCheckEnabled, false);
        expect(loaded.autoDownloadEnabled, true);
        expect(loaded.wifiOnlyDownload, false);
        expect(loaded.skippedVersions, ['1.0.0', '2.0.0']);
        expect(loaded.updateFrequency, UpdateFrequency.weekly);
      });

      test('should overwrite existing preferences', () async {
        SharedPreferences.setMockInitialValues({
          'update_auto_check': true,
          'update_auto_download': false,
        });

        final prefs = UpdatePreferences(
          autoCheckEnabled: false,
          autoDownloadEnabled: true,
        );
        await prefs.save();

        final loaded = await UpdatePreferences.load();
        expect(loaded.autoCheckEnabled, false);
        expect(loaded.autoDownloadEnabled, true);
      });

      test('should persist default values', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = UpdatePreferences();
        await prefs.save();

        final loaded = await UpdatePreferences.load();
        expect(loaded.autoCheckEnabled, true);
        expect(loaded.autoDownloadEnabled, false);
        expect(loaded.wifiOnlyDownload, true);
        expect(loaded.skippedVersions, isEmpty);
        expect(loaded.updateFrequency, UpdateFrequency.daily);
      });
    });

    group('round-trip persistence', () {
      test('should persist skipVersion changes', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = UpdatePreferences();
        prefs.skipVersion('3.0.0');
        await prefs.save();

        final loaded = await UpdatePreferences.load();
        expect(loaded.skippedVersions, contains('3.0.0'));
      });

      test('should persist unskipVersion changes', () async {
        SharedPreferences.setMockInitialValues({
          'update_skip_versions': ['1.0.0', '2.0.0'],
        });
        final prefs = await UpdatePreferences.load();
        prefs.unskipVersion('1.0.0');
        await prefs.save();

        final loaded = await UpdatePreferences.load();
        expect(loaded.skippedVersions, isNot(contains('1.0.0')));
        expect(loaded.skippedVersions, contains('2.0.0'));
      });

      test('should persist clearSkippedVersions changes', () async {
        SharedPreferences.setMockInitialValues({
          'update_skip_versions': ['1.0.0', '2.0.0', '3.0.0'],
        });
        final prefs = await UpdatePreferences.load();
        prefs.clearSkippedVersions();
        await prefs.save();

        final loaded = await UpdatePreferences.load();
        expect(loaded.skippedVersions, isEmpty);
      });
    });
  });
}
