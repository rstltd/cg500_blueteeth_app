import 'dart:async';
import '../utils/logger.dart';
import '../models/update_preferences.dart';
import '../models/update_info.dart';
import '../models/download_progress.dart';
import 'notification_service.dart';
import 'network_service.dart';
import 'update_checker.dart';
import 'download_manager.dart';
import 'install_manager.dart';

// Re-export models for backward compatibility
export '../models/update_info.dart' show UpdateInfo;
export '../models/download_progress.dart' show DownloadProgress;
export '../models/update_type.dart' show UpdateType;

/// Service for handling app updates and version management.
///
/// This service acts as a coordinator/facade that delegates specialized
/// responsibilities to focused services:
/// - [UpdateChecker] - Version checking and update detection
/// - [DownloadManager] - APK download with progress tracking
/// - [InstallManager] - APK installation on Android
///
/// This design follows the Single Responsibility Principle, making each
/// component easier to test and maintain independently.
///
/// Use [UpdateService.withDependencies()] constructor and register via
/// service locator for production use.
class UpdateService {
  /// Named constructor for dependency injection.
  /// Use this when creating instances via the service locator.
  UpdateService.withDependencies({
    required NotificationService notificationService,
    required NetworkService networkService,
    UpdateChecker? updateChecker,
    DownloadManager? downloadManager,
    InstallManager? installManager,
  })  : _notificationService = notificationService,
        _networkService = networkService,
        _updateChecker = updateChecker ?? UpdateChecker.withDependencies(),
        _downloadManager = downloadManager ??
            DownloadManager.withDependencies(
              notificationService: notificationService,
              networkService: networkService,
            ),
        _installManager = installManager ??
            InstallManager.withDependencies(
              notificationService: notificationService,
            );

  final NotificationService _notificationService;
  final NetworkService _networkService;
  final UpdateChecker _updateChecker;
  final DownloadManager _downloadManager;
  final InstallManager _installManager;

  UpdatePreferences? _preferences;

  // Update state
  final StreamController<UpdateInfo> _updateController =
      StreamController<UpdateInfo>.broadcast();

  /// Stream of update availability events
  Stream<UpdateInfo> get updateStream => _updateController.stream;

  /// Stream of download progress updates (delegated to DownloadManager)
  Stream<DownloadProgress> get downloadStream => _downloadManager.downloadStream;

  /// Check if a download is in progress
  bool get isDownloading => _downloadManager.isDownloading;

  /// Initialize the update service
  Future<bool> initialize() async {
    try {
      // Initialize update checker
      await _updateChecker.initialize();

      // Load user preferences
      _preferences = await UpdatePreferences.load();

      // Initialize network service
      await _networkService.initialize();

      final versionInfo = _updateChecker.getCurrentVersionInfo();
      Logger.info(
          'Update Service initialized - Version: ${versionInfo['version']} (${versionInfo['buildNumber']})');
      Logger.info('Update preferences loaded: $_preferences');
      return true;
    } catch (e) {
      Logger.error('Failed to initialize Update Service', error: e);
      return false;
    }
  }

  /// Check for available updates via GitHub Releases
  Future<UpdateInfo?> checkForUpdates({bool showNotification = true}) async {
    try {
      // Check if auto check is enabled
      if (_preferences != null &&
          !_preferences!.autoCheckEnabled &&
          showNotification) {
        Logger.debug('Auto check disabled by user preferences');
        return null;
      }

      final updateInfo = await _updateChecker.checkForUpdates(
        skippedVersions: _preferences?.skippedVersions ?? [],
      );

      if (updateInfo != null) {
        Logger.info(
            'Update available: ${updateInfo.currentVersion} -> ${updateInfo.latestVersion}');

        if (showNotification) {
          _notificationService.showInfo(
            title: 'Update Available',
            message: 'Version ${updateInfo.latestVersion} is now available',
          );
        }

        _updateController.add(updateInfo);
        return updateInfo;
      } else {
        Logger.info('App is up to date');
        if (showNotification) {
          _notificationService.showSuccess(
            title: 'Up to Date',
            message: 'You are using the latest version',
          );
        }
      }
    } catch (e) {
      Logger.error('Error checking for updates', error: e);
      if (showNotification) {
        _notificationService.showError(
          title: 'Update Check Failed',
          message: 'Unable to check for updates. Please try again later.',
        );
      }
    }

    return null;
  }

  /// Download APK update with real-time progress tracking
  Future<String?> downloadUpdate(UpdateInfo updateInfo) async {
    // Check preferences before download
    if (_preferences == null) {
      Logger.error(
          'Update preferences not loaded, cannot check network suitability');
      _notificationService.showError(
        title: 'Configuration Error',
        message: 'Update settings not loaded. Please restart the app.',
      );
      return null;
    }

    return _downloadManager.downloadUpdate(
      updateInfo,
      wifiOnly: _preferences!.wifiOnlyDownload,
    );
  }

  /// Install APK update (Android only)
  Future<bool> installUpdate(String apkPath) async {
    return _installManager.installUpdate(apkPath);
  }

  /// Check if device can install APK files
  Future<bool> canInstallApks() async {
    return _installManager.canInstallApks();
  }

  /// Request APK installation permission
  Future<void> requestInstallPermission() async {
    return _installManager.requestInstallPermission();
  }

  /// Diagnose APK installation permissions and configuration
  Future<Map<String, dynamic>> diagnosePermissions() async {
    return _installManager.diagnosePermissions();
  }

  /// Get current app version info
  Map<String, String> getCurrentVersionInfo() {
    return _updateChecker.getCurrentVersionInfo();
  }

  /// Clean up downloaded update files (keeps only latest version)
  Future<void> cleanupDownloads({String? keepVersion}) async {
    return _downloadManager.cleanupDownloads(keepVersion: keepVersion);
  }

  /// Skip a specific version
  Future<void> skipVersion(String version) async {
    if (_preferences != null) {
      _preferences!.skipVersion(version);
      await _preferences!.save();
      Logger.info('Version $version added to skip list');
    }
  }

  /// Get current update preferences
  UpdatePreferences? get preferences => _preferences;

  /// Update preferences and save
  Future<void> updatePreferences(UpdatePreferences newPreferences) async {
    _preferences = newPreferences;
    await _preferences!.save();
    Logger.info('Update preferences saved: $_preferences');
  }

  /// Check if auto download is enabled and suitable
  bool shouldAutoDownload(UpdateInfo updateInfo) {
    if (_preferences == null || !_preferences!.autoDownloadEnabled) {
      return false;
    }

    return _networkService.isSuitableForDownload(
      wifiOnly: _preferences!.wifiOnlyDownload,
    );
  }

  /// Dispose resources
  void dispose() {
    _updateController.close();
    _downloadManager.dispose();
    _networkService.dispose();
  }
}
