import 'dart:async';
import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/network_service.dart';
import '../services/smart_notification_service.dart';
import '../utils/logger.dart';
import '../widgets/update_dialog.dart';

/// Global update manager that coordinates all update operations
/// This is the single source of truth for update state across the app
class AppUpdateManager {
  static final AppUpdateManager _instance = AppUpdateManager._internal();
  factory AppUpdateManager() => _instance;
  AppUpdateManager._internal();

  final UpdateService _updateService = UpdateService();
  final NetworkService _networkService = NetworkService();
  final SmartNotificationService _notificationService = SmartNotificationService();
  
  // State management
  bool _isInitialized = false;
  bool _isCheckingForUpdates = false;
  UpdateInfo? _latestUpdateInfo;
  Timer? _periodicUpdateTimer;
  BuildContext? _currentContext;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isCheckingForUpdates => _isCheckingForUpdates;
  UpdateInfo? get latestUpdateInfo => _latestUpdateInfo;
  UpdateService get updateService => _updateService;
  NetworkService get networkService => _networkService;

  /// Initialize the update manager
  /// This should be called during app startup
  Future<bool> initialize() async {
    if (_isInitialized) {
      Logger.debug('AppUpdateManager already initialized');
      return true;
    }

    try {
      Logger.info('Initializing AppUpdateManager...');
      
      // Initialize core services
      await _updateService.initialize();
      await _networkService.initialize();
      
      // Listen to update streams
      _updateService.updateStream.listen(_handleUpdateAvailable);
      
      // Listen to network changes to trigger update checks
      _networkService.networkStream.listen(_handleNetworkChange);
      
      _isInitialized = true;
      Logger.info('AppUpdateManager initialized successfully');
      
      // Perform initial update check after initialization
      _scheduleInitialUpdateCheck();
      
      return true;
    } catch (e) {
      Logger.error('Failed to initialize AppUpdateManager', error: e);
      return false;
    }
  }

  /// Set the current context for showing dialogs
  void setContext(BuildContext context) {
    _currentContext = context;
  }

  /// Schedule initial update check with delay
  void _scheduleInitialUpdateCheck() {
    Timer(const Duration(seconds: 3), () {
      checkForUpdatesWithUI();
    });
  }

  /// Check for updates and show UI if available
  Future<UpdateInfo?> checkForUpdatesWithUI({bool force = false}) async {
    if (_isCheckingForUpdates && !force) {
      Logger.debug('Update check already in progress');
      return _latestUpdateInfo;
    }

    _isCheckingForUpdates = true;
    
    try {
      Logger.info('Checking for updates with UI...');
      
      // Check for updates
      final updateInfo = await _updateService.checkForUpdates(showNotification: false);
      
      if (updateInfo != null) {
        _latestUpdateInfo = updateInfo;
        Logger.info('Update found: ${updateInfo.currentVersion} -> ${updateInfo.latestVersion}');
        
        // Show update dialog if context is available
        if (_currentContext != null && _currentContext!.mounted) {
          _showUpdateDialog(updateInfo);
        } else {
          // Fallback to notification if no context
          _notificationService.showInfo(
            title: 'Update Available',
            message: 'Version ${updateInfo.latestVersion} is available',
          );
        }
        
        return updateInfo;
      } else {
        Logger.info('No updates available');
        return null;
      }
    } catch (e) {
      Logger.error('Failed to check for updates', error: e);
      return null;
    } finally {
      _isCheckingForUpdates = false;
    }
  }

  /// Check for updates silently (no UI)
  Future<UpdateInfo?> checkForUpdatesSilently() async {
    try {
      Logger.debug('Checking for updates silently...');
      final updateInfo = await _updateService.checkForUpdates(showNotification: false);
      
      if (updateInfo != null) {
        _latestUpdateInfo = updateInfo;
        Logger.info('Silent update check: Update available ${updateInfo.latestVersion}');
      }
      
      return updateInfo;
    } catch (e) {
      Logger.error('Silent update check failed', error: e);
      return null;
    }
  }

  /// Force show update dialog if update is available
  void showUpdateDialogIfAvailable() {
    if (_latestUpdateInfo != null && _currentContext != null && _currentContext!.mounted) {
      _showUpdateDialog(_latestUpdateInfo!);
    }
  }

  /// Handle update available event
  void _handleUpdateAvailable(UpdateInfo updateInfo) {
    _latestUpdateInfo = updateInfo;
    Logger.info('Update event received: ${updateInfo.latestVersion}');
    
    // Auto-show dialog for forced updates
    if (updateInfo.isForced && _currentContext != null && _currentContext!.mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  /// Handle network status changes
  void _handleNetworkChange(NetworkStatus status) {
    Logger.debug('Network status changed: $status');
    
    // Trigger update check when WiFi becomes available
    if (status == NetworkStatus.wifi) {
      Logger.debug('WiFi connected, scheduling update check');
      Timer(const Duration(seconds: 2), () {
        checkForUpdatesSilently();
      });
    }
  }

  /// Show update dialog
  void _showUpdateDialog(UpdateInfo updateInfo) {
    if (_currentContext == null || !_currentContext!.mounted) {
      Logger.warning('Cannot show update dialog: context not available');
      return;
    }

    showDialog(
      context: _currentContext!,
      barrierDismissible: !updateInfo.isForced,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onDismiss: () {
          Logger.debug('Update dialog dismissed');
        },
        onUpdateComplete: () {
          Logger.info('Update completed, clearing cached update info');
          _latestUpdateInfo = null;
        },
      ),
    );
  }

  /// Start periodic update checks
  void startPeriodicUpdateChecks({Duration interval = const Duration(hours: 6)}) {
    _stopPeriodicUpdateChecks();
    
    Logger.info('Starting periodic update checks every ${interval.inHours} hours');
    
    _periodicUpdateTimer = Timer.periodic(interval, (timer) {
      Logger.debug('Periodic update check triggered');
      checkForUpdatesSilently();
    });
  }

  /// Stop periodic update checks
  void _stopPeriodicUpdateChecks() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = null;
  }

  /// Start update download
  Future<bool> downloadUpdate() async {
    if (_latestUpdateInfo == null) {
      Logger.warning('No update info available for download');
      return false;
    }

    try {
      Logger.info('Starting update download...');
      return await _updateService.downloadUpdate(_latestUpdateInfo!);
    } catch (e) {
      Logger.error('Failed to download update', error: e);
      return false;
    }
  }

  /// Get current app version info
  Map<String, String> getCurrentVersionInfo() {
    return _updateService.getCurrentVersionInfo();
  }

  /// Check if auto updates are enabled
  bool get autoUpdatesEnabled {
    return _updateService.preferences?.autoCheckEnabled ?? true;
  }

  /// Check if auto download is enabled
  bool get autoDownloadEnabled {
    return _updateService.preferences?.autoDownloadEnabled ?? false;
  }

  /// Enable or disable automatic update checks
  Future<void> setAutoUpdatesEnabled(bool enabled) async {
    if (_updateService.preferences != null) {
      final prefs = _updateService.preferences!;
      prefs.autoCheckEnabled = enabled;
      await _updateService.updatePreferences(prefs);
      
      if (enabled) {
        startPeriodicUpdateChecks();
      } else {
        _stopPeriodicUpdateChecks();
      }
      
      Logger.info('Auto updates ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Cleanup and dispose resources
  void dispose() {
    Logger.info('Disposing AppUpdateManager...');
    
    _stopPeriodicUpdateChecks();
    _updateService.dispose();
    _networkService.dispose();
    _currentContext = null;
    _latestUpdateInfo = null;
    _isInitialized = false;
  }
}