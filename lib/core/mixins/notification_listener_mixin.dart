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
/// - Properly cancel subscriptions on dispose
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

  /// Handle incoming notifications by showing a SnackBar.
  void _handleNotification(NotificationModel notification) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          backgroundColor: getNotificationColor(notification.type),
          duration: notification.duration ?? const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Get the color for a notification type.
  /// Can be overridden in implementing classes for custom colors.
  @protected
  Color getNotificationColor(NotificationType type) {
    return FormattingUtils.getNotificationColor(type);
  }
}
