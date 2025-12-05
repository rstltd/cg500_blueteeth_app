import 'dart:async';
import '../../services/notification_service.dart';

/// Interface for notification services.
///
/// Implementations of this interface provide user notification capabilities
/// with different severity levels and categories.
abstract class NotificationServiceInterface {
  /// Stream of notifications for UI consumption.
  Stream<NotificationModel> get notifications;

  /// Show an informational notification.
  void showInfo({
    required String title,
    required String message,
  });

  /// Show a success notification.
  void showSuccess({
    required String title,
    required String message,
  });

  /// Show a warning notification.
  void showWarning({
    required String title,
    required String message,
  });

  /// Show an error notification.
  void showError({
    required String title,
    required String message,
  });

  /// Show a connection status notification.
  void showConnectionStatus({
    required String title,
    required String message,
    required bool isConnected,
  });

  /// Show a scanning status notification.
  void showScanningStatus({
    required String title,
    required String message,
    required bool isScanning,
  });

  /// Release all resources held by this service.
  void dispose();
}
