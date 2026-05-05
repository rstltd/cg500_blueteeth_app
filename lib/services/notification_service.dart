import 'dart:async';

enum NotificationType {
  info,
  success,
  warning,
  error,
}

/// A tappable action attached to a notification — the View layer renders it
/// as a SnackBar action button so the user can recover without opening
/// settings. Kept as a small typed class instead of stuffing callbacks into
/// `metadata` so the contract is explicit.
class NotificationAction {
  const NotificationAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final void Function() onPressed;
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  /// Optional recovery action surfaced as a SnackBar action button.
  final NotificationAction? action;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.duration,
    this.metadata = const {},
    this.action,
  });

  factory NotificationModel.info({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.info,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 3),
      metadata: metadata,
      action: action,
    );
  }

  factory NotificationModel.success({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.success,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 3),
      metadata: metadata,
      action: action,
    );
  }

  factory NotificationModel.warning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.warning,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 5),
      metadata: metadata,
      action: action,
    );
  }

  factory NotificationModel.error({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.error,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 7),
      metadata: metadata,
      action: action,
    );
  }
}

/// Filtering rules consulted by [NotificationService] before emitting.
/// When a service is constructed without a filter, every `show*` call is
/// emitted unconditionally; when one is supplied, the rules below decide
/// whether a given notification reaches subscribers.
///
/// Filter STATE (last-emit timestamps, pending debounce timers) lives in
/// the service, not here, so the same filter config can be reused across
/// independent service instances without leaking state between them.
class NotificationFilter {
  NotificationFilter({
    Set<String>? silentTitles,
    Set<String>? criticalTitles,
    Set<String>? debouncedTitles,
    this.duplicateThreshold = const Duration(seconds: 2),
    this.sameMessageSpamThreshold = const Duration(seconds: 5),
    this.connectionDebounce = const Duration(milliseconds: 500),
    this.scanningDebounce = const Duration(milliseconds: 1000),
  })  : silentTitles = Set.of(silentTitles ?? const <String>{}),
        criticalTitles = Set.of(criticalTitles ?? const <String>{}),
        debouncedTitles = Set.of(debouncedTitles ?? const <String>{});

  /// Defaults tuned for this app's BLE flow. Internal-only operations
  /// (MTU config, command echo) are silenced; user-actionable failures
  /// always pass; connection/scan toggles are debounced to absorb the
  /// natural jitter of broadcast streams.
  factory NotificationFilter.bleDefaults() {
    return NotificationFilter(
      silentTitles: {
        'MTU Configured',
        'Command Sent',
        'Communication Ready',
      },
      criticalTitles: {
        'Connection Failed',
        'Bluetooth Not Supported',
        'Permissions Required',
        'Send Failed',
      },
      debouncedTitles: {
        'Connected',
        'Disconnected',
        'Scan Failed',
        'Bluetooth Disabled',
      },
    );
  }

  /// Titles that should never reach the user.
  final Set<String> silentTitles;

  /// Titles that always pass, even within the dedup window.
  final Set<String> criticalTitles;

  /// Titles whose connect/scan toggles get debounced.
  final Set<String> debouncedTitles;

  /// Window inside which an identical title:message pair is treated as a
  /// duplicate and suppressed.
  final Duration duplicateThreshold;

  /// Window inside which two notifications sharing the same title and
  /// message are suppressed as spam (separate from duplicate detection
  /// because it ignores other titles between them).
  final Duration sameMessageSpamThreshold;

  /// Debounce delay before emitting a connection status change.
  final Duration connectionDebounce;

  /// Debounce delay before emitting a scanning status change.
  final Duration scanningDebounce;
}

/// In-app notification service.
///
/// The default constructor produces an unfiltered service; use
/// [NotificationService.smart] for the production wiring that suppresses
/// noise (internal BLE chatter, duplicates, debounced connect/scan
/// toggles). Callers always inject the same [NotificationService] type —
/// the filter is an internal concern.
class NotificationService {
  /// Unfiltered service. Every `show*` call is emitted as-is.
  NotificationService()
      : _filter = null,
        _notificationController =
            StreamController<NotificationModel>.broadcast(),
        _notifications = [];

  /// Service with filtering enabled. The filter is mutable: callers can
  /// add to its sets via [configureSettings] without reconstructing the
  /// service.
  NotificationService.withFilter(NotificationFilter filter)
      : _filter = filter,
        _notificationController =
            StreamController<NotificationModel>.broadcast(),
        _notifications = [];

  /// Production wiring: filtered with BLE-tuned defaults.
  factory NotificationService.smart() =>
      NotificationService.withFilter(NotificationFilter.bleDefaults());

  /// Test-only constructor that creates a fresh, unfiltered instance.
  /// Kept as an alias of the default constructor so existing tests that
  /// reference it still compile.
  NotificationService.forTesting()
      : _filter = null,
        _notificationController =
            StreamController<NotificationModel>.broadcast(),
        _notifications = [];

  final NotificationFilter? _filter;
  final StreamController<NotificationModel> _notificationController;
  final List<NotificationModel> _notifications;

  // Filter runtime state — only consulted when [_filter] is non-null, but
  // safe to leave allocated either way.
  final Map<String, DateTime> _lastNotificationTime = {};
  final Map<String, String> _lastNotificationMessage = {};
  final Map<String, Timer> _pendingNotifications = {};

  Stream<NotificationModel> get notifications => _notificationController.stream;
  List<NotificationModel> get allNotifications => List.from(_notifications);

  void showInfo({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {
    if (!_shouldShow(title, message, force)) return;
    _addNotification(NotificationModel.info(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
      action: action,
    ));
  }

  void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {
    if (!_shouldShow(title, message, force)) return;
    _addNotification(NotificationModel.success(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
      action: action,
    ));
  }

  void showWarning({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {
    if (!_shouldShow(title, message, force)) return;
    _addNotification(NotificationModel.warning(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
      action: action,
    ));
  }

  void showError({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
    NotificationAction? action,
    bool force = false,
  }) {
    if (!_shouldShow(title, message, force)) return;
    _addNotification(NotificationModel.error(
      title: title,
      message: message,
      duration: duration,
      metadata: metadata,
      action: action,
    ));
  }

  bool _shouldShow(String title, String message, bool force) {
    final filter = _filter;
    if (filter == null || force) return true;

    if (filter.silentTitles.contains(title)) {
      return false;
    }
    if (filter.criticalTitles.contains(title)) {
      _record(title, message);
      return true;
    }

    final key = '$title:$message';
    final lastTime = _lastNotificationTime[key];
    final lastMessage = _lastNotificationMessage[title];
    if (lastTime != null) {
      final delta = DateTime.now().difference(lastTime);
      if (delta < filter.duplicateThreshold) return false;
      if (lastMessage == message && delta < filter.sameMessageSpamThreshold) {
        return false;
      }
    }
    _record(title, message);
    return true;
  }

  void _record(String title, String message) {
    _lastNotificationTime['$title:$message'] = DateTime.now();
    _lastNotificationMessage[title] = message;
  }

  void _addNotification(NotificationModel notification) {
    _notifications.add(notification);
    _notificationController.add(notification);
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
    clearFilters();
  }

  void clearByType(NotificationType type) {
    _notifications.removeWhere((notification) => notification.type == type);
  }

  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  int get notificationCount => _notifications.length;

  /// Connection toggle — debounced when a filter is configured so rapid
  /// connect/disconnect flips collapse into the latest state.
  void showConnectionStatus({
    required String title,
    required String message,
    required bool isConnected,
  }) {
    final filter = _filter;
    if (filter == null) {
      if (isConnected) {
        showSuccess(title: title, message: message);
      } else {
        showInfo(title: title, message: message);
      }
      return;
    }

    final key = 'connection_${isConnected ? 'connected' : 'disconnected'}';
    final oppositeKey =
        'connection_${isConnected ? 'disconnected' : 'connected'}';
    _pendingNotifications[oppositeKey]?.cancel();
    _pendingNotifications.remove(oppositeKey);
    _pendingNotifications[key]?.cancel();
    _pendingNotifications[key] = Timer(filter.connectionDebounce, () {
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

  /// Scanning toggle — debounced when a filter is configured. Stops are
  /// suppressed unless they carry an "error" hint in the title; starts
  /// only surface for error/disabled cases (the BLE flow already shows
  /// scan progress visually elsewhere).
  void showScanningStatus({
    required String title,
    required String message,
    required bool isScanning,
  }) {
    final filter = _filter;
    if (filter == null) {
      if (isScanning) {
        showInfo(title: title, message: message);
      }
      return;
    }

    final key = 'scanning_${isScanning ? 'started' : 'stopped'}';
    final oppositeKey =
        'scanning_${isScanning ? 'stopped' : 'started'}';
    _pendingNotifications[oppositeKey]?.cancel();
    _pendingNotifications.remove(oppositeKey);

    if (!isScanning && !title.toLowerCase().contains('error')) {
      return;
    }

    _pendingNotifications[key]?.cancel();
    _pendingNotifications[key] = Timer(filter.scanningDebounce, () {
      if (isScanning) {
        if (title.toLowerCase().contains('error') ||
            title.toLowerCase().contains('disabled')) {
          showWarning(title: title, message: message);
        }
      }
      _pendingNotifications.remove(key);
    });
  }

  /// Reset filter runtime state. Safe to call when no filter is configured.
  void clearFilters() {
    _lastNotificationTime.clear();
    _lastNotificationMessage.clear();
    for (final timer in _pendingNotifications.values) {
      timer.cancel();
    }
    _pendingNotifications.clear();
  }

  /// Add titles to the configured filter sets. No-op when no filter is set.
  void configureSettings({
    Set<String>? additionalSilentOperations,
    Set<String>? additionalCriticalNotifications,
    Set<String>? additionalDebouncedNotifications,
  }) {
    final filter = _filter;
    if (filter == null) return;
    if (additionalSilentOperations != null) {
      filter.silentTitles.addAll(additionalSilentOperations);
    }
    if (additionalCriticalNotifications != null) {
      filter.criticalTitles.addAll(additionalCriticalNotifications);
    }
    if (additionalDebouncedNotifications != null) {
      filter.debouncedTitles.addAll(additionalDebouncedNotifications);
    }
  }

  Map<String, dynamic> getStatistics() {
    final filter = _filter;
    return <String, dynamic>{
      'total_notifications': _notifications.length,
      'filtered_notifications': _lastNotificationTime.length,
      'pending_notifications': _pendingNotifications.length,
      'silent_operations': filter?.silentTitles.length ?? 0,
      'critical_notifications': filter?.criticalTitles.length ?? 0,
      'debounced_notifications': filter?.debouncedTitles.length ?? 0,
    };
  }

  void dispose() {
    clearFilters();
    _notificationController.close();
  }
}
