import 'dart:async';
import 'notification_service.dart';

// Re-export NotificationModel for convenience
export 'notification_service.dart' show NotificationModel, NotificationType;

/// Smart notification service that filters and manages notifications
/// to prevent notification spam and improve user experience.
///
/// This service extends [NotificationService] and can be used
/// with dependency injection for improved testability.
///
/// Use [SmartNotificationService.withDependencies()] or [SmartNotificationService()]
/// constructor and register via service locator for production use.
class SmartNotificationService extends NotificationService {
  /// Default constructor for dependency injection via service locator.
  SmartNotificationService() : _baseNotificationService = NotificationService();

  /// Named constructor for dependency injection (alias for default constructor).
  /// Use this when creating instances via the service locator.
  SmartNotificationService.withDependencies()
      : _baseNotificationService = NotificationService();

  final NotificationService _baseNotificationService;
  final Map<String, DateTime> _lastNotificationTime = {};
  final Map<String, String> _lastNotificationMessage = {};
  final Map<String, Timer> _pendingNotifications = {};
  
  // Configuration
  static const Duration _duplicateThreshold = Duration(seconds: 2);
  static const Duration _connectionDebounce = Duration(milliseconds: 500);
  static const Duration _scanningDebounce = Duration(milliseconds: 1000);
  
  // Notification categories (mutable to allow configuration)
  // Using Set.from() to ensure mutable sets
  static final Set<String> _silentOperations = Set<String>.from([
    'MTU Configured',
    'Command Sent',
    'Communication Ready',
  ]);

  static final Set<String> _criticalNotifications = Set<String>.from([
    'Connection Failed',
    'Bluetooth Not Supported',
    'Permissions Required',
    'Send Failed',
  ]);

  static final Set<String> _debouncedNotifications = Set<String>.from([
    'Connected',
    'Disconnected',
    'Scan Failed',
    'Bluetooth Disabled',
  ]);

  @override
  Stream<NotificationModel> get notifications => _baseNotificationService.notifications;

  @override
  List<NotificationModel> get allNotifications => _baseNotificationService.allNotifications;

  /// Show info notification with smart filtering
  @override
  void showInfo({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    bool force = false,
  }) {
    if (_shouldShowNotification(title, message, NotificationType.info, force)) {
      _baseNotificationService.showInfo(
        title: title,
        message: message,
        duration: duration,
        metadata: metadata,
      );
      _recordNotification(title, message);
    }
  }

  /// Show success notification with smart filtering
  @override
  void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    bool force = false,
  }) {
    if (_shouldShowNotification(title, message, NotificationType.success, force)) {
      _baseNotificationService.showSuccess(
        title: title,
        message: message,
        duration: duration,
        metadata: metadata,
      );
      _recordNotification(title, message);
    }
  }

  /// Show warning notification with smart filtering
  @override
  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    bool force = false,
  }) {
    if (_shouldShowNotification(title, message, NotificationType.warning, force)) {
      _baseNotificationService.showWarning(
        title: title,
        message: message,
        duration: duration,
        metadata: metadata,
      );
      _recordNotification(title, message);
    }
  }

  /// Show error notification with smart filtering
  @override
  void showError({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    bool force = false,
  }) {
    if (_shouldShowNotification(title, message, NotificationType.error, force)) {
      _baseNotificationService.showError(
        title: title,
        message: message,
        duration: duration,
        metadata: metadata,
      );
      _recordNotification(title, message);
    }
  }

  /// Show connection status notification with debouncing
  @override
  void showConnectionStatus({
    required String title,
    required String message,
    required bool isConnected,
  }) {
    final key = 'connection_${isConnected ? 'connected' : 'disconnected'}';
    
    // Cancel any pending opposite notification
    final oppositeKey = 'connection_${isConnected ? 'disconnected' : 'connected'}';
    _pendingNotifications[oppositeKey]?.cancel();
    _pendingNotifications.remove(oppositeKey);
    
    // Debounce this notification
    _pendingNotifications[key]?.cancel();
    _pendingNotifications[key] = Timer(_connectionDebounce, () {
      if (isConnected) {
        showSuccess(
          title: title,
          message: message,
          duration: const Duration(seconds: 3),
        );
      } else {
        showInfo(
          title: title,
          message: message,
          duration: const Duration(seconds: 2),
        );
      }
      _pendingNotifications.remove(key);
    });
  }

  /// Show scanning status notification with debouncing
  @override
  void showScanningStatus({
    required String title,
    required String message,
    required bool isScanning,
  }) {
    final key = 'scanning_${isScanning ? 'started' : 'stopped'}';
    
    // Cancel any pending opposite notification
    final oppositeKey = 'scanning_${isScanning ? 'stopped' : 'started'}';
    _pendingNotifications[oppositeKey]?.cancel();
    _pendingNotifications.remove(oppositeKey);
    
    // Don't show scanning stop notifications unless there's an error
    if (!isScanning && !title.toLowerCase().contains('error')) {
      return;
    }
    
    // Debounce this notification
    _pendingNotifications[key]?.cancel();
    _pendingNotifications[key] = Timer(_scanningDebounce, () {
      if (isScanning) {
        // Only show scanning start for important notifications
        if (title.toLowerCase().contains('error') || title.toLowerCase().contains('disabled')) {
          showWarning(title: title, message: message);
        }
      }
      _pendingNotifications.remove(key);
    });
  }

  /// Check if notification should be shown
  bool _shouldShowNotification(
    String title,
    String message,
    NotificationType type,
    bool force,
  ) {
    // Always show if forced
    if (force) return true;
    
    // Silence non-critical operations
    if (_silentOperations.contains(title)) {
      return false;
    }
    
    // Always show critical notifications
    if (_criticalNotifications.contains(title)) {
      return true;
    }
    
    // Check for duplicate notifications
    final key = '$title:$message';
    final lastTime = _lastNotificationTime[key];
    final lastMessage = _lastNotificationMessage[title];
    
    if (lastTime != null) {
      final timeSinceLastNotification = DateTime.now().difference(lastTime);
      
      // Prevent duplicate notifications within threshold
      if (timeSinceLastNotification < _duplicateThreshold) {
        return false;
      }
      
      // Prevent same message type spam
      if (lastMessage == message && timeSinceLastNotification < const Duration(seconds: 5)) {
        return false;
      }
    }
    
    return true;
  }

  /// Record notification for filtering logic
  void _recordNotification(String title, String message) {
    final key = '$title:$message';
    _lastNotificationTime[key] = DateTime.now();
    _lastNotificationMessage[title] = message;
  }

  /// Clear notification filters (useful for testing or reset)
  void clearFilters() {
    _lastNotificationTime.clear();
    _lastNotificationMessage.clear();
    for (var timer in _pendingNotifications.values) {
      timer.cancel();
    }
    _pendingNotifications.clear();
  }

  /// Pass-through methods to base service
  @override
  void removeNotification(String id) {
    _baseNotificationService.removeNotification(id);
  }

  @override
  void clearAll() {
    _baseNotificationService.clearAll();
    clearFilters();
  }

  @override
  void clearByType(NotificationType type) {
    _baseNotificationService.clearByType(type);
  }

  @override
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _baseNotificationService.getNotificationsByType(type);
  }

  @override
  int get notificationCount => _baseNotificationService.notificationCount;

  @override
  void dispose() {
    clearFilters();
    _baseNotificationService.dispose();
  }

  /// Configure notification settings
  void configureSettings({
    Set<String>? additionalSilentOperations,
    Set<String>? additionalCriticalNotifications,
    Set<String>? additionalDebouncedNotifications,
  }) {
    if (additionalSilentOperations != null) {
      _silentOperations.addAll(additionalSilentOperations);
    }
    if (additionalCriticalNotifications != null) {
      _criticalNotifications.addAll(additionalCriticalNotifications);
    }
    if (additionalDebouncedNotifications != null) {
      _debouncedNotifications.addAll(additionalDebouncedNotifications);
    }
  }

  /// Get notification statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total_notifications': _baseNotificationService.notificationCount,
      'filtered_notifications': _lastNotificationTime.length,
      'pending_notifications': _pendingNotifications.length,
      'silent_operations': _silentOperations.length,
      'critical_notifications': _criticalNotifications.length,
      'debounced_notifications': _debouncedNotifications.length,
    };
  }
}