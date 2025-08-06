import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'notification_service.dart';
import '../widgets/animated_widgets.dart';

/// Enhanced error handling service with better user feedback
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final NotificationService _notificationService = NotificationService();
  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();
  final List<AppError> _errorHistory = [];

  Stream<AppError> get errorStream => _errorController.stream;
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  /// Handle different types of errors with appropriate user feedback
  Future<void> handleError(AppError error, BuildContext? context) async {
    _addToHistory(error);
    
    switch (error.category) {
      case ErrorCategory.bluetooth:
        await _handleBluetoothError(error, context);
        break;
      case ErrorCategory.permission:
        await _handlePermissionError(error, context);
        break;
      case ErrorCategory.network:
        await _handleNetworkError(error, context);
        break;
      case ErrorCategory.validation:
        await _handleValidationError(error, context);
        break;
      case ErrorCategory.system:
        await _handleSystemError(error, context);
        break;
      case ErrorCategory.unknown:
        await _handleUnknownError(error, context);
        break;
    }

    _errorController.add(error);
  }

  /// Handle Bluetooth-specific errors
  Future<void> _handleBluetoothError(AppError error, BuildContext? context) async {
    String title = 'Bluetooth Error';
    String message = _getBluetoothErrorMessage(error);
    List<UserAction> actions = _getBluetoothErrorActions(error);

    await _showErrorDialog(context, title, message, actions);
    _notificationService.showError(title: title, message: message);
  }

  /// Handle permission-related errors
  Future<void> _handlePermissionError(AppError error, BuildContext? context) async {
    String title = 'Permission Required';
    String message = _getPermissionErrorMessage(error);
    List<UserAction> actions = _getPermissionErrorActions(error);

    await _showErrorDialog(context, title, message, actions);
    _notificationService.showWarning(title: title, message: message);
  }

  /// Handle network errors
  Future<void> _handleNetworkError(AppError error, BuildContext? context) async {
    String title = 'Network Error';
    String message = _getNetworkErrorMessage(error);
    List<UserAction> actions = _getNetworkErrorActions(error);

    await _showErrorDialog(context, title, message, actions);
    _notificationService.showError(title: title, message: message);
  }

  /// Handle validation errors
  Future<void> _handleValidationError(AppError error, BuildContext? context) async {
    String message = _getValidationErrorMessage(error);
    
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
    }
    
    _notificationService.showWarning(title: 'Validation Error', message: message);
  }

  /// Handle system errors
  Future<void> _handleSystemError(AppError error, BuildContext? context) async {
    String title = 'System Error';
    String message = _getSystemErrorMessage(error);
    List<UserAction> actions = _getSystemErrorActions(error);

    await _showErrorDialog(context, title, message, actions);
    _notificationService.showError(title: title, message: message);
  }

  /// Handle unknown errors
  Future<void> _handleUnknownError(AppError error, BuildContext? context) async {
    String title = 'Unexpected Error';
    String message = 'An unexpected error occurred. Please try again.';
    List<UserAction> actions = [
      UserAction(
        label: 'Retry',
        action: error.retryAction,
        isPrimary: true,
      ),
      UserAction(
        label: 'Report Issue',
        action: () => _reportError(error),
        isPrimary: false,
      ),
    ];

    await _showErrorDialog(context, title, message, actions);
    _notificationService.showError(title: title, message: message);
  }

  /// Show enhanced error dialog with actions
  Future<void> _showErrorDialog(
    BuildContext? context,
    String title,
    String message,
    List<UserAction> actions,
  ) async {
    if (context == null) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            ...actions.map((action) => _buildActionButton(dialogContext, action)),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Build action button for error dialog
  Widget _buildActionButton(BuildContext context, UserAction action) {
    return action.isPrimary
        ? ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              action.action?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(action.label),
          )
        : TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              action.action?.call();
            },
            child: Text(action.label),
          );
  }

  /// Show success feedback with animation
  void showSuccessFeedback(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width * 0.5 - 100,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedFeedback(
                  showSuccess: true,
                  duration: Duration(milliseconds: 800),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    
    // Remove overlay after duration
    Timer(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  /// Get Bluetooth-specific error messages
  String _getBluetoothErrorMessage(AppError error) {
    switch (error.code) {
      case 'BLE_DISABLED':
        return 'Bluetooth is disabled on this device. Please enable Bluetooth to continue.';
      case 'BLE_UNAVAILABLE':
        return 'Bluetooth Low Energy is not available on this device.';
      case 'DEVICE_NOT_FOUND':
        return 'The selected device could not be found. It may be out of range or turned off.';
      case 'CONNECTION_FAILED':
        return 'Failed to connect to the device. Please ensure the device is nearby and try again.';
      case 'CONNECTION_LOST':
        return 'Connection to the device was lost. The device may have moved out of range.';
      case 'SERVICE_DISCOVERY_FAILED':
        return 'Failed to discover device services. The device may not be compatible.';
      case 'CHARACTERISTIC_NOT_FOUND':
        return 'Required characteristic not found on the device.';
      case 'WRITE_FAILED':
        return 'Failed to send data to the device. Please check the connection and try again.';
      case 'READ_FAILED':
        return 'Failed to read data from the device. Please check the connection.';
      default:
        return error.message;
    }
  }

  /// Get permission-specific error messages
  String _getPermissionErrorMessage(AppError error) {
    switch (error.code) {
      case 'BLUETOOTH_PERMISSION_DENIED':
        return 'Bluetooth permission is required to scan for and connect to devices.';
      case 'LOCATION_PERMISSION_DENIED':
        return 'Location permission is required for Bluetooth scanning on Android devices.';
      case 'NOTIFICATION_PERMISSION_DENIED':
        return 'Notification permission is required to show connection status updates.';
      default:
        return error.message;
    }
  }

  /// Get network-specific error messages
  String _getNetworkErrorMessage(AppError error) {
    if (error.originalError is SocketException) {
      return 'No internet connection. Please check your network settings and try again.';
    }
    if (error.originalError is TimeoutException) {
      return 'The request timed out. Please check your connection and try again.';
    }
    return error.message;
  }

  /// Get validation error messages
  String _getValidationErrorMessage(AppError error) {
    switch (error.code) {
      case 'INVALID_COMMAND':
        return 'The command format is invalid. Please check your input and try again.';
      case 'EMPTY_COMMAND':
        return 'Command cannot be empty. Please enter a valid command.';
      case 'COMMAND_TOO_LONG':
        return 'Command is too long. Please use a shorter command.';
      default:
        return error.message;
    }
  }

  /// Get system error messages
  String _getSystemErrorMessage(AppError error) {
    switch (error.code) {
      case 'INSUFFICIENT_MEMORY':
        return 'Insufficient memory to complete the operation. Please close other apps and try again.';
      case 'FILE_NOT_FOUND':
        return 'A required file was not found. Please reinstall the app if the problem persists.';
      case 'STORAGE_FULL':
        return 'Device storage is full. Please free up space and try again.';
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
            label: 'Open Settings',
            action: () => _openBluetoothSettings(),
            isPrimary: true,
          ),
        ];
      case 'CONNECTION_FAILED':
      case 'CONNECTION_LOST':
        return [
          UserAction(
            label: 'Retry',
            action: error.retryAction,
            isPrimary: true,
          ),
        ];
      default:
        return [];
    }
  }

  /// Get permission error actions
  List<UserAction> _getPermissionErrorActions(AppError error) {
    return [
      UserAction(
        label: 'Grant Permission',
        action: error.retryAction,
        isPrimary: true,
      ),
      UserAction(
        label: 'Open Settings',
        action: () => _openAppSettings(),
        isPrimary: false,
      ),
    ];
  }

  /// Get network error actions
  List<UserAction> _getNetworkErrorActions(AppError error) {
    return [
      UserAction(
        label: 'Retry',
        action: error.retryAction,
        isPrimary: true,
      ),
      UserAction(
        label: 'Check Settings',
        action: () => _openNetworkSettings(),
        isPrimary: false,
      ),
    ];
  }

  /// Get system error actions
  List<UserAction> _getSystemErrorActions(AppError error) {
    return [
      UserAction(
        label: 'Retry',
        action: error.retryAction,
        isPrimary: true,
      ),
    ];
  }

  /// Add error to history
  void _addToHistory(AppError error) {
    _errorHistory.insert(0, error);
    if (_errorHistory.length > 100) {
      _errorHistory.removeLast();
    }
  }

  /// Report error to analytics or crash reporting service
  void _reportError(AppError error) {
    // TODO: Implement error reporting integration
    // You could integrate with Firebase Crashlytics, Sentry, or other services
  }

  /// Open system Bluetooth settings
  void _openBluetoothSettings() {
    // TODO: Implement platform-specific Bluetooth settings navigation
  }

  /// Open app settings
  void _openAppSettings() {
    // TODO: Implement platform-specific app settings navigation
  }

  /// Open network settings
  void _openNetworkSettings() {
    // TODO: Implement platform-specific network settings navigation
  }

  /// Clear error history
  void clearHistory() {
    _errorHistory.clear();
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}

/// Error categories for better classification
enum ErrorCategory {
  bluetooth,
  permission,
  network,
  validation,
  system,
  unknown,
}

/// Enhanced error model
class AppError {
  final String code;
  final String message;
  final ErrorCategory category;
  final DateTime timestamp;
  final Object? originalError;
  final StackTrace? stackTrace;
  final VoidCallback? retryAction;
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
    VoidCallback? retryAction,
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
    VoidCallback? retryAction,
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
    VoidCallback? retryAction,
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

  @override
  String toString() {
    return 'AppError(code: $code, message: $message, category: $category)';
  }
}

/// User action for error dialogs
class UserAction {
  final String label;
  final VoidCallback? action;
  final bool isPrimary;

  const UserAction({
    required this.label,
    required this.action,
    this.isPrimary = false,
  });
}