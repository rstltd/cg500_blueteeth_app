import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService', () {
    group('singleton', () {
      test('should return same instance', () {
        final instance1 = UpdateService();
        final instance2 = UpdateService();
        expect(identical(instance1, instance2), true);
      });

      test('should have consistent identity across multiple calls', () {
        final instances = <UpdateService>[];
        for (int i = 0; i < 10; i++) {
          instances.add(UpdateService());
        }

        for (int i = 1; i < instances.length; i++) {
          expect(identical(instances[0], instances[i]), true);
        }
      });
    });

    group('streams', () {
      test('updateStream should be a broadcast stream', () {
        final service = UpdateService();
        expect(service.updateStream, isA<Stream<UpdateInfo>>());

        // Should allow multiple listeners
        final sub1 = service.updateStream.listen((_) {});
        final sub2 = service.updateStream.listen((_) {});

        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });

      test('downloadStream should be a broadcast stream', () {
        final service = UpdateService();
        expect(service.downloadStream, isA<Stream<DownloadProgress>>());

        // Should allow multiple listeners
        final sub1 = service.downloadStream.listen((_) {});
        final sub2 = service.downloadStream.listen((_) {});

        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });
    });

    group('getCurrentVersionInfo', () {
      test('should return map with version and buildNumber keys', () {
        final service = UpdateService();
        final info = service.getCurrentVersionInfo();

        expect(info, isA<Map<String, String>>());
        expect(info.containsKey('version'), true);
        expect(info.containsKey('buildNumber'), true);
      });

      test('should return strings for version values', () {
        final service = UpdateService();
        final info = service.getCurrentVersionInfo();

        expect(info['version'], isA<String>());
        expect(info['buildNumber'], isA<String>());
      });

      test('should be consistent across multiple calls', () {
        final service = UpdateService();
        final info1 = service.getCurrentVersionInfo();
        final info2 = service.getCurrentVersionInfo();

        expect(info1['version'], info2['version']);
        expect(info1['buildNumber'], info2['buildNumber']);
      });
    });

    group('preferences', () {
      test('preferences getter should not throw', () {
        final service = UpdateService();
        expect(() => service.preferences, returnsNormally);
      });
    });

    group('dispose', () {
      test('should not throw', () {
        final service = UpdateService();
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });


  group('UpdateInfo', () {
    group('hasUpdate', () {
      test('should return true when latest version is greater than current', () {
        final info = UpdateInfo(
          latestVersion: '2.0.0',
          currentVersion: '1.0.0',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'New features',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isTrue);
      });

      test('should return false when current version equals latest', () {
        final info = UpdateInfo(
          latestVersion: '1.0.0',
          currentVersion: '1.0.0',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Current version',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isFalse);
      });

      test('should return false when current version is greater than latest', () {
        final info = UpdateInfo(
          latestVersion: '1.0.0',
          currentVersion: '2.0.0',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Old version',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isFalse);
      });

      test('should handle minor version updates', () {
        final info = UpdateInfo(
          latestVersion: '1.1.0',
          currentVersion: '1.0.0',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Minor update',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isTrue);
      });

      test('should handle patch version updates', () {
        final info = UpdateInfo(
          latestVersion: '1.0.1',
          currentVersion: '1.0.0',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Patch update',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isTrue);
      });

      test('should handle versions with build numbers', () {
        final info = UpdateInfo(
          latestVersion: '1.0.0',
          currentVersion: '1.0.0+10',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Build update',
          releaseDate: DateTime.now(),
        );

        // Latest without build number should not trigger update for same version with build
        expect(info.hasUpdate, isFalse);
      });

      test('should detect update when latest has higher build number', () {
        final info = UpdateInfo(
          latestVersion: '1.0.0+20',
          currentVersion: '1.0.0+10',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Build update',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isTrue);
      });

      test('should not detect update when current has higher build number', () {
        final info = UpdateInfo(
          latestVersion: '1.0.0+10',
          currentVersion: '1.0.0+20',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Older build',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isFalse);
      });

      test('should handle two-part version numbers', () {
        final info = UpdateInfo(
          latestVersion: '2.0',
          currentVersion: '1.0',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Major update',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isTrue);
      });

      test('should handle version with mixed formats', () {
        final info = UpdateInfo(
          latestVersion: '1.2.3',
          currentVersion: '1.2',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 1024,
          releaseNotes: 'Patch update',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isTrue);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final releaseDate = DateTime(2024, 1, 15, 10, 30);
        final info = UpdateInfo(
          latestVersion: '2.0.0',
          currentVersion: '1.0.0',
          downloadUrl: 'https://example.com/app.apk',
          downloadSize: 10485760,
          releaseNotes: 'New features and bug fixes',
          isForced: true,
          updateType: UpdateType.critical,
          releaseDate: releaseDate,
        );

        final json = info.toJson();

        expect(json['latest_version'], '2.0.0');
        expect(json['current_version'], '1.0.0');
        expect(json['download_url'], 'https://example.com/app.apk');
        expect(json['download_size'], 10485760);
        expect(json['release_notes'], 'New features and bug fixes');
        expect(json['is_forced'], true);
        expect(json['update_type'], 'critical');
        expect(json['release_date'], releaseDate.toIso8601String());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'latest_version': '2.0.0',
          'current_version': '1.0.0',
          'download_url': 'https://example.com/app.apk',
          'download_size': 10485760,
          'release_notes': 'New features',
          'is_forced': false,
          'update_type': 'recommended',
          'release_date': '2024-01-15T10:30:00.000',
        };

        final info = UpdateInfo.fromJson(json);

        expect(info.latestVersion, '2.0.0');
        expect(info.currentVersion, '1.0.0');
        expect(info.downloadUrl, 'https://example.com/app.apk');
        expect(info.downloadSize, 10485760);
        expect(info.releaseNotes, 'New features');
        expect(info.isForced, false);
        expect(info.updateType, UpdateType.recommended);
        expect(info.releaseDate.year, 2024);
        expect(info.releaseDate.month, 1);
        expect(info.releaseDate.day, 15);
      });

      test('should handle missing JSON fields with defaults', () {
        final json = <String, dynamic>{};

        final info = UpdateInfo.fromJson(json);

        expect(info.latestVersion, '1.0.0');
        expect(info.currentVersion, '1.0.0');
        expect(info.downloadUrl, '');
        expect(info.downloadSize, 0);
        expect(info.releaseNotes, '');
        expect(info.isForced, false);
        expect(info.updateType, UpdateType.optional);
      });

      test('should handle invalid update_type in JSON', () {
        final json = {
          'latest_version': '2.0.0',
          'current_version': '1.0.0',
          'download_url': '',
          'download_size': 0,
          'release_notes': '',
          'is_forced': false,
          'update_type': 'invalid_type',
          'release_date': '2024-01-15T10:30:00.000',
        };

        final info = UpdateInfo.fromJson(json);

        expect(info.updateType, UpdateType.optional);
      });

      test('should handle invalid release_date in JSON', () {
        final json = {
          'latest_version': '2.0.0',
          'current_version': '1.0.0',
          'download_url': '',
          'download_size': 0,
          'release_notes': '',
          'is_forced': false,
          'update_type': 'optional',
          'release_date': 'invalid_date',
        };

        final info = UpdateInfo.fromJson(json);

        // Should use current date as fallback
        expect(info.releaseDate.year, DateTime.now().year);
      });

      test('should round-trip through JSON correctly', () {
        final original = UpdateInfo(
          latestVersion: '3.1.4',
          currentVersion: '2.5.0',
          downloadUrl: 'https://github.com/releases/app.apk',
          downloadSize: 25000000,
          releaseNotes: 'Many improvements',
          isForced: true,
          updateType: UpdateType.forced,
          releaseDate: DateTime(2024, 6, 15),
        );

        final json = original.toJson();
        final restored = UpdateInfo.fromJson(json);

        expect(restored.latestVersion, original.latestVersion);
        expect(restored.currentVersion, original.currentVersion);
        expect(restored.downloadUrl, original.downloadUrl);
        expect(restored.downloadSize, original.downloadSize);
        expect(restored.releaseNotes, original.releaseNotes);
        expect(restored.isForced, original.isForced);
        expect(restored.updateType, original.updateType);
        expect(restored.releaseDate.year, original.releaseDate.year);
        expect(restored.releaseDate.month, original.releaseDate.month);
        expect(restored.releaseDate.day, original.releaseDate.day);
      });
    });

    group('constructor defaults', () {
      test('should have default isForced as false', () {
        final info = UpdateInfo(
          latestVersion: '2.0.0',
          currentVersion: '1.0.0',
          downloadUrl: '',
          downloadSize: 0,
          releaseNotes: '',
          releaseDate: DateTime.now(),
        );

        expect(info.isForced, false);
      });

      test('should have default updateType as optional', () {
        final info = UpdateInfo(
          latestVersion: '2.0.0',
          currentVersion: '1.0.0',
          downloadUrl: '',
          downloadSize: 0,
          releaseNotes: '',
          releaseDate: DateTime.now(),
        );

        expect(info.updateType, UpdateType.optional);
      });
    });

    group('edge cases', () {
      test('should handle empty version strings gracefully', () {
        // This tests error handling - should not crash
        final info = UpdateInfo(
          latestVersion: '',
          currentVersion: '',
          downloadUrl: '',
          downloadSize: 0,
          releaseNotes: '',
          releaseDate: DateTime.now(),
        );

        // Should not throw, hasUpdate behavior on invalid input
        expect(() => info.hasUpdate, returnsNormally);
      });

      test('should handle version with many segments', () {
        final info = UpdateInfo(
          latestVersion: '1.2.3.4.5',
          currentVersion: '1.2.3.4.4',
          downloadUrl: '',
          downloadSize: 0,
          releaseNotes: '',
          releaseDate: DateTime.now(),
        );

        // Only first 3 segments are compared
        expect(info.hasUpdate, isFalse);
      });

      test('should handle large version numbers', () {
        final info = UpdateInfo(
          latestVersion: '100.200.300',
          currentVersion: '99.999.999',
          downloadUrl: '',
          downloadSize: 0,
          releaseNotes: '',
          releaseDate: DateTime.now(),
        );

        expect(info.hasUpdate, isTrue);
      });
    });
  });

  group('DownloadProgress', () {
    group('progressText', () {
      test('should format 0% correctly', () {
        final progress = DownloadProgress(
          progress: 0.0,
          downloadedBytes: 0,
          totalBytes: 1000,
        );

        expect(progress.progressText, '0%');
      });

      test('should format 50% correctly', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
        );

        expect(progress.progressText, '50%');
      });

      test('should format 100% correctly', () {
        final progress = DownloadProgress(
          progress: 1.0,
          downloadedBytes: 1000,
          totalBytes: 1000,
        );

        expect(progress.progressText, '100%');
      });

      test('should truncate to integer percentage', () {
        final progress = DownloadProgress(
          progress: 0.333,
          downloadedBytes: 333,
          totalBytes: 1000,
        );

        expect(progress.progressText, '33%');
      });

      test('should handle progress above 1.0', () {
        final progress = DownloadProgress(
          progress: 1.5,
          downloadedBytes: 1500,
          totalBytes: 1000,
        );

        expect(progress.progressText, '150%');
      });
    });

    group('sizeText', () {
      test('should format bytes correctly', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
        );

        expect(progress.sizeText, '500B / 1000B');
      });

      test('should format kilobytes correctly', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 512 * 1024,
          totalBytes: 1024 * 1024,
        );

        // 1024KB = 1MB, so totalBytes will be formatted as MB
        expect(progress.sizeText, '512.0KB / 1.0MB');
      });

      test('should format megabytes correctly', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 5 * 1024 * 1024,
          totalBytes: 10 * 1024 * 1024,
        );

        expect(progress.sizeText, '5.0MB / 10.0MB');
      });

      test('should handle zero bytes', () {
        final progress = DownloadProgress(
          progress: 0.0,
          downloadedBytes: 0,
          totalBytes: 0,
        );

        expect(progress.sizeText, '0B / 0B');
      });
    });

    group('speedText', () {
      test('should return empty string for null speed', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: null,
        );

        expect(progress.speedText, '');
      });

      test('should return empty string for zero speed', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: 0,
        );

        expect(progress.speedText, '');
      });

      test('should return empty string for negative speed', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: -100,
        );

        expect(progress.speedText, '');
      });

      test('should format bytes per second', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: 500,
        );

        expect(progress.speedText, '500B/s');
      });

      test('should format kilobytes per second', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: 1024 * 500,
        );

        expect(progress.speedText, '500.0KB/s');
      });

      test('should format megabytes per second', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: 5 * 1024 * 1024,
        );

        expect(progress.speedText, '5.0MB/s');
      });
    });

    group('timeRemainingText', () {
      test('should return empty string for null duration', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          estimatedTimeRemaining: null,
        );

        expect(progress.timeRemainingText, '');
      });

      test('should format seconds remaining', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          estimatedTimeRemaining: const Duration(seconds: 45),
        );

        expect(progress.timeRemainingText, '45s remaining');
      });

      test('should format minutes and seconds remaining', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          estimatedTimeRemaining: const Duration(minutes: 5, seconds: 30),
        );

        expect(progress.timeRemainingText, '5m 30s remaining');
      });

      test('should format hours and minutes remaining', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          estimatedTimeRemaining: const Duration(hours: 2, minutes: 15),
        );

        expect(progress.timeRemainingText, '2h 15m remaining');
      });

      test('should format zero duration', () {
        final progress = DownloadProgress(
          progress: 1.0,
          downloadedBytes: 1000,
          totalBytes: 1000,
          estimatedTimeRemaining: Duration.zero,
        );

        expect(progress.timeRemainingText, '0s remaining');
      });

      test('should handle exactly 1 hour', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          estimatedTimeRemaining: const Duration(hours: 1),
        );

        expect(progress.timeRemainingText, '1h 0m remaining');
      });

      test('should handle exactly 1 minute', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          estimatedTimeRemaining: const Duration(minutes: 1),
        );

        expect(progress.timeRemainingText, '1m 0s remaining');
      });
    });

    group('constructor', () {
      test('should set all required fields', () {
        final progress = DownloadProgress(
          progress: 0.75,
          downloadedBytes: 750,
          totalBytes: 1000,
        );

        expect(progress.progress, 0.75);
        expect(progress.downloadedBytes, 750);
        expect(progress.totalBytes, 1000);
      });

      test('should set optional fields', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          filePath: '/path/to/file.apk',
          status: 'Downloading...',
          speed: 1024.0,
          estimatedTimeRemaining: const Duration(seconds: 30),
        );

        expect(progress.filePath, '/path/to/file.apk');
        expect(progress.status, 'Downloading...');
        expect(progress.speed, 1024.0);
        expect(progress.estimatedTimeRemaining, const Duration(seconds: 30));
      });

      test('should have default empty status', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
        );

        expect(progress.status, '');
      });

      test('should have default null optional fields', () {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
        );

        expect(progress.filePath, isNull);
        expect(progress.speed, isNull);
        expect(progress.estimatedTimeRemaining, isNull);
      });
    });
  });

  group('UpdateType', () {
    test('should have all expected values', () {
      expect(UpdateType.values.length, 4);
      expect(UpdateType.values, contains(UpdateType.optional));
      expect(UpdateType.values, contains(UpdateType.recommended));
      expect(UpdateType.values, contains(UpdateType.critical));
      expect(UpdateType.values, contains(UpdateType.forced));
    });

    test('optional should have correct name', () {
      expect(UpdateType.optional.name, 'optional');
    });

    test('recommended should have correct name', () {
      expect(UpdateType.recommended.name, 'recommended');
    });

    test('critical should have correct name', () {
      expect(UpdateType.critical.name, 'critical');
    });

    test('forced should have correct name', () {
      expect(UpdateType.forced.name, 'forced');
    });

    test('should be able to find by name', () {
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'optional'),
        UpdateType.optional,
      );
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'recommended'),
        UpdateType.recommended,
      );
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'critical'),
        UpdateType.critical,
      );
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'forced'),
        UpdateType.forced,
      );
    });

    test('should have correct index order', () {
      expect(UpdateType.optional.index, 0);
      expect(UpdateType.recommended.index, 1);
      expect(UpdateType.critical.index, 2);
      expect(UpdateType.forced.index, 3);
    });
  });

  group('UpdateInfo version comparison edge cases', () {
    test('should handle version with leading zeros', () {
      // This is an interesting edge case - int.parse handles leading zeros
      final info = UpdateInfo(
        latestVersion: '01.02.03',
        currentVersion: '1.2.2',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      expect(info.hasUpdate, isTrue);
    });

    test('should handle single digit versions', () {
      final info = UpdateInfo(
        latestVersion: '2',
        currentVersion: '1',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      expect(info.hasUpdate, isTrue);
    });

    test('should handle latest version same as current with different format', () {
      final info = UpdateInfo(
        latestVersion: '1.0.0',
        currentVersion: '1.0',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      // Both are effectively 1.0.0
      expect(info.hasUpdate, isFalse);
    });

    test('should handle build number comparison when base versions equal', () {
      final info = UpdateInfo(
        latestVersion: '2.0.0+5',
        currentVersion: '2.0.0+3',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      expect(info.hasUpdate, isTrue);
    });

    test('should handle latest with build number vs current without', () {
      final info = UpdateInfo(
        latestVersion: '2.0.0+5',
        currentVersion: '2.0.0',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      expect(info.hasUpdate, isTrue);
    });

    test('should handle current with build number vs latest without', () {
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '2.0.0+5',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      // Current has build number, latest doesn't - current is newer
      expect(info.hasUpdate, isFalse);
    });

    test('should handle version with v prefix stripped', () {
      // Note: The service strips 'v' prefix, but the model doesn't
      // This tests behavior if prefix was already stripped
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      expect(info.hasUpdate, isTrue);
    });

    test('should handle major version rollback', () {
      final info = UpdateInfo(
        latestVersion: '1.0.0',
        currentVersion: '3.0.0',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        releaseDate: DateTime.now(),
      );
      expect(info.hasUpdate, isFalse);
    });
  });

  group('DownloadProgress edge cases', () {
    test('should handle very large file sizes', () {
      final progress = DownloadProgress(
        progress: 0.5,
        downloadedBytes: 500 * 1024 * 1024, // 500 MB
        totalBytes: 1000 * 1024 * 1024, // 1 GB
      );

      expect(progress.sizeText, contains('MB'));
    });

    test('should handle fractional progress values', () {
      final progress = DownloadProgress(
        progress: 0.999,
        downloadedBytes: 999,
        totalBytes: 1000,
      );

      expect(progress.progressText, '99%'); // Truncated, not rounded
    });

    test('should handle very small speed', () {
      final progress = DownloadProgress(
        progress: 0.5,
        downloadedBytes: 500,
        totalBytes: 1000,
        speed: 1.0, // 1 byte per second
      );

      expect(progress.speedText, '1B/s');
    });

    test('should handle very large speed', () {
      final progress = DownloadProgress(
        progress: 0.5,
        downloadedBytes: 500,
        totalBytes: 1000,
        speed: 100 * 1024 * 1024.0, // 100 MB/s
      );

      expect(progress.speedText, '100.0MB/s');
    });

    test('should handle very long duration remaining', () {
      final progress = DownloadProgress(
        progress: 0.1,
        downloadedBytes: 100,
        totalBytes: 1000,
        estimatedTimeRemaining: const Duration(hours: 24, minutes: 30),
      );

      expect(progress.timeRemainingText, '24h 30m remaining');
    });

    test('should handle exactly 60 seconds', () {
      final progress = DownloadProgress(
        progress: 0.5,
        downloadedBytes: 500,
        totalBytes: 1000,
        estimatedTimeRemaining: const Duration(seconds: 60),
      );

      // 60 seconds = 1 minute 0 seconds
      expect(progress.timeRemainingText, '1m 0s remaining');
    });

    test('should handle exactly 59 seconds', () {
      final progress = DownloadProgress(
        progress: 0.5,
        downloadedBytes: 500,
        totalBytes: 1000,
        estimatedTimeRemaining: const Duration(seconds: 59),
      );

      expect(progress.timeRemainingText, '59s remaining');
    });
  });

  group('UpdateInfo comprehensive tests', () {
    test('should store all properties correctly', () {
      final releaseDate = DateTime(2024, 6, 15, 12, 0, 0);
      final info = UpdateInfo(
        latestVersion: '2.1.0',
        currentVersion: '1.5.0',
        downloadUrl: 'https://github.com/releases/app.apk',
        downloadSize: 15000000,
        releaseNotes: 'Bug fixes and improvements',
        isForced: false,
        updateType: UpdateType.recommended,
        releaseDate: releaseDate,
      );

      expect(info.latestVersion, '2.1.0');
      expect(info.currentVersion, '1.5.0');
      expect(info.downloadUrl, 'https://github.com/releases/app.apk');
      expect(info.downloadSize, 15000000);
      expect(info.releaseNotes, 'Bug fixes and improvements');
      expect(info.isForced, false);
      expect(info.updateType, UpdateType.recommended);
      expect(info.releaseDate, releaseDate);
    });

    test('should handle forced update correctly', () {
      final info = UpdateInfo(
        latestVersion: '3.0.0',
        currentVersion: '1.0.0',
        downloadUrl: '',
        downloadSize: 0,
        releaseNotes: '',
        isForced: true,
        updateType: UpdateType.forced,
        releaseDate: DateTime.now(),
      );

      expect(info.isForced, true);
      expect(info.updateType, UpdateType.forced);
    });

    test('fromJson should handle all UpdateType values', () {
      for (final updateType in UpdateType.values) {
        final json = {
          'latest_version': '2.0.0',
          'current_version': '1.0.0',
          'download_url': '',
          'download_size': 0,
          'release_notes': '',
          'is_forced': false,
          'update_type': updateType.name,
          'release_date': '2024-01-15T10:30:00.000',
        };

        final info = UpdateInfo.fromJson(json);
        expect(info.updateType, updateType);
      }
    });

    test('toJson and fromJson should be symmetric', () {
      final original = UpdateInfo(
        latestVersion: '1.2.3+456',
        currentVersion: '0.9.0+100',
        downloadUrl: 'https://example.com/update.apk',
        downloadSize: 12345678,
        releaseNotes: 'Test release notes with unicode: 中文',
        isForced: true,
        updateType: UpdateType.critical,
        releaseDate: DateTime(2024, 12, 25, 8, 30, 0),
      );

      final json = original.toJson();
      final restored = UpdateInfo.fromJson(json);

      expect(restored.latestVersion, original.latestVersion);
      expect(restored.currentVersion, original.currentVersion);
      expect(restored.downloadUrl, original.downloadUrl);
      expect(restored.downloadSize, original.downloadSize);
      expect(restored.releaseNotes, original.releaseNotes);
      expect(restored.isForced, original.isForced);
      expect(restored.updateType, original.updateType);
    });
  });

  group('DownloadProgress formatting stress tests', () {
    test('should format all byte ranges correctly', () {
      final testCases = [
        (0, '0B'),
        (512, '512B'),
        (1023, '1023B'),
        (1024, '1.0KB'),
        (1536, '1.5KB'),
        (1024 * 1024 - 1, '1024.0KB'),
        (1024 * 1024, '1.0MB'),
        (1024 * 1024 * 10, '10.0MB'),
        (1024 * 1024 * 100, '100.0MB'),
      ];

      for (final (bytes, expected) in testCases) {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: bytes,
          totalBytes: bytes * 2,
        );

        // Extract the first part of sizeText (downloaded portion)
        final sizeText = progress.sizeText;
        expect(sizeText.startsWith(expected), isTrue,
            reason: 'Expected $bytes to format as $expected but got $sizeText');
      }
    });

    test('should handle progress at boundaries', () {
      final testCases = [
        (0.0, '0%'),
        (0.005, '0%'),
        (0.01, '1%'),
        (0.10, '10%'),
        (0.50, '50%'),
        (0.99, '99%'),
        (0.999, '99%'),
        (1.0, '100%'),
      ];

      for (final (progress, expected) in testCases) {
        final dp = DownloadProgress(
          progress: progress,
          downloadedBytes: (progress * 1000).round(),
          totalBytes: 1000,
        );

        expect(dp.progressText, expected,
            reason: 'Expected progress $progress to format as $expected');
      }
    });
  });
}
