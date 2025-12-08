import 'dart:async';
import 'package:flutter/foundation.dart';

/// Base class for all ViewModels in the application.
///
/// Provides lifecycle management, automatic stream subscription handling,
/// and state change notification capabilities.
///
/// Usage:
/// ```dart
/// class MyViewModel extends BaseViewModel {
///   late final BleControllerInterface _controller;
///
///   @override
///   Future<void> onInit() async {
///     _controller = getIt<BleControllerInterface>();
///
///     // Subscriptions are automatically cleaned up on dispose
///     subscribe(_controller.devicesStream, (devices) {
///       // handle devices update
///       notifyListeners();
///     });
///   }
/// }
/// ```
abstract class BaseViewModel extends ChangeNotifier {
  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// Whether this ViewModel has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether this ViewModel has completed initialization.
  bool get isInitialized => _isInitialized;

  /// Whether the ViewModel is currently loading data.
  bool get isLoading => _isLoading;

  /// Error message if an error occurred during operations.
  String? get errorMessage => _errorMessage;

  /// Whether the ViewModel has an error.
  bool get hasError => _errorMessage != null;

  /// Initialize the ViewModel. Called once when first created.
  ///
  /// Override this method to perform async initialization.
  /// The base implementation handles loading state automatically.
  @mustCallSuper
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    _setLoading(true);
    _clearError();

    try {
      await onInit();
      _isInitialized = true;
    } catch (e) {
      _setError('Initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Override this method to perform initialization logic.
  ///
  /// This is called once during [initialize].
  /// Set up stream subscriptions and load initial data here.
  @protected
  Future<void> onInit() async {}

  /// Subscribe to a stream with automatic lifecycle management.
  ///
  /// The subscription will be automatically cancelled when [dispose] is called.
  /// Optionally specify [onError] and [onDone] callbacks.
  @protected
  StreamSubscription<T> subscribe<T>(
    Stream<T> stream,
    void Function(T data) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = stream.listen(
      (data) {
        if (!_isDisposed) {
          onData(data);
        }
      },
      onError: onError ?? _handleStreamError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Handle stream errors. Override to customize error handling.
  @protected
  void _handleStreamError(dynamic error, StackTrace stackTrace) {
    if (!_isDisposed) {
      _setError(error.toString());
    }
  }

  /// Set loading state and notify listeners.
  @protected
  void setLoading(bool loading) {
    _setLoading(loading);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading && !_isDisposed) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message and notify listeners.
  @protected
  void setError(String? message) {
    _setError(message);
  }

  void _setError(String? message) {
    if (_errorMessage != message && !_isDisposed) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// Clear any error message.
  @protected
  void clearError() {
    _clearError();
  }

  void _clearError() {
    _setError(null);
  }

  /// Safely notify listeners, checking if disposed first.
  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Called when the ViewModel is about to be disposed.
  ///
  /// Override to perform cleanup. Make sure to call super.
  @protected
  @mustCallSuper
  void onDispose() {}

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Call subclass cleanup
    onDispose();

    super.dispose();
  }
}

/// Mixin that provides mounted-state awareness for ViewModels.
///
/// Use this when you need to check if the associated widget is still mounted
/// before performing UI-related operations.
mixin MountedAwareMixin on BaseViewModel {
  bool _isMounted = false;

  /// Whether the associated widget is currently mounted.
  bool get isMounted => _isMounted && !isDisposed;

  /// Set the mounted state. Called by ViewModelProvider.
  void setMounted(bool mounted) {
    _isMounted = mounted;
  }

  /// Execute a callback only if mounted.
  void runIfMounted(VoidCallback callback) {
    if (isMounted) {
      callback();
    }
  }

  /// Execute an async callback only if mounted.
  Future<T?> runIfMountedAsync<T>(Future<T> Function() callback) async {
    if (isMounted) {
      return await callback();
    }
    return null;
  }
}
