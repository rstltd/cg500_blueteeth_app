import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/network_service.dart';

/// Utility class for common formatting operations used across the app
class FormattingUtils {
  FormattingUtils._();

  /// Format a DateTime for display
  /// Returns format: DD/MM/YYYY HH:MM
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format a Duration for display
  /// Returns format: HH:MM:SS
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  /// Get the color for a notification type
  static Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  /// Get the color for a network status
  static Color getNetworkStatusColor(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return Colors.green;
      case NetworkStatus.mobile:
        return Colors.orange;
      case NetworkStatus.none:
        return Colors.red;
      case NetworkStatus.unknown:
        return Colors.grey;
    }
  }

  /// Get the icon for a network status
  static IconData getNetworkStatusIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return Icons.wifi;
      case NetworkStatus.mobile:
        return Icons.signal_cellular_4_bar;
      case NetworkStatus.none:
        return Icons.wifi_off;
      case NetworkStatus.unknown:
        return Icons.help_outline;
    }
  }

  /// Format bytes for display (e.g., "1.5MB", "512KB")
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Format a compact duration (e.g., "2h 15m", "45s")
  static String formatCompactDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
