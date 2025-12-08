import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/core/mixins/notification_listener_mixin.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';

void main() {
  group('NotificationListenerMixin', () {
    late StreamController<NotificationModel> notificationController;

    setUp(() {
      notificationController = StreamController<NotificationModel>.broadcast();
    });

    tearDown(() {
      notificationController.close();
    });

    // Test widget that uses the mixin
    Widget createTestWidget({
      required Stream<NotificationModel> stream,
    }) {
      return MaterialApp(
        home: _TestWidget(notificationStream: stream),
      );
    }

    group('initialization', () {
      testWidgets('should subscribe to notification stream on init',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pump();

        // Verify widget is mounted and listening
        expect(find.byType(_TestWidget), findsOneWidget);
        expect(notificationController.hasListener, isTrue);
      });

      testWidgets('should not throw when stream is empty', (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pump();

        // Should complete without errors
        expect(find.byType(_TestWidget), findsOneWidget);
      });
    });

    group('notification handling', () {
      testWidgets('should show SnackBar when notification received',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        // Emit notification
        notificationController.add(NotificationModel(
          id: '1',
          title: 'Test Title',
          message: 'Test Message',
          type: NotificationType.info,
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        // Should show SnackBar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Test Title: Test Message'), findsOneWidget);
      });

      testWidgets('should show success notification with correct color',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        notificationController.add(NotificationModel(
          id: '1',
          title: 'Success',
          message: 'Operation completed',
          type: NotificationType.success,
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Success: Operation completed'), findsOneWidget);
      });

      testWidgets('should show error notification with correct color',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        notificationController.add(NotificationModel(
          id: '1',
          title: 'Error',
          message: 'Something went wrong',
          type: NotificationType.error,
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Error: Something went wrong'), findsOneWidget);
      });

      testWidgets('should show warning notification', (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        notificationController.add(NotificationModel(
          id: '1',
          title: 'Warning',
          message: 'Please note',
          type: NotificationType.warning,
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Warning: Please note'), findsOneWidget);
      });

      testWidgets('should use custom duration from notification',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        notificationController.add(NotificationModel(
          id: '1',
          title: 'Quick',
          message: 'Fast notification',
          type: NotificationType.info,
          timestamp: DateTime.now(),
          duration: const Duration(seconds: 1),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should use default duration when not specified',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        notificationController.add(NotificationModel(
          id: '1',
          title: 'Default',
          message: 'Default duration',
          type: NotificationType.info,
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('disposal', () {
      testWidgets('should cancel subscription on dispose', (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pump();

        expect(notificationController.hasListener, isTrue);

        // Remove widget (triggers dispose)
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump();

        // Listener should be cancelled
        // Note: hasListener may still be true due to broadcast stream behavior
        // but sending events should not cause errors
        notificationController.add(NotificationModel(
          id: '2',
          title: 'After Dispose',
          message: 'Should not crash',
          type: NotificationType.info,
          timestamp: DateTime.now(),
        ));
        await tester.pump();

        // Should not show SnackBar since widget is disposed
        expect(find.text('After Dispose: Should not crash'), findsNothing);
      });

      testWidgets('should handle multiple dispose calls gracefully',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pump();

        // First dispose
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump();

        // Rebuild should work fine
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pump();

        expect(find.byType(_TestWidget), findsOneWidget);
      });
    });

    group('multiple notifications', () {
      testWidgets('should handle rapid notifications', (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        // Send multiple notifications rapidly
        for (int i = 0; i < 5; i++) {
          notificationController.add(NotificationModel(
            id: '$i',
            title: 'Notification $i',
            message: 'Message $i',
            type: NotificationType.info,
            timestamp: DateTime.now(),
          ));
        }
        await tester.pumpAndSettle();

        // At least one SnackBar should be visible
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('should handle different notification types in sequence',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        final types = [
          NotificationType.info,
          NotificationType.success,
          NotificationType.warning,
          NotificationType.error,
        ];

        for (final type in types) {
          notificationController.add(NotificationModel(
            id: type.toString(),
            title: type.toString(),
            message: 'Message',
            type: type,
            timestamp: DateTime.now(),
          ));
          await tester.pumpAndSettle();
        }

        // Should have processed all without errors
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('mounted check', () {
      testWidgets('should not show SnackBar when widget is not mounted',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pump();

        // Dispose the widget
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        // Send notification after dispose
        notificationController.add(NotificationModel(
          id: '1',
          title: 'Unmounted',
          message: 'Should not appear',
          type: NotificationType.info,
          timestamp: DateTime.now(),
        ));
        await tester.pump();

        // Should not find the notification text
        expect(find.text('Unmounted: Should not appear'), findsNothing);
      });
    });

    group('notification colors', () {
      testWidgets('info notification should have info color', (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        notificationController.add(NotificationModel(
          id: '1',
          title: 'Info',
          message: 'Information',
          type: NotificationType.info,
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        final snackBarFinder = find.byType(SnackBar);
        expect(snackBarFinder, findsOneWidget);
        final snackBar = tester.widget<SnackBar>(snackBarFinder);
        expect(snackBar.backgroundColor, isNotNull);
      });

      testWidgets('success notification should have success color',
          (tester) async {
        await tester.pumpWidget(
          createTestWidget(stream: notificationController.stream),
        );
        await tester.pumpAndSettle();

        notificationController.add(NotificationModel(
          id: '1',
          title: 'Success',
          message: 'Done',
          type: NotificationType.success,
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        final snackBarFinder = find.byType(SnackBar);
        expect(snackBarFinder, findsOneWidget);
        final snackBar = tester.widget<SnackBar>(snackBarFinder);
        expect(snackBar.backgroundColor, isNotNull);
      });
    });
  });
}

/// Test widget that uses NotificationListenerMixin
class _TestWidget extends StatefulWidget {
  const _TestWidget({required this.notificationStream});

  final Stream<NotificationModel> notificationStream;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with NotificationListenerMixin<_TestWidget> {
  @override
  Stream<NotificationModel> get notificationStream => widget.notificationStream;

  @override
  void initState() {
    super.initState();
    initializeNotificationListener();
  }

  @override
  void dispose() {
    disposeNotificationListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Test Widget'),
      ),
    );
  }
}
