import 'dart:async';
import 'dart:io';
import '../l10n/app_strings.dart';
import 'notification_service.dart';
import '../utils/logger.dart';

/// Error categories for classification
enum ErrorCategory {
  bluetooth,
  permission,
  network,
  validation,
  system,
  unknown,
}

/// Error model for the application
class AppError {
  final String code;
  final String message;
  final ErrorCategory category;
  final DateTime timestamp;
  final Object? originalError;
  final StackTrace? stackTrace;
  final void Function()? retryAction;
  final Map<String, dynamic>? metadata;

  AppError({
    required this.code,
    required this.message,
    required this.category,
    DateTime? timestamp,
    this.originalError,
    this.stackTrace,
    this.retryAction,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a Bluetooth error
  factory AppError.bluetooth(
    String code,
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
    void Function()? retryAction,
    Map<String, dynamic>? metadata,
  }) {
    return AppError(
      code: code,
      message: message,
      category: ErrorCategory.bluetooth,
      originalError: originalError,
      stackTrace: stackTrace,
      retryAction: retryAction,
      metadata: metadata,
    );
  }

  /// Create a permission error
  factory AppError.permission(
    String code,
    String message, {
    void Function()? retryAction,
  }) {
    return AppError(
      code: code,
      message: message,
      category: ErrorCategory.permission,
      retryAction: retryAction,
    );
  }

  /// Create a network error
  factory AppError.network(
    String code,
    String message, {
    Object? originalError,
    void Function()? retryAction,
  }) {
    return AppError(
      code: code,
      message: message,
      category: ErrorCategory.network,
      originalError: originalError,
      retryAction: retryAction,
    );
  }

  /// Create a validation error
  factory AppError.validation(String code, String message) {
    return AppError(
      code: code,
      message: message,
      category: ErrorCategory.validation,
    );
  }

  /// Create a system error
  factory AppError.system(
    String code,
    String message, {
    Object? originalError,
    void Function()? retryAction,
  }) {
    return AppError(
      code: code,
      message: message,
      category: ErrorCategory.system,
      originalError: originalError,
      retryAction: retryAction,
    );
  }

  @override
  String toString() {
    return 'AppError(code: $code, message: $message, category: $category)';
  }
}

/// User action for error recovery
class UserAction {
  final String label;
  final void Function()? action;
  final bool isPrimary;

  const UserAction({
    required this.label,
    required this.action,
    this.isPrimary = false,
  });
}

/// Error handling service implementation.
///
/// Handles error logging, history management, and provides user-friendly
/// error messages and recovery actions. UI-related error display should
/// be handled by the Views layer using the error stream and helper methods.
class ErrorHandlingService {
  final NotificationService _notificationService;
  final StreamController<AppError> _errorController;
  final List<AppError> _errorHistory;

  /// Default constructor for dependency injection via service locator.
  ErrorHandlingService({
    required NotificationService notificationService,
  })  : _notificationService = notificationService,
        _errorController = StreamController<AppError>.broadcast(),
        _errorHistory = [];

  /// Named constructor for testing that creates a fresh instance.
  ErrorHandlingService.forTesting({
    required NotificationService notificationService,
  })  : _notificationService = notificationService,
        _errorController = StreamController<AppError>.broadcast(),
        _errorHistory = [];

  Stream<AppError> get errorStream => _errorController.stream;

  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  Future<void> handleError(AppError error) async {
    _addToHistory(error);
    _logError(error);
    _showNotification(error);
    _errorController.add(error);
  }

  /// Log error based on category
  void _logError(AppError error) {
    final logMessage = '[${error.category.name.toUpperCase()}] ${error.code}: ${error.message}';

    switch (error.category) {
      case ErrorCategory.bluetooth:
      case ErrorCategory.network:
      case ErrorCategory.system:
        Logger.error(logMessage, error: error.originalError);
        break;
      case ErrorCategory.permission:
        Logger.warning(logMessage);
        break;
      case ErrorCategory.validation:
        Logger.info(logMessage);
        break;
      case ErrorCategory.unknown:
        Logger.error(logMessage, error: error.originalError);
        break;
    }
  }

  /// Show notification based on error category
  void _showNotification(AppError error) {
    final message = getErrorMessage(error);
    final title = _getErrorTitle(error);

    // If the error has at least one recovery action, surface the primary
    // one as a SnackBar action button so transient errors can be recovered
    // inline without opening settings.
    final recoveryActions = getErrorRecoveryActions(error);
    NotificationAction? snackbarAction;
    if (recoveryActions.isNotEmpty) {
      final primary = recoveryActions.firstWhere(
        (a) => a.isPrimary,
        orElse: () => recoveryActions.first,
      );
      final cb = primary.action;
      if (cb != null) {
        snackbarAction = NotificationAction(
          label: primary.label,
          onPressed: cb,
        );
      }
    }

    switch (error.category) {
      case ErrorCategory.bluetooth:
      case ErrorCategory.network:
      case ErrorCategory.system:
      case ErrorCategory.unknown:
        _notificationService.showError(
          title: title,
          message: message,
          action: snackbarAction,
        );
        break;
      case ErrorCategory.permission:
      case ErrorCategory.validation:
        _notificationService.showWarning(
          title: title,
          message: message,
          action: snackbarAction,
        );
        break;
    }
  }

  /// Get error title based on category
  String _getErrorTitle(AppError error) {
    switch (error.category) {
      case ErrorCategory.bluetooth:
        return AppStrings.bluetoothErrorTitle;
      case ErrorCategory.permission:
        return AppStrings.permissionErrorTitle;
      case ErrorCategory.network:
        return AppStrings.networkErrorTitle;
      case ErrorCategory.validation:
        return AppStrings.validationErrorTitle;
      case ErrorCategory.system:
        return AppStrings.systemErrorTitle;
      case ErrorCategory.unknown:
        return AppStrings.unknownErrorTitle;
    }
  }

  String getErrorMessage(AppError error) {
    switch (error.category) {
      case ErrorCategory.bluetooth:
        return _getBluetoothErrorMessage(error);
      case ErrorCategory.permission:
        return _getPermissionErrorMessage(error);
      case ErrorCategory.network:
        return _getNetworkErrorMessage(error);
      case ErrorCategory.validation:
        return _getValidationErrorMessage(error);
      case ErrorCategory.system:
        return _getSystemErrorMessage(error);
      case ErrorCategory.unknown:
        return AppStrings.unexpectedErrorMessage;
    }
  }

  List<UserAction> getErrorRecoveryActions(AppError error) {
    switch (error.category) {
      case ErrorCategory.bluetooth:
        return _getBluetoothErrorActions(error);
      case ErrorCategory.permission:
        return _getPermissionErrorActions(error);
      case ErrorCategory.network:
        return _getNetworkErrorActions(error);
      case ErrorCategory.validation:
        return []; // Validation errors typically don't need recovery actions
      case ErrorCategory.system:
        return _getSystemErrorActions(error);
      case ErrorCategory.unknown:
        return _getUnknownErrorActions(error);
    }
  }

  /// Get Bluetooth-specific error messages
  String _getBluetoothErrorMessage(AppError error) {
    switch (error.code) {
      case 'BLE_DISABLED':
        return AppStrings.bleDisabledMessage;
      case 'BLE_UNAVAILABLE':
        return AppStrings.bleUnavailableMessage;
      case 'SCAN_FAILED':
        return AppStrings.scanFailedMessage;
      case 'DEVICE_NOT_FOUND':
        return AppStrings.deviceNotFoundMessage;
      case 'CONNECTION_FAILED':
        return AppStrings.connectionFailedMessage;
      case 'CONNECTION_LOST':
        return AppStrings.connectionLostMessage;
      case 'SERVICE_DISCOVERY_FAILED':
        return AppStrings.serviceDiscoveryFailedMessage;
      case 'CHARACTERISTIC_NOT_FOUND':
        return AppStrings.characteristicNotFoundMessage;
      case 'WRITE_FAILED':
        return AppStrings.writeFailedMessage;
      case 'READ_FAILED':
        return AppStrings.readFailedMessage;
      default:
        return error.message;
    }
  }

  /// Get permission-specific error messages
  String _getPermissionErrorMessage(AppError error) {
    switch (error.code) {
      case 'BLUETOOTH_PERMISSION_DENIED':
        return AppStrings.bluetoothPermissionDeniedMessage;
      case 'LOCATION_PERMISSION_DENIED':
        return AppStrings.locationPermissionDeniedMessage;
      case 'LOCATION_SERVICE_DISABLED':
        return AppStrings.locationServiceDisabledMessage;
      case 'NOTIFICATION_PERMISSION_DENIED':
        return AppStrings.notificationPermissionDeniedMessage;
      default:
        return error.message;
    }
  }

  /// Get network-specific error messages
  String _getNetworkErrorMessage(AppError error) {
    if (error.originalError is SocketException) {
      return AppStrings.noInternetMessage;
    }
    if (error.originalError is TimeoutException) {
      return AppStrings.requestTimedOutMessage;
    }
    return error.message;
  }

  /// Get validation error messages
  String _getValidationErrorMessage(AppError error) {
    switch (error.code) {
      case 'INVALID_COMMAND':
        return AppStrings.invalidCommandMessage;
      case 'EMPTY_COMMAND':
        return AppStrings.emptyCommandMessage;
      case 'COMMAND_TOO_LONG':
        return AppStrings.commandTooLongMessage;
      default:
        return error.message;
    }
  }

  /// Get system error messages
  String _getSystemErrorMessage(AppError error) {
    switch (error.code) {
      case 'INSUFFICIENT_MEMORY':
        return AppStrings.insufficientMemoryMessage;
      case 'FILE_NOT_FOUND':
        return AppStrings.fileNotFoundMessage;
      case 'STORAGE_FULL':
        return AppStrings.storageFullMessage;
      default:
        return error.message;
    }
  }

  /// Get Bluetooth error actions
  List<UserAction> _getBluetoothErrorActions(AppError error) {
    switch (error.code) {
      case 'BLE_DISABLED':
        return [
          UserAction(
            label: AppStrings.enableBluetoothAction,
            action: error.retryAction,
            isPrimary: true,
          ),
        ];
      case 'BLE_UNAVAILABLE':
        // Hardware can't be fixed at runtime — no actionable recovery.
        return const [];
      case 'CONNECTION_FAILED':
      case 'CONNECTION_LOST':
        return [
          UserAction(
            label: AppStrings.retryAction,
            action: error.retryAction,
            isPrimary: true,
          ),
        ];
      default:
        if (error.retryAction != null) {
          return [
            UserAction(
              label: AppStrings.retryAction,
              action: error.retryAction,
              isPrimary: true,
            ),
          ];
        }
        return const [];
    }
  }

  /// Get permission error actions
  List<UserAction> _getPermissionErrorActions(AppError error) {
    switch (error.code) {
      case 'LOCATION_SERVICE_DISABLED':
        return [
          UserAction(
            label: AppStrings.enableLocationServiceAction,
            action: error.retryAction,
            isPrimary: true,
          ),
        ];
      default:
        return [
          UserAction(
            label: AppStrings.openSettingsAction,
            action: error.retryAction,
            isPrimary: true,
          ),
        ];
    }
  }

  /// Get network error actions
  List<UserAction> _getNetworkErrorActions(AppError error) {
    return [
      UserAction(
        label: AppStrings.retryAction,
        action: error.retryAction,
        isPrimary: true,
      ),
    ];
  }

  /// Get system error actions
  List<UserAction> _getSystemErrorActions(AppError error) {
    if (error.retryAction != null) {
      return [
        UserAction(
          label: AppStrings.retryAction,
          action: error.retryAction,
          isPrimary: true,
        ),
      ];
    }
    return const [];
  }

  /// Get unknown error actions
  List<UserAction> _getUnknownErrorActions(AppError error) {
    final actions = <UserAction>[];
    if (error.retryAction != null) {
      actions.add(UserAction(
        label: AppStrings.retryAction,
        action: error.retryAction,
        isPrimary: true,
      ));
    }
    return actions;
  }

  /// Add error to history
  void _addToHistory(AppError error) {
    _errorHistory.insert(0, error);
    if (_errorHistory.length > 100) {
      _errorHistory.removeLast();
    }
  }

  void clearHistory() {
    _errorHistory.clear();
  }

  void dispose() {
    _errorController.close();
  }
}
