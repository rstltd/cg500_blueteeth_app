import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/utils/formatting_utils.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';

void main() {
  group('FormattingUtils', () {
    group('formatDateTime', () {
      test('should format date and time correctly', () {
        final dateTime = DateTime(2024, 3, 15, 14, 30);
        final result = FormattingUtils.formatDateTime(dateTime);

        expect(result, '2024/3/15 14:30');
      });

      test('should pad single digit minutes with zero', () {
        final dateTime = DateTime(2024, 1, 5, 9, 5);
        final result = FormattingUtils.formatDateTime(dateTime);

        expect(result, '2024/1/5 9:05');
      });

      test('should handle midnight correctly', () {
        final dateTime = DateTime(2024, 12, 31, 0, 0);
        final result = FormattingUtils.formatDateTime(dateTime);

        expect(result, '2024/12/31 0:00');
      });

      test('should handle noon correctly', () {
        final dateTime = DateTime(2024, 6, 15, 12, 0);
        final result = FormattingUtils.formatDateTime(dateTime);

        expect(result, '2024/6/15 12:00');
      });

      test('should handle end of day correctly', () {
        final dateTime = DateTime(2024, 6, 15, 23, 59);
        final result = FormattingUtils.formatDateTime(dateTime);

        expect(result, '2024/6/15 23:59');
      });

      test('should handle leap year date', () {
        final dateTime = DateTime(2024, 2, 29, 10, 15);
        final result = FormattingUtils.formatDateTime(dateTime);

        expect(result, '2024/2/29 10:15');
      });
    });

    group('formatDuration', () {
      test('should format zero duration', () {
        const duration = Duration.zero;
        final result = FormattingUtils.formatDuration(duration);

        expect(result, '00:00:00');
      });

      test('should format seconds only', () {
        const duration = Duration(seconds: 45);
        final result = FormattingUtils.formatDuration(duration);

        expect(result, '00:00:45');
      });

      test('should format minutes and seconds', () {
        const duration = Duration(minutes: 5, seconds: 30);
        final result = FormattingUtils.formatDuration(duration);

        expect(result, '00:05:30');
      });

      test('should format hours, minutes and seconds', () {
        const duration = Duration(hours: 2, minutes: 15, seconds: 45);
        final result = FormattingUtils.formatDuration(duration);

        expect(result, '02:15:45');
      });

      test('should handle large hours', () {
        const duration = Duration(hours: 100, minutes: 30, seconds: 15);
        final result = FormattingUtils.formatDuration(duration);

        expect(result, '100:30:15');
      });

      test('should pad single digit values', () {
        const duration = Duration(hours: 1, minutes: 2, seconds: 3);
        final result = FormattingUtils.formatDuration(duration);

        expect(result, '01:02:03');
      });

      test('should handle maximum minute and second values', () {
        const duration = Duration(hours: 1, minutes: 59, seconds: 59);
        final result = FormattingUtils.formatDuration(duration);

        expect(result, '01:59:59');
      });
    });

    group('getNotificationColor', () {
      test('should return green for success', () {
        final color = FormattingUtils.getNotificationColor(NotificationType.success);

        expect(color, Colors.green);
      });

      test('should return orange for warning', () {
        final color = FormattingUtils.getNotificationColor(NotificationType.warning);

        expect(color, Colors.orange);
      });

      test('should return red for error', () {
        final color = FormattingUtils.getNotificationColor(NotificationType.error);

        expect(color, Colors.red);
      });

      test('should return blue for info', () {
        final color = FormattingUtils.getNotificationColor(NotificationType.info);

        expect(color, Colors.blue);
      });

      test('should handle all notification types', () {
        for (final type in NotificationType.values) {
          expect(
            () => FormattingUtils.getNotificationColor(type),
            returnsNormally,
            reason: 'Should handle $type without throwing',
          );
        }
      });
    });

    group('getNetworkStatusColor', () {
      test('should return green for wifi', () {
        final color = FormattingUtils.getNetworkStatusColor(NetworkStatus.wifi);

        expect(color, Colors.green);
      });

      test('should return orange for mobile', () {
        final color = FormattingUtils.getNetworkStatusColor(NetworkStatus.mobile);

        expect(color, Colors.orange);
      });

      test('should return red for none', () {
        final color = FormattingUtils.getNetworkStatusColor(NetworkStatus.none);

        expect(color, Colors.red);
      });

      test('should return grey for unknown', () {
        final color = FormattingUtils.getNetworkStatusColor(NetworkStatus.unknown);

        expect(color, Colors.grey);
      });

      test('should handle all network statuses', () {
        for (final status in NetworkStatus.values) {
          expect(
            () => FormattingUtils.getNetworkStatusColor(status),
            returnsNormally,
            reason: 'Should handle $status without throwing',
          );
        }
      });
    });

    group('getNetworkStatusIcon', () {
      test('should return wifi icon for wifi status', () {
        final icon = FormattingUtils.getNetworkStatusIcon(NetworkStatus.wifi);

        expect(icon, Icons.wifi);
      });

      test('should return cellular icon for mobile status', () {
        final icon = FormattingUtils.getNetworkStatusIcon(NetworkStatus.mobile);

        expect(icon, Icons.signal_cellular_4_bar);
      });

      test('should return wifi_off icon for none status', () {
        final icon = FormattingUtils.getNetworkStatusIcon(NetworkStatus.none);

        expect(icon, Icons.wifi_off);
      });

      test('should return help icon for unknown status', () {
        final icon = FormattingUtils.getNetworkStatusIcon(NetworkStatus.unknown);

        expect(icon, Icons.help_outline);
      });

      test('should handle all network statuses', () {
        for (final status in NetworkStatus.values) {
          expect(
            () => FormattingUtils.getNetworkStatusIcon(status),
            returnsNormally,
            reason: 'Should handle $status without throwing',
          );
        }
      });
    });

    group('formatBytes', () {
      test('should format bytes under 1KB', () {
        expect(FormattingUtils.formatBytes(0), '0B');
        expect(FormattingUtils.formatBytes(500), '500B');
        expect(FormattingUtils.formatBytes(1023), '1023B');
      });

      test('should format bytes as KB', () {
        expect(FormattingUtils.formatBytes(1024), '1.0KB');
        expect(FormattingUtils.formatBytes(1536), '1.5KB');
        expect(FormattingUtils.formatBytes(512 * 1024), '512.0KB');
      });

      test('should format bytes as MB', () {
        expect(FormattingUtils.formatBytes(1024 * 1024), '1.0MB');
        expect(FormattingUtils.formatBytes(1536 * 1024), '1.5MB');
        expect(FormattingUtils.formatBytes(10 * 1024 * 1024), '10.0MB');
      });

      test('should handle boundary values correctly', () {
        // Just under 1KB
        expect(FormattingUtils.formatBytes(1023), '1023B');
        // Exactly 1KB
        expect(FormattingUtils.formatBytes(1024), '1.0KB');
        // Just under 1MB
        expect(FormattingUtils.formatBytes(1024 * 1024 - 1), '1024.0KB');
        // Exactly 1MB
        expect(FormattingUtils.formatBytes(1024 * 1024), '1.0MB');
      });

      test('should format large file sizes correctly', () {
        expect(FormattingUtils.formatBytes(100 * 1024 * 1024), '100.0MB');
        expect(FormattingUtils.formatBytes(500 * 1024 * 1024), '500.0MB');
      });
    });

    group('formatCompactDuration', () {
      test('should format seconds only', () {
        const duration = Duration(seconds: 45);
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '45s');
      });

      test('should format zero seconds', () {
        const duration = Duration.zero;
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '0s');
      });

      test('should format minutes and seconds', () {
        const duration = Duration(minutes: 5, seconds: 30);
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '5m 30s');
      });

      test('should format hours and minutes', () {
        const duration = Duration(hours: 2, minutes: 15);
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '2h 15m');
      });

      test('should show hours format for long durations', () {
        const duration = Duration(hours: 2, minutes: 30, seconds: 45);
        final result = FormattingUtils.formatCompactDuration(duration);

        // Should show hours and minutes, ignoring seconds
        expect(result, '2h 30m');
      });

      test('should handle exactly one minute', () {
        const duration = Duration(minutes: 1);
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '1m 0s');
      });

      test('should handle exactly one hour', () {
        const duration = Duration(hours: 1);
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '1h 0m');
      });

      test('should handle duration just under one minute', () {
        const duration = Duration(seconds: 59);
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '59s');
      });

      test('should handle duration just under one hour', () {
        const duration = Duration(minutes: 59, seconds: 59);
        final result = FormattingUtils.formatCompactDuration(duration);

        expect(result, '59m 59s');
      });
    });
  });
}
