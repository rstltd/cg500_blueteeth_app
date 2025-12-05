import 'dart:async';

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

/// Interface for error handling service
abstract class ErrorHandlingServiceInterface {
  /// Stream of errors for UI to listen to
  Stream<AppError> get errorStream;

  /// Error history for debugging
  List<AppError> get errorHistory;

  /// Handle an error - logs it, adds to history, notifies listeners
  Future<void> handleError(AppError error);

  /// Get user-friendly message for an error
  String getErrorMessage(AppError error);

  /// Get recovery actions for an error
  List<UserAction> getErrorRecoveryActions(AppError error);

  /// Clear error history
  void clearHistory();

  /// Dispose resources
  void dispose();
}
