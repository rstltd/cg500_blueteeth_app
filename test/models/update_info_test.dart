import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/models/update_type.dart';

void main() {
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
      // Same semver, only one side has build number - treat as equal
      expect(info.hasUpdate, isFalse);
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
      // Same semver, only one side has build number - treat as equal
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

  group('UpdateInfo SHA256 checksum', () {
    test('hasChecksum should return false when sha256Checksum is null', () {
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 1024,
        releaseNotes: 'Test release',
        releaseDate: DateTime.now(),
        sha256Checksum: null,
      );

      expect(info.hasChecksum, isFalse);
    });

    test('hasChecksum should return false when sha256Checksum is empty', () {
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 1024,
        releaseNotes: 'Test release',
        releaseDate: DateTime.now(),
        sha256Checksum: '',
      );

      expect(info.hasChecksum, isFalse);
    });

    test('hasChecksum should return true when sha256Checksum is valid', () {
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 1024,
        releaseNotes: 'Test release',
        releaseDate: DateTime.now(),
        sha256Checksum: 'a' * 64, // Valid 64-character hex string
      );

      expect(info.hasChecksum, isTrue);
    });

    test('sha256Checksum should be preserved in toJson', () {
      final checksum = 'abc123def456' * 5 + 'abcd'; // 64 characters
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 1024,
        releaseNotes: 'Test release',
        releaseDate: DateTime.now(),
        sha256Checksum: checksum,
      );

      final json = info.toJson();

      expect(json['sha256_checksum'], checksum);
    });

    test('toJson should not include sha256_checksum key when null', () {
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 1024,
        releaseNotes: 'Test release',
        releaseDate: DateTime.now(),
        sha256Checksum: null,
      );

      final json = info.toJson();

      expect(json.containsKey('sha256_checksum'), isFalse);
    });

    test('fromJson should parse sha256_checksum correctly', () {
      final checksum = 'fedcba9876543210' * 4; // 64 characters
      final json = {
        'latest_version': '2.0.0',
        'current_version': '1.0.0',
        'download_url': 'https://example.com/app.apk',
        'download_size': 1024,
        'release_notes': 'Test release',
        'release_date': '2024-01-15T10:30:00.000',
        'sha256_checksum': checksum,
      };

      final info = UpdateInfo.fromJson(json);

      expect(info.sha256Checksum, checksum);
      expect(info.hasChecksum, isTrue);
    });

    test('fromJson should handle missing sha256_checksum (backward compatible)', () {
      final json = {
        'latest_version': '2.0.0',
        'current_version': '1.0.0',
        'download_url': 'https://example.com/app.apk',
        'download_size': 1024,
        'release_notes': 'Test release',
        'release_date': '2024-01-15T10:30:00.000',
        // No sha256_checksum field - simulates old release format
      };

      final info = UpdateInfo.fromJson(json);

      expect(info.sha256Checksum, isNull);
      expect(info.hasChecksum, isFalse);
    });

    test('sha256Checksum should round-trip through JSON correctly', () {
      final checksum = '0123456789abcdef' * 4; // 64 characters
      final original = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 1024,
        releaseNotes: 'Test release',
        releaseDate: DateTime.now(),
        sha256Checksum: checksum,
      );

      final json = original.toJson();
      final restored = UpdateInfo.fromJson(json);

      expect(restored.sha256Checksum, original.sha256Checksum);
      expect(restored.hasChecksum, original.hasChecksum);
    });
  });

  group('UpdateInfo comprehensive', () {
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

  group('UpdateInfo SHA256 checksum extraction', () {
    test('should preserve checksum through constructor', () {
      final checksum = 'a1b2c3d4e5f6' * 5 + 'a1b2c3d4'; // 64 chars
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        downloadSize: 1024,
        releaseNotes: 'Test',
        releaseDate: DateTime.now(),
        sha256Checksum: checksum,
      );

      expect(info.sha256Checksum, checksum);
      expect(info.hasChecksum, isTrue);
    });

    test('should handle typical GitHub release notes format', () {
      // Simulates what the release script generates
      final info = UpdateInfo(
        latestVersion: '3.0.0',
        currentVersion: '2.0.0',
        downloadUrl: 'https://github.com/releases/app.apk',
        downloadSize: 15000000,
        releaseNotes: '''
## CG500 BLE App v3.0.0

Released: 2024-12-09

### Changes in this version:
* Bug fixes and improvements

### Verification:
SHA256: abc123def456789012345678901234567890123456789012345678901234abcd
''',
        releaseDate: DateTime.now(),
        sha256Checksum: 'abc123def456789012345678901234567890123456789012345678901234abcd',
      );

      expect(info.hasChecksum, isTrue);
      expect(info.sha256Checksum!.length, 64);
    });

    test('should handle update without checksum (backward compatible)', () {
      // Simulates old release without checksum
      final info = UpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://github.com/releases/app.apk',
        downloadSize: 15000000,
        releaseNotes: '''
## CG500 BLE App v2.0.0

Released: 2024-01-15

### Changes:
* Old release without checksum
''',
        releaseDate: DateTime.now(),
        // No sha256Checksum - old format
      );

      expect(info.hasChecksum, isFalse);
      expect(info.sha256Checksum, isNull);
    });
  });
}
