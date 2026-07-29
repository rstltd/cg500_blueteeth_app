import '../../services/notification_service.dart';
import '../../l10n/app_strings.dart';

/// Verbosity level for BLE notifications.
/// Controls how much detail is shown to the user.
enum BleNotificationVerbosity {
  /// Show all notifications including info and success messages
  verbose,
  /// Show only errors and warnings (recommended for most users)
  normal,
  /// Show only error notifications (minimal noise)
  minimal,
  /// Don't show any notifications (silent mode)
  silent,
}

/// SharedPreferences key for BLE notification verbosity
const String bleNotificationVerbosityKey = 'ble_notification_verbosity';

/// BLE event types for notification handling.
/// Each event has properties that determine when it should be shown.
enum BleEvent {
  // Initialization events
  initializeSuccess(isError: false, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventControllerReadyTitle,
      defaultMessage: AppStrings.bleEventControllerReadyMessage),
  initializeFailed(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventInitFailedTitle,
      defaultMessage: AppStrings.bleEventInitFailedMessage),
  initializeError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventControllerErrorTitle,
      defaultMessage: AppStrings.bleEventControllerErrorMessage),

  // Scanning events
  scanStarted(isError: false, isWarning: false, isImportant: false,
      defaultTitle: AppStrings.bleEventScanStartedTitle,
      defaultMessage: AppStrings.bleEventScanStartedMessage),
  scanStopped(isError: false, isWarning: false, isImportant: false,
      defaultTitle: AppStrings.bleEventScanStoppedTitle,
      defaultMessage: AppStrings.bleEventScanStoppedMessage),
  scanError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventScanErrorTitle,
      defaultMessage: AppStrings.bleEventScanErrorDefaultMessage),
  stopScanError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventStopScanErrorTitle,
      defaultMessage: AppStrings.bleEventStopScanErrorDefaultMessage),

  // Connection events
  connecting(isError: false, isWarning: false, isImportant: false,
      defaultTitle: AppStrings.bleEventConnectingTitle,
      defaultMessage: AppStrings.bleEventConnectingMessage),
  connected(isError: false, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.connected,
      defaultMessage: AppStrings.bleEventConnectedMessage),
  connectionError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventConnectionFailedTitle,
      defaultMessage: AppStrings.bleEventConnectionFailedMessage),
  disconnectError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventDisconnectErrorTitle,
      defaultMessage: AppStrings.bleEventDisconnectErrorMessage),

  // Service discovery events
  discoveringServices(isError: false, isWarning: false, isImportant: false,
      defaultTitle: AppStrings.bleEventDiscoveringServicesTitle,
      defaultMessage: AppStrings.bleEventDiscoveringServicesMessage),
  servicesFound(isError: false, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventServicesFoundTitle,
      defaultMessage: AppStrings.bleEventServicesFoundDefaultMessage),
  noServicesFound(isError: false, isWarning: true, isImportant: false,
      defaultTitle: AppStrings.bleEventNoServicesTitle,
      defaultMessage: AppStrings.bleEventNoServicesMessage),
  serviceDiscoveryError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventServiceDiscoveryErrorTitle,
      defaultMessage: AppStrings.bleEventServiceDiscoveryErrorMessage),

  // Command events
  emptyCommand(isError: false, isWarning: true, isImportant: false,
      defaultTitle: AppStrings.bleEventEmptyCommandTitle,
      defaultMessage: AppStrings.bleEventEmptyCommandMessage),
  commandError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: AppStrings.bleEventCommandErrorTitle,
      defaultMessage: AppStrings.commandSendFailed),

  // Device list events
  devicesCleared(isError: false, isWarning: false, isImportant: false,
      defaultTitle: AppStrings.bleEventDevicesClearedTitle,
      defaultMessage: AppStrings.bleEventDevicesClearedMessage),
  ;

  final bool isError;
  final bool isWarning;
  final bool isImportant;
  final String defaultTitle;
  final String defaultMessage;

  const BleEvent({
    required this.isError,
    required this.isWarning,
    required this.isImportant,
    required this.defaultTitle,
    required this.defaultMessage,
  });
}

/// Unified delegate for BLE controller notifications.
///
/// This class replaces the previous 4 implementations (Default, Minimal,
/// Configurable, Silent) with a single configurable class that handles
/// all notification behavior based on the verbosity level.
///
/// The delegate separates notification logic from the BLE controller,
/// allowing for easier testing and customization of notification behavior.
///
/// Usage:
/// ```dart
/// final delegate = BleNotificationDelegate(
///   notificationService: myNotificationService,
///   verbosity: BleNotificationVerbosity.minimal,
/// );
///
/// // Change verbosity at runtime
/// delegate.setVerbosity(BleNotificationVerbosity.verbose);
/// ```
class BleNotificationDelegate {
  final NotificationService _notificationService;
  BleNotificationVerbosity _verbosity;

  BleNotificationDelegate(
    this._notificationService, {
    BleNotificationVerbosity verbosity = BleNotificationVerbosity.minimal,
  }) : _verbosity = verbosity;

  /// Get current verbosity level
  BleNotificationVerbosity get verbosity => _verbosity;

  /// Update verbosity level at runtime
  void setVerbosity(BleNotificationVerbosity verbosity) {
    _verbosity = verbosity;
  }

  /// Determine if an event should trigger a notification based on verbosity.
  bool _shouldNotify(BleEvent event) {
    switch (_verbosity) {
      case BleNotificationVerbosity.silent:
        return false;
      case BleNotificationVerbosity.minimal:
        return event.isError;
      case BleNotificationVerbosity.normal:
        return event.isError || event.isWarning;
      case BleNotificationVerbosity.verbose:
        return true;
    }
  }

  /// Unified notification method using BleEvent.
  void _notify(BleEvent event, {String? customMessage}) {
    if (!_shouldNotify(event)) return;

    final message = customMessage ?? event.defaultMessage;

    if (event.isError) {
      _notificationService.showError(
        title: event.defaultTitle,
        message: message,
      );
    } else if (event.isWarning) {
      _notificationService.showWarning(
        title: event.defaultTitle,
        message: message,
      );
    } else if (event.isImportant) {
      _notificationService.showSuccess(
        title: event.defaultTitle,
        message: message,
      );
    } else {
      _notificationService.showInfo(
        title: event.defaultTitle,
        message: message,
      );
    }
  }

  // ============================================
  // Initialization notifications
  // ============================================

  void onInitializeSuccess() => _notify(BleEvent.initializeSuccess);

  void onInitializeFailed() => _notify(BleEvent.initializeFailed);

  void onInitializeError(String error) =>
      _notify(BleEvent.initializeError,
          customMessage: AppStrings.bleEventControllerErrorDetailMessage(error));

  // ============================================
  // Scanning notifications
  // ============================================

  void onScanStarted() => _notify(BleEvent.scanStarted);

  void onScanStopped() => _notify(BleEvent.scanStopped);

  void onScanError(String error) =>
      _notify(BleEvent.scanError, customMessage: AppStrings.bleEventScanErrorMessage(error));

  void onStopScanError(String error) =>
      _notify(BleEvent.stopScanError, customMessage: AppStrings.bleEventStopScanErrorMessage(error));

  // ============================================
  // Connection notifications
  // ============================================

  void onConnecting() => _notify(BleEvent.connecting);

  void onConnected() => _notify(BleEvent.connected);

  void onConnectionError(String error) =>
      _notify(BleEvent.connectionError, customMessage: error);

  void onDisconnectError(String error) =>
      _notify(BleEvent.disconnectError, customMessage: error);

  // ============================================
  // Service discovery notifications
  // ============================================

  void onDiscoveringServices() => _notify(BleEvent.discoveringServices);

  void onServicesFound(int count) =>
      _notify(BleEvent.servicesFound, customMessage: AppStrings.bleEventServicesFoundMessage(count));

  void onNoServicesFound() => _notify(BleEvent.noServicesFound);

  void onServiceDiscoveryError(String error) =>
      _notify(BleEvent.serviceDiscoveryError, customMessage: error);

  // ============================================
  // Command notifications
  // ============================================

  void onEmptyCommand() => _notify(BleEvent.emptyCommand);

  void onCommandError(String error) =>
      _notify(BleEvent.commandError, customMessage: error);

  // ============================================
  // Device list notifications
  // ============================================

  void onDevicesCleared() => _notify(BleEvent.devicesCleared);
}
