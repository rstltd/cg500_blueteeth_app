import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/download_progress.dart';

void main() {
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

    test('should format speed correctly across the byte/KB/MB range', () {
      final testCases = [
        (100.0, '100B/s'),
        (1024.0, '1.0KB/s'),
        (1024.0 * 500, '500.0KB/s'),
        (1024.0 * 1024, '1.0MB/s'),
        (1024.0 * 1024 * 5, '5.0MB/s'),
      ];

      for (final (speed, expected) in testCases) {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: speed,
        );

        expect(progress.speedText, expected,
            reason: 'Expected speed $speed to format as $expected');
      }
    });

    test('should format time remaining correctly across s/m/h ranges', () {
      final testCases = [
        (const Duration(seconds: 5), '5s remaining'),
        (const Duration(seconds: 30), '30s remaining'),
        (const Duration(minutes: 1, seconds: 30), '1m 30s remaining'),
        (const Duration(minutes: 5), '5m 0s remaining'),
        (const Duration(hours: 1), '1h 0m remaining'),
      ];

      for (final (duration, expected) in testCases) {
        final progress = DownloadProgress(
          progress: 0.5,
          downloadedBytes: 500,
          totalBytes: 1000,
          estimatedTimeRemaining: duration,
        );

        expect(progress.timeRemainingText, expected,
            reason: 'Expected duration $duration to format as $expected');
      }
    });
  });
}
