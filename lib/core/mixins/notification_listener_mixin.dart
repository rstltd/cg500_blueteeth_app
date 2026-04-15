import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../utils/formatting_utils.dart';

/// Mixin that provides notification listening functionality for StatefulWidgets.
///
/// This mixin eliminates duplicated notification handling code across Views
/// by providing a standardized way to:
/// - Subscribe to notification streams
/// - Display SnackBar notifications with proper colors
/// - Clear outdated notifications when new ones arrive
/// - Properly cancel subscriptions on dispose
///
/// Note: Notification filtering is handled at the source level by
/// ConfigurableBleNotificationDelegate. This mixin simply displays
/// whatever notifications pass through the stream.
///
/// Usage:
/// ```dart
/// class _MyViewState extends State<MyView> with NotificationListenerMixin<MyView> {
///   @override
///   Stream<NotificationModel> get notificationStream => _controller.notificationStream;
///
///   @override
///   void initState() {
///     super.initState();
///     initializeNotificationListener();
///   }
///
///   @override
///   void dispose() {
///     disposeNotificationListener();
///     super.dispose();
///   }
/// }
/// ```
mixin NotificationListenerMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<NotificationModel>? _notificationSubscription;

  /// Override this getter to provide the notification stream source.
  Stream<NotificationModel> get notificationStream;

  /// Initialize the notification listener.
  /// Call this in initState() after super.initState().
  @protected
  void initializeNotificationListener() {
    _notificationSubscription = notificationStream.listen(_handleNotification);
  }

  /// Dispose of the notification listener.
  /// Call this in dispose() before super.dispose().
  @protected
  void disposeNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  /// Get appropriate duration based on notification type.
  /// Important notifications get slightly longer display time.
  Duration _getNotificationDuration(NotificationModel notification) {
    if (notification.duration != null) {
      return notification.duration!;
    }
    switch (notification.type) {
      case NotificationType.error:
        return const Duration(seconds: 4);
      case NotificationType.warning:
        return const Duration(seconds: 3);
      case NotificationType.success:
        return const Duration(seconds: 2);
      case NotificationType.info:
        return const Duration(milliseconds: 1500);
    }
  }

  /// Handle incoming notifications by showing a SnackBar.
  void _handleNotification(NotificationModel notification) {
    if (!mounted) return;

    // Clear any existing SnackBars to prevent queue buildup
    ScaffoldMessenger.of(context).clearSnackBars();

    // Render an inline recovery action when the source supplied one.
    final notificationAction = notification.action;
    SnackBarAction? snackBarAction;
    if (notificationAction != null) {
      snackBarAction = SnackBarAction(
        label: notificationAction.label,
        onPressed: notificationAction.onPressed,
      );
    }

    // Show the new notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.message}'),
        backgroundColor: getNotificationColor(notification.type),
        duration: _getNotificationDuration(notification),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: snackBarAction,
      ),
    );
  }

  /// Get the color for a notification type.
  /// Can be overridden in implementing classes for custom colors.
  @protected
  Color getNotificationColor(NotificationType type) {
    return FormattingUtils.getNotificationColor(type);
  }
}
