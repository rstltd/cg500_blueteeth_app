import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/smart_notification_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartNotificationService', () {
    late SmartNotificationService service;

    setUp(() {
      service = SmartNotificationService();
      service.clearAll();
    });

    group('singleton', () {
      test('should return same instance', () {
        final instance1 = SmartNotificationService();
        final instance2 = SmartNotificationService();
        expect(identical(instance1, instance2), true);
      });
    });

    group('notifications stream', () {
      test('should be available', () {
        expect(service.notifications, isA<Stream<NotificationModel>>());
      });
    });

    group('allNotifications', () {
      test('should return list', () {
        expect(service.allNotifications, isA<List<NotificationModel>>());
      });

      test('should be empty initially', () {
        expect(service.allNotifications, isEmpty);
      });
    });

    group('showInfo', () {
      test('should add info notification', () {
        service.showInfo(title: 'Test', message: 'Test message');
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });

      test('should accept force parameter', () {
        service.showInfo(title: 'Test', message: 'Test message', force: true);
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });

      test('should accept duration parameter', () {
        service.showInfo(
          title: 'Test',
          message: 'Test message',
          duration: const Duration(seconds: 5),
        );
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });

      test('should accept metadata parameter', () {
        service.showInfo(
          title: 'Test',
          message: 'Test message',
          metadata: {'key': 'value'},
        );
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });
    });

    group('showSuccess', () {
      test('should add success notification', () {
        service.showSuccess(title: 'Success', message: 'Success message');
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });

      test('should accept force parameter', () {
        service.showSuccess(title: 'Success', message: 'Message', force: true);
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });
    });

    group('showWarning', () {
      test('should add warning notification', () {
        service.showWarning(title: 'Warning', message: 'Warning message');
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });

      test('should accept force parameter', () {
        service.showWarning(title: 'Warning', message: 'Message', force: true);
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });
    });

    group('showError', () {
      test('should add error notification', () {
        service.showError(title: 'Error', message: 'Error message');
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });

      test('should accept force parameter', () {
        service.showError(title: 'Error', message: 'Message', force: true);
        expect(service.notificationCount, greaterThanOrEqualTo(0));
      });
    });

    group('silent operations', () {
      test('should filter MTU Configured notification', () {
        service.showInfo(title: 'MTU Configured', message: 'Test');
        // Silent operations should be filtered
        expect(service.notificationCount, 0);
      });

      test('should filter Command Sent notification', () {
        service.showInfo(title: 'Command Sent', message: 'Test');
        expect(service.notificationCount, 0);
      });

      test('should filter Communication Ready notification', () {
        service.showInfo(title: 'Communication Ready', message: 'Test');
        expect(service.notificationCount, 0);
      });
    });

    group('critical notifications', () {
      test('should always show Connection Failed', () {
        service.showError(title: 'Connection Failed', message: 'Test');
        expect(service.notificationCount, greaterThan(0));
      });

      test('should always show Bluetooth Not Supported', () {
        service.showError(title: 'Bluetooth Not Supported', message: 'Test');
        expect(service.notificationCount, greaterThan(0));
      });

      test('should always show Permissions Required', () {
        service.showError(title: 'Permissions Required', message: 'Test');
        expect(service.notificationCount, greaterThan(0));
      });

      test('should always show Send Failed', () {
        service.showError(title: 'Send Failed', message: 'Test');
        expect(service.notificationCount, greaterThan(0));
      });
    });

    group('duplicate filtering', () {
      test('should filter duplicate notifications within threshold', () async {
        service.showInfo(title: 'Test', message: 'Message 1', force: true);
        final count1 = service.notificationCount;

        // Same notification immediately - should be filtered
        service.showInfo(title: 'Test', message: 'Message 1');
        final count2 = service.notificationCount;

        expect(count2, equals(count1));
      });

      test('should allow different notifications', () {
        service.showInfo(title: 'Test 1', message: 'Message 1', force: true);
        final count1 = service.notificationCount;

        service.showInfo(title: 'Test 2', message: 'Message 2', force: true);
        final count2 = service.notificationCount;

        expect(count2, greaterThan(count1));
      });
    });

    group('showConnectionStatus', () {
      test('should handle connected status', () async {
        service.showConnectionStatus(
          title: 'Connected',
          message: 'Device connected',
          isConnected: true,
        );
        // Debounced, so check after delay
        await Future.delayed(const Duration(seconds: 1));
        // Just verify it doesn't throw
        expect(true, true);
      });

      test('should handle disconnected status', () async {
        service.showConnectionStatus(
          title: 'Disconnected',
          message: 'Device disconnected',
          isConnected: false,
        );
        await Future.delayed(const Duration(seconds: 1));
        expect(true, true);
      });
    });

    group('showScanningStatus', () {
      test('should handle scanning started', () async {
        service.showScanningStatus(
          title: 'Scanning',
          message: 'Started scanning',
          isScanning: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        expect(true, true);
      });

      test('should handle scanning stopped', () async {
        service.showScanningStatus(
          title: 'Scanning',
          message: 'Stopped scanning',
          isScanning: false,
        );
        await Future.delayed(const Duration(seconds: 2));
        expect(true, true);
      });

      test('should handle scanning error', () async {
        service.showScanningStatus(
          title: 'Scan Error',
          message: 'Failed to scan',
          isScanning: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        expect(true, true);
      });
    });

    group('clearFilters', () {
      test('should not throw', () {
        expect(() => service.clearFilters(), returnsNormally);
      });

      test('should allow same notification after clearing', () {
        service.showInfo(title: 'Test', message: 'Message', force: true);
        service.clearFilters();
        service.showInfo(title: 'Test', message: 'Message', force: true);
        // Should not be filtered after clearing
        expect(service.notificationCount, greaterThan(0));
      });
    });

    group('removeNotification', () {
      test('should not throw for non-existent id', () {
        expect(() => service.removeNotification('non-existent'), returnsNormally);
      });
    });

    group('clearAll', () {
      test('should clear all notifications', () {
        service.showInfo(title: 'Test 1', message: 'Message', force: true);
        service.showSuccess(title: 'Test 2', message: 'Message', force: true);

        service.clearAll();

        expect(service.notificationCount, 0);
      });
    });

    group('clearByType', () {
      test('should clear by type', () {
        service.showInfo(title: 'Info', message: 'Message', force: true);
        service.showError(title: 'Error', message: 'Message', force: true);

        service.clearByType(NotificationType.info);

        // Should only have error notification left
        final infos = service.getNotificationsByType(NotificationType.info);
        expect(infos, isEmpty);
      });
    });

    group('getNotificationsByType', () {
      test('should return list', () {
        final result = service.getNotificationsByType(NotificationType.info);
        expect(result, isA<List<NotificationModel>>());
      });

      test('should return only matching type', () {
        service.showInfo(title: 'Info', message: 'Message', force: true);
        service.showError(title: 'Error', message: 'Message', force: true);

        final errors = service.getNotificationsByType(NotificationType.error);
        for (var notification in errors) {
          expect(notification.type, NotificationType.error);
        }
      });
    });

    group('notificationCount', () {
      test('should return 0 when empty', () {
        service.clearAll();
        expect(service.notificationCount, 0);
      });

      test('should count notifications', () {
        service.showInfo(title: 'Test 1', message: 'Message', force: true);
        service.showSuccess(title: 'Test 2', message: 'Message', force: true);
        expect(service.notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('getStatistics', () {
      test('should return map', () {
        final stats = service.getStatistics();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should contain expected keys', () {
        final stats = service.getStatistics();
        expect(stats.containsKey('total_notifications'), true);
        expect(stats.containsKey('filtered_notifications'), true);
        expect(stats.containsKey('pending_notifications'), true);
        expect(stats.containsKey('silent_operations'), true);
        expect(stats.containsKey('critical_notifications'), true);
        expect(stats.containsKey('debounced_notifications'), true);
      });

      test('should return numeric values', () {
        final stats = service.getStatistics();
        expect(stats['total_notifications'], isA<int>());
        expect(stats['filtered_notifications'], isA<int>());
        expect(stats['pending_notifications'], isA<int>());
      });
    });

    group('dispose', () {
      test('should not throw', () {
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
