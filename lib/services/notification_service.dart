import 'dart:async';

enum NotificationType {
  info,
  success,
  warning,
  error,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.duration,
    this.metadata = const {},
  });

  factory NotificationModel.info({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.info,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 3),
      metadata: metadata,
    );
  }

  factory NotificationModel.success({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.success,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 3),
      metadata: metadata,
    );
  }

  factory NotificationModel.warning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.warning,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 5),
      metadata: metadata,
    );
  }

  factory NotificationModel.error({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.error,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 7),
      metadata: metadata,
    );
  }
}

/// Service for managing in-app notifications.
///
/// Use [NotificationService()] constructor and register via service locator
/// for production use.
class NotificationService {
  /// Default constructor for dependency injection via service locator.
  NotificationService()
      : _notificationController = StreamController<NotificationModel>.broadcast(),
        _notifications = [];

  /// Named constructor for testing that creates a fresh instance.
  NotificationService.forTesting()
      : _notificationController = StreamController<NotificationModel>.broadcast(),
        _notifications = [];

  final StreamController<NotificationModel> _notificationController;
  final List<NotificationModel> _notifications;

  Stream<NotificationModel> get notifications => _notificationController.stream;
  List<NotificationModel> get allNotifications => List.from(_notifications);

  void showInfo({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    final notification = NotificationModel.info(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
    );
    _addNotification(notification);
  }

  void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    final notification = NotificationModel.success(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
    );
    _addNotification(notification);
  }

  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    final notification = NotificationModel.warning(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
    );
    _addNotification(notification);
  }

  void showError({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    final notification = NotificationModel.error(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
    );
    _addNotification(notification);
  }

  void _addNotification(NotificationModel notification) {
    _notifications.add(notification);
    _notificationController.add(notification);
    
    // Note: Consider using Logger for debug output if needed

    // Auto-remove notification after duration
    if (notification.duration != null) {
      Timer(notification.duration!, () {
        removeNotification(notification.id);
      });
    }
  }

  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
  }

  void clearAll() {
    _notifications.clear();
  }

  void clearByType(NotificationType type) {
    _notifications.removeWhere((notification) => notification.type == type);
  }

  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  int get notificationCount => _notifications.length;

  /// Show a connection status notification.
  void showConnectionStatus({
    required String title,
    required String message,
    required bool isConnected,
  }) {
    if (isConnected) {
      showSuccess(title: title, message: message);
    } else {
      showInfo(title: title, message: message);
    }
  }

  /// Show a scanning status notification.
  void showScanningStatus({
    required String title,
    required String message,
    required bool isScanning,
  }) {
    if (isScanning) {
      showInfo(title: title, message: message);
    }
  }

  void dispose() {
    _notificationController.close();
  }
}