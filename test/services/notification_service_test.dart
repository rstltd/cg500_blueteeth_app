import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';

void main() {
  group('NotificationType', () {
    test('should have 4 notification types', () {
      expect(NotificationType.values.length, 4);
    });

    test('should contain info type', () {
      expect(NotificationType.values, contains(NotificationType.info));
    });

    test('should contain success type', () {
      expect(NotificationType.values, contains(NotificationType.success));
    });

    test('should contain warning type', () {
      expect(NotificationType.values, contains(NotificationType.warning));
    });

    test('should contain error type', () {
      expect(NotificationType.values, contains(NotificationType.error));
    });
  });

  group('NotificationModel', () {
    group('constructor', () {
      test('should create notification with required fields', () {
        final now = DateTime.now();
        final notification = NotificationModel(
          id: 'test-id',
          title: 'Test Title',
          message: 'Test Message',
          type: NotificationType.info,
          timestamp: now,
        );

        expect(notification.id, 'test-id');
        expect(notification.title, 'Test Title');
        expect(notification.message, 'Test Message');
        expect(notification.type, NotificationType.info);
        expect(notification.timestamp, now);
      });

      test('should have default empty metadata', () {
        final notification = NotificationModel(
          id: 'test-id',
          title: 'Test',
          message: 'Message',
          type: NotificationType.info,
          timestamp: DateTime.now(),
        );
        expect(notification.metadata, isEmpty);
      });

      test('should have default null duration', () {
        final notification = NotificationModel(
          id: 'test-id',
          title: 'Test',
          message: 'Message',
          type: NotificationType.info,
          timestamp: DateTime.now(),
        );
        expect(notification.duration, isNull);
      });

      test('should create with custom metadata', () {
        final notification = NotificationModel(
          id: 'test-id',
          title: 'Test',
          message: 'Message',
          type: NotificationType.info,
          timestamp: DateTime.now(),
          metadata: {'key': 'value'},
        );
        expect(notification.metadata['key'], 'value');
      });
    });

    group('factory info', () {
      test('should create info notification', () {
        final notification = NotificationModel.info(
          title: 'Info Title',
          message: 'Info Message',
        );

        expect(notification.type, NotificationType.info);
        expect(notification.title, 'Info Title');
        expect(notification.message, 'Info Message');
        expect(notification.id, isNotEmpty);
        expect(notification.timestamp, isNotNull);
      });

      test('should have default duration of 3 seconds', () {
        final notification = NotificationModel.info(
          title: 'Info',
          message: 'Message',
        );
        expect(notification.duration, const Duration(seconds: 3));
      });

      test('should accept custom duration', () {
        final notification = NotificationModel.info(
          title: 'Info',
          message: 'Message',
          duration: const Duration(seconds: 10),
        );
        expect(notification.duration, const Duration(seconds: 10));
      });

      test('should accept metadata', () {
        final notification = NotificationModel.info(
          title: 'Info',
          message: 'Message',
          metadata: {'action': 'test'},
        );
        expect(notification.metadata['action'], 'test');
      });
    });

    group('factory success', () {
      test('should create success notification', () {
        final notification = NotificationModel.success(
          title: 'Success Title',
          message: 'Success Message',
        );

        expect(notification.type, NotificationType.success);
        expect(notification.title, 'Success Title');
        expect(notification.message, 'Success Message');
      });

      test('should have default duration of 3 seconds', () {
        final notification = NotificationModel.success(
          title: 'Success',
          message: 'Message',
        );
        expect(notification.duration, const Duration(seconds: 3));
      });
    });

    group('factory warning', () {
      test('should create warning notification', () {
        final notification = NotificationModel.warning(
          title: 'Warning Title',
          message: 'Warning Message',
        );

        expect(notification.type, NotificationType.warning);
        expect(notification.title, 'Warning Title');
        expect(notification.message, 'Warning Message');
      });

      test('should have default duration of 5 seconds', () {
        final notification = NotificationModel.warning(
          title: 'Warning',
          message: 'Message',
        );
        expect(notification.duration, const Duration(seconds: 5));
      });
    });

    group('factory error', () {
      test('should create error notification', () {
        final notification = NotificationModel.error(
          title: 'Error Title',
          message: 'Error Message',
        );

        expect(notification.type, NotificationType.error);
        expect(notification.title, 'Error Title');
        expect(notification.message, 'Error Message');
      });

      test('should have default duration of 7 seconds', () {
        final notification = NotificationModel.error(
          title: 'Error',
          message: 'Message',
        );
        expect(notification.duration, const Duration(seconds: 7));
      });
    });

    group('unique IDs', () {
      test('should generate unique IDs for each notification', () async {
        final notification1 = NotificationModel.info(
          title: 'Test 1',
          message: 'Message 1',
        );

        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 2));

        final notification2 = NotificationModel.info(
          title: 'Test 2',
          message: 'Message 2',
        );

        expect(notification1.id, isNot(equals(notification2.id)));
      });
    });
  });

  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
      notificationService.clearAll();
    });

    group('singleton', () {
      test('should return same instance', () {
        final instance1 = NotificationService();
        final instance2 = NotificationService();
        expect(identical(instance1, instance2), true);
      });
    });

    group('showInfo', () {
      test('should add info notification', () {
        notificationService.showInfo(
          title: 'Info',
          message: 'Info message',
        );

        expect(notificationService.notificationCount, 1);
        expect(notificationService.allNotifications.first.type, NotificationType.info);
      });

      test('should accept custom duration', () {
        notificationService.showInfo(
          title: 'Info',
          message: 'Info message',
          duration: const Duration(seconds: 10),
        );

        expect(notificationService.allNotifications.first.duration, const Duration(seconds: 10));
      });

      test('should accept metadata', () {
        notificationService.showInfo(
          title: 'Info',
          message: 'Info message',
          metadata: {'key': 'value'},
        );

        expect(notificationService.allNotifications.first.metadata['key'], 'value');
      });
    });

    group('showSuccess', () {
      test('should add success notification', () {
        notificationService.showSuccess(
          title: 'Success',
          message: 'Success message',
        );

        expect(notificationService.notificationCount, 1);
        expect(notificationService.allNotifications.first.type, NotificationType.success);
      });
    });

    group('showWarning', () {
      test('should add warning notification', () {
        notificationService.showWarning(
          title: 'Warning',
          message: 'Warning message',
        );

        expect(notificationService.notificationCount, 1);
        expect(notificationService.allNotifications.first.type, NotificationType.warning);
      });
    });

    group('showError', () {
      test('should add error notification', () {
        notificationService.showError(
          title: 'Error',
          message: 'Error message',
        );

        expect(notificationService.notificationCount, 1);
        expect(notificationService.allNotifications.first.type, NotificationType.error);
      });
    });

    group('removeNotification', () {
      test('should remove notification by id', () {
        notificationService.showInfo(title: 'Test', message: 'Message');
        final id = notificationService.allNotifications.first.id;

        notificationService.removeNotification(id);

        expect(notificationService.notificationCount, 0);
      });

      test('should not throw when id not found', () {
        notificationService.showInfo(title: 'Test', message: 'Message');

        expect(
          () => notificationService.removeNotification('non-existent-id'),
          returnsNormally,
        );
        expect(notificationService.notificationCount, 1);
      });
    });

    group('clearAll', () {
      test('should clear all notifications', () {
        notificationService.showInfo(title: 'Info', message: 'Message');
        notificationService.showSuccess(title: 'Success', message: 'Message');
        notificationService.showWarning(title: 'Warning', message: 'Message');
        notificationService.showError(title: 'Error', message: 'Message');

        expect(notificationService.notificationCount, 4);

        notificationService.clearAll();

        expect(notificationService.notificationCount, 0);
      });

      test('should handle empty list', () {
        notificationService.clearAll();
        expect(notificationService.notificationCount, 0);
      });
    });

    group('clearByType', () {
      test('should clear only info notifications', () {
        notificationService.showInfo(title: 'Info', message: 'Message');
        notificationService.showSuccess(title: 'Success', message: 'Message');
        notificationService.showInfo(title: 'Info 2', message: 'Message');

        notificationService.clearByType(NotificationType.info);

        expect(notificationService.notificationCount, 1);
        expect(notificationService.allNotifications.first.type, NotificationType.success);
      });

      test('should clear only error notifications', () {
        notificationService.showInfo(title: 'Info', message: 'Message');
        notificationService.showError(title: 'Error', message: 'Message');
        notificationService.showError(title: 'Error 2', message: 'Message');

        notificationService.clearByType(NotificationType.error);

        expect(notificationService.notificationCount, 1);
        expect(notificationService.allNotifications.first.type, NotificationType.info);
      });

      test('should handle no matching type', () {
        notificationService.showInfo(title: 'Info', message: 'Message');

        notificationService.clearByType(NotificationType.error);

        expect(notificationService.notificationCount, 1);
      });
    });

    group('getNotificationsByType', () {
      test('should return only notifications of specified type', () {
        notificationService.showInfo(title: 'Info', message: 'Message');
        notificationService.showSuccess(title: 'Success', message: 'Message');
        notificationService.showInfo(title: 'Info 2', message: 'Message');

        final infoNotifications = notificationService.getNotificationsByType(NotificationType.info);

        expect(infoNotifications.length, 2);
        expect(infoNotifications.every((n) => n.type == NotificationType.info), true);
      });

      test('should return empty list when no matching type', () {
        notificationService.showInfo(title: 'Info', message: 'Message');

        final errorNotifications = notificationService.getNotificationsByType(NotificationType.error);

        expect(errorNotifications, isEmpty);
      });
    });

    group('allNotifications', () {
      test('should return copy of notifications list', () {
        notificationService.showInfo(title: 'Info', message: 'Message');

        final notifications = notificationService.allNotifications;
        notifications.clear(); // Modify returned list

        expect(notificationService.notificationCount, 1); // Original should be unchanged
      });
    });

    group('notificationCount', () {
      test('should return 0 when empty', () {
        expect(notificationService.notificationCount, 0);
      });

      test('should return correct count', () {
        notificationService.showInfo(title: 'Info', message: 'Message');
        notificationService.showSuccess(title: 'Success', message: 'Message');
        notificationService.showWarning(title: 'Warning', message: 'Message');

        expect(notificationService.notificationCount, 3);
      });
    });

    group('notifications stream', () {
      test('should emit notifications when added', () async {
        final emissions = <NotificationModel>[];
        final subscription = notificationService.notifications.listen(emissions.add);

        notificationService.showInfo(title: 'Test 1', message: 'Message 1');
        notificationService.showSuccess(title: 'Test 2', message: 'Message 2');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emissions.length, 2);
        expect(emissions[0].title, 'Test 1');
        expect(emissions[1].title, 'Test 2');

        await subscription.cancel();
      });
    });

    group('multiple notifications', () {
      test('should maintain order of notifications', () {
        notificationService.showInfo(title: 'First', message: 'Message');
        notificationService.showSuccess(title: 'Second', message: 'Message');
        notificationService.showWarning(title: 'Third', message: 'Message');

        final notifications = notificationService.allNotifications;

        expect(notifications[0].title, 'First');
        expect(notifications[1].title, 'Second');
        expect(notifications[2].title, 'Third');
      });
    });
  });
}
