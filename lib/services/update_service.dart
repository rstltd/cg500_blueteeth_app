import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import '../models/update_preferences.dart';
import '../models/update_info.dart';
import '../models/download_progress.dart';
import '../models/update_type.dart';
import '../core/interfaces/update_service_interface.dart';
import '../core/interfaces/notification_service_interface.dart';
import '../core/interfaces/network_service_interface.dart';

// Re-export models for backward compatibility
export '../models/update_info.dart' show UpdateInfo;
export '../models/download_progress.dart' show DownloadProgress;
export '../models/update_type.dart' show UpdateType;

/// Service for handling app updates and version management.
///
/// This service implements [UpdateServiceInterface] and can be used with
/// dependency injection for improved testability.
///
/// Use [UpdateService.withDependencies()] constructor and register via
/// service locator for production use.
class UpdateService implements UpdateServiceInterface {
  /// Named constructor for dependency injection.
  /// Use this when creating instances via the service locator.
  UpdateService.withDependencies({
    required NotificationServiceInterface notificationService,
    required NetworkServiceInterface networkService,
  })  : _notificationService = notificationService,
        _networkService = networkService;

  final NotificationServiceInterface _notificationService;
  final NetworkServiceInterface _networkService;
  
  UpdatePreferences? _preferences;
  static const int _maxRetries = 3;
  
  // GitHub repository configuration
  static const String _githubOwner = 'rstltd';
  static const String _githubRepo = 'cg500_blueteeth_app';
  static const String _githubApiUrl = 'https://api.github.com';
  static const String _releasesEndpoint = '$_githubApiUrl/repos/$_githubOwner/$_githubRepo/releases/latest';
  
  // Local version info
  String? _currentVersion;
  String? _currentBuildNumber;
  
  // Update state
  final StreamController<UpdateInfo> _updateController = 
      StreamController<UpdateInfo>.broadcast();
  final StreamController<DownloadProgress> _downloadController = 
      StreamController<DownloadProgress>.broadcast();
      
  @override
  Stream<UpdateInfo> get updateStream => _updateController.stream;
  @override
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;

  /// Initialize the update service
  @override
  Future<bool> initialize() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      _currentBuildNumber = packageInfo.buildNumber;
      
      // Load user preferences
      _preferences = await UpdatePreferences.load();
      
      // Initialize network service
      await _networkService.initialize();
      
      Logger.info('Update Service initialized - Version: $_currentVersion ($_currentBuildNumber)');
      Logger.info('Update preferences loaded: $_preferences');
      return true;
    } catch (e) {
      Logger.error('Failed to initialize Update Service', error: e);
      return false;
    }
  }

  /// Check for available updates via GitHub Releases
  @override
  Future<UpdateInfo?> checkForUpdates({bool showNotification = true}) async {
    try {
      // Check if auto check is enabled
      if (_preferences != null && !_preferences!.autoCheckEnabled && showNotification) {
        Logger.debug('Auto check disabled by user preferences');
        return null;
      }

      Logger.info('Checking for updates via GitHub Releases...');
      
      final response = await http.get(
        Uri.parse(_releasesEndpoint),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'CG500-BLE-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse GitHub release data
        final latestVersion = _cleanVersionTag(data['tag_name'] ?? '1.0.0');
        // Build complete current version string with build number if available
        final currentVersionBase = _currentVersion ?? '1.0.0';
        final buildNumber = _currentBuildNumber ?? '';
        final currentVersion = buildNumber.isNotEmpty ? '$currentVersionBase+$buildNumber' : currentVersionBase;
        
        // Find APK asset
        final assets = data['assets'] as List<dynamic>? ?? [];
        final apkAsset = assets.firstWhere(
          (asset) => (asset['name'] as String).toLowerCase().endsWith('.apk'),
          orElse: () => null,
        );
        
        if (apkAsset == null) {
          Logger.warning('No APK file found in latest release');
          return null;
        }
        
        final updateInfo = UpdateInfo(
          latestVersion: latestVersion,
          currentVersion: currentVersion,
          downloadUrl: apkAsset['browser_download_url'] ?? '',
          downloadSize: apkAsset['size'] ?? 0,
          releaseNotes: data['body'] ?? 'No release notes available',
          isForced: _isForceUpdate(data['body'] ?? ''),
          updateType: _determineUpdateType(currentVersion, latestVersion),
          releaseDate: DateTime.tryParse(data['published_at'] ?? '') ?? DateTime.now(),
        );
        
        // Log version comparison for debugging
        Logger.debug('Version comparison: current=$currentVersion, latest=$latestVersion');
        Logger.debug('Has update check: ${updateInfo.hasUpdate}');
        
        if (updateInfo.hasUpdate) {
          // Check if this version should be skipped
          if (_preferences != null && _preferences!.shouldSkipVersion(latestVersion)) {
            Logger.info('Version $latestVersion is skipped by user preference');
            return null;
          }

          Logger.info('Update available: $currentVersion -> $latestVersion');
          
          if (showNotification) {
            _notificationService.showInfo(
              title: 'Update Available',
              message: 'Version $latestVersion is now available',
            );
          }
          
          _updateController.add(updateInfo);
          return updateInfo;
        } else {
          Logger.info('App is up to date ($currentVersion)');
          if (showNotification) {
            _notificationService.showSuccess(
              title: 'Up to Date',
              message: 'You are using the latest version',
            );
          }
        }
      } else if (response.statusCode == 404) {
        Logger.warning('No releases found or repository not accessible');
      } else {
        Logger.error('GitHub API error: ${response.statusCode}');
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
  @override
  Future<String?> downloadUpdate(UpdateInfo updateInfo) async {
    return _downloadWithRetry(updateInfo, 0);
  }

  /// Download with retry mechanism and real progress tracking
  Future<String?> _downloadWithRetry(UpdateInfo updateInfo, int attemptNumber) async {
    try {
      // Check network connectivity - ensure preferences are loaded before checking
      if (_preferences == null) {
        Logger.error('Update preferences not loaded, cannot check network suitability');
        _notificationService.showError(
          title: 'Configuration Error',
          message: 'Update settings not loaded. Please restart the app.',
        );
        return null;
      }
      
      if (!_networkService.isSuitableForDownload(
          wifiOnly: _preferences!.wifiOnlyDownload)) {
        final networkStatus = _networkService.getStatusDescription();
        _notificationService.showError(
          title: 'Network Unsuitable',
          message: _preferences!.wifiOnlyDownload == true 
              ? 'WiFi connection required for downloads. Currently: $networkStatus'
              : 'No internet connection available',
        );
        return null;
      }

      // Show network info for mobile data
      if (_networkService.currentStatus == NetworkStatus.mobile && 
          _preferences!.wifiOnlyDownload == false) {
        final estimatedTime = _networkService.estimateDownloadTime(updateInfo.downloadSize);
        Logger.info('Downloading via mobile data - Estimated time: $estimatedTime');
      }

      Logger.info('Starting download from GitHub (attempt ${attemptNumber + 1}): ${updateInfo.downloadUrl}');
      
      // Initialize progress
      _downloadController.add(DownloadProgress(
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: updateInfo.downloadSize > 0 ? updateInfo.downloadSize : 10 * 1024 * 1024, // Default 10MB if unknown
        status: 'Starting download...',
      ));
      
      // Use HttpClient for better progress tracking
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      client.idleTimeout = const Duration(minutes: 5);
      
      try {
        final request = await client.getUrl(Uri.parse(updateInfo.downloadUrl));
        request.headers.add('Accept', 'application/octet-stream');
        request.headers.add('User-Agent', 'CG500-BLE-App');
        
        final response = await request.close();
        
        if (response.statusCode != 200) {
          throw Exception('Download failed with status: ${response.statusCode}');
        }
        
        // Get content length from headers
        final contentLength = response.contentLength > 0 
            ? response.contentLength 
            : updateInfo.downloadSize;
        
        // Setup file path - use app files directory for better FileProvider compatibility
        Directory directory;
        try {
          directory = await getApplicationDocumentsDirectory();
          Logger.info('Using documents directory: ${directory.path}');
        } catch (e) {
          // Fallback to support directory if documents directory fails
          directory = await getApplicationSupportDirectory();
          Logger.warning('Documents directory failed, using support directory: ${directory.path}');
        }
        
        final filePath = '${directory.path}/cg500_ble_app_${updateInfo.latestVersion}.apk';
        final file = File(filePath);
        
        // Delete existing file if it exists
        if (await file.exists()) {
          await file.delete();
        }
        
        // Download with progress tracking
        final sink = file.openWrite();
        int downloadedBytes = 0;
        final startTime = DateTime.now();
        
        await response.listen(
          (List<int> chunk) {
            sink.add(chunk);
            downloadedBytes += chunk.length;
            
            final progress = contentLength > 0 
                ? downloadedBytes / contentLength 
                : 0.0;
            
            final elapsed = DateTime.now().difference(startTime);
            final speed = downloadedBytes / elapsed.inSeconds;
            final remainingBytes = contentLength - downloadedBytes;
            final estimatedRemaining = speed > 0 
                ? Duration(seconds: (remainingBytes / speed).round())
                : Duration.zero;
            
            _downloadController.add(DownloadProgress(
              progress: progress.clamp(0.0, 1.0),
              downloadedBytes: downloadedBytes,
              totalBytes: contentLength,
              status: 'Downloading... ${_formatBytes(downloadedBytes)}/${_formatBytes(contentLength)}',
              speed: speed,
              estimatedTimeRemaining: estimatedRemaining,
            ));
          },
          onDone: () async {
            await sink.flush();
            await sink.close();
            client.close();
          },
          onError: (error) async {
            await sink.close();
            client.close();
            throw error;
          },
        ).asFuture();
        
        // Final progress update
        _downloadController.add(DownloadProgress(
          progress: 1.0,
          downloadedBytes: downloadedBytes,
          totalBytes: contentLength,
          status: 'Download complete',
          filePath: filePath,
        ));

        Logger.info('APK downloaded successfully: $filePath (${_formatBytes(downloadedBytes)})');
        
        _notificationService.showSuccess(
          title: 'Download Complete',
          message: 'Update ready to install (${_formatBytes(downloadedBytes)})',
        );

        return filePath;
      } finally {
        client.close();
      }
    } catch (e) {
      Logger.error('Download failed (attempt ${attemptNumber + 1})', error: e);
      
      // Reset progress on failure
      _downloadController.add(DownloadProgress(
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 1,
        status: 'Download failed: $e',
      ));
      
      // Retry if we haven't exceeded max retries
      if (attemptNumber < _maxRetries - 1) {
        Logger.info('Retrying download in 5 seconds... (${attemptNumber + 2}/$_maxRetries)');
        
        _notificationService.showInfo(
          title: 'Download Failed',
          message: 'Retrying download (${attemptNumber + 2}/$_maxRetries)...',
        );
        
        await Future.delayed(const Duration(seconds: 5));
        return _downloadWithRetry(updateInfo, attemptNumber + 1);
      } else {
        _notificationService.showError(
          title: 'Download Failed',
          message: 'Unable to download after $_maxRetries attempts. Check network connection.',
        );
        return null;
      }
    }
  }

  /// Install APK update (Android only)
  @override
  Future<bool> installUpdate(String apkPath) async {
    if (!Platform.isAndroid) {
      Logger.warning('APK installation only supported on Android');
      _notificationService.showError(
        title: 'Platform Not Supported',
        message: 'APK installation is only available on Android devices.',
      );
      return false;
    }

    try {
      Logger.info('Starting APK installation process...');
      Logger.info('APK path: $apkPath');
      
      // Check if file exists
      final file = File(apkPath);
      if (!await file.exists()) {
        Logger.error('APK file does not exist at path: $apkPath');
        _notificationService.showError(
          title: 'Installation Failed',
          message: 'APK file not found. Please try downloading again.',
        );
        return false;
      }
      
      Logger.info('APK file exists, size: ${await file.length()} bytes');
      
      // Use platform channel to check and request permissions
      const platform = MethodChannel('com.cg500.ble_app/update');
      
      // Check if we can install APKs
      final canInstall = await platform.invokeMethod('canInstallApks');
      Logger.info('Can install APKs: $canInstall');
      
      if (!canInstall) {
        Logger.warning('Unknown sources permission not granted');
        _notificationService.showError(
          title: 'Permission Required',
          message: 'Please allow installation from unknown sources in device settings.',
        );
        
        // Request permission
        await platform.invokeMethod('requestInstallPermission');
        return false;
      }
      
      Logger.info('Calling platform method installApk...');
      final result = await platform.invokeMethod('installApk', {'filePath': apkPath});
      
      Logger.info('Install APK platform channel result: $result');
      
      // Handle detailed result from Android
      if (result is Map) {
        final installResult = Map<String, dynamic>.from(result);
        final success = installResult['success'] ?? false;
        
        Logger.info('Installation result details: $installResult');
        
        if (success) {
          Logger.info('✅ APK installation started successfully');
          _notificationService.showSuccess(
            title: 'Installation Started',
            message: 'Please follow the installation prompts.',
          );
          return true;
        } else {
          final error = installResult['error'] ?? 'Unknown error';
          final errorType = installResult['errorType'] ?? 'UNKNOWN';
          
          Logger.error('❌ APK installation failed', error: '$errorType: $error');
          
          // Show specific error messages based on error type
          switch (errorType) {
            case 'PERMISSION_DENIED':
              Logger.warning('Permission denied - requesting install permission');
              _notificationService.showError(
                title: 'Permission Required',
                message: 'Please allow installation from unknown sources in device settings, then try again.',
              );
              // Automatically request permission
              await platform.invokeMethod('requestInstallPermission');
              break;
            case 'FILE_NOT_FOUND':
              _notificationService.showError(
                title: 'File Not Found',
                message: 'The APK file could not be found. Please try downloading again.',
              );
              break;
            case 'FILEPROVIDER_ERROR':
              _notificationService.showError(
                title: 'File Access Error',
                message: 'Could not access the APK file for installation. Check app permissions.',
              );
              break;
            case 'NO_RESOLVER':
              _notificationService.showError(
                title: 'Installation Not Supported',
                message: 'No app found to handle APK installation on this device.',
              );
              break;
            default:
              _notificationService.showError(
                title: 'Installation Failed',
                message: 'Error: $error',
              );
          }
          return false;
        }
      } else if (result == true) {
        // Legacy boolean result handling
        Logger.info('✅ APK installation triggered successfully (legacy result)');
        _notificationService.showSuccess(
          title: 'Installation Started',
          message: 'Follow the installation prompts to complete the update.',
        );
        return true;
      } else {
        Logger.warning('❌ APK installation trigger returned: $result');
        _notificationService.showError(
          title: 'Installation Failed',
          message: 'Could not start APK installation. Please check permissions.',
        );
        return false;
      }
    } catch (e) {
      Logger.error('❌ Failed to install APK via platform channel', error: e);
      _notificationService.showError(
        title: 'Installation Error',
        message: 'Failed to install update: ${e.toString()}',
      );
      return false;
    }
  }

  /// Check if device can install APK files
  @override
  Future<bool> canInstallApks() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      const platform = MethodChannel('com.cg500.ble_app/update');
      final canInstall = await platform.invokeMethod('canInstallApks');
      return canInstall ?? false;
    } catch (e) {
      Logger.error('Failed to check APK installation permission', error: e);
      return false;
    }
  }

  /// Request APK installation permission
  @override
  Future<void> requestInstallPermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      const platform = MethodChannel('com.cg500.ble_app/update');
      await platform.invokeMethod('requestInstallPermission');
    } catch (e) {
      Logger.error('Failed to request APK installation permission', error: e);
    }
  }

  /// Diagnose APK installation permissions and configuration
  @override
  Future<Map<String, dynamic>> diagnosePermissions() async {
    if (!Platform.isAndroid) {
      return {'platform': 'non-android', 'supported': false};
    }

    try {
      const platform = MethodChannel('com.cg500.ble_app/update');
      final result = await platform.invokeMethod('diagnosePermissions');
      
      if (result is Map) {
        final diagnosis = Map<String, dynamic>.from(result);
        Logger.info('Permission diagnosis completed: $diagnosis');
        return diagnosis;
      } else {
        Logger.warning('Unexpected diagnosis result type: ${result.runtimeType}');
        return {'error': 'Unexpected result type', 'raw_result': result.toString()};
      }
    } catch (e) {
      Logger.error('Failed to diagnose permissions', error: e);
      return {'error': 'Diagnosis failed', 'exception': e.toString()};
    }
  }

  /// Get current app version info
  @override
  Map<String, String> getCurrentVersionInfo() {
    return {
      'version': _currentVersion ?? 'Unknown',
      'buildNumber': _currentBuildNumber ?? 'Unknown',
    };
  }

  /// Clean up downloaded update files (keeps only latest version)
  @override
  Future<void> cleanupDownloads({String? keepVersion}) async {
    try {
      Directory directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        directory = await getApplicationSupportDirectory();
      }
      final files = directory.listSync();
      
      for (final file in files) {
        if (file.path.endsWith('.apk') && file.path.contains('cg500_ble_app_')) {
          // Keep the specified version file
          if (keepVersion != null && file.path.contains('_$keepVersion.apk')) {
            Logger.debug('Keeping file: ${file.path}');
            continue;
          }
          
          await file.delete();
          Logger.debug('Cleaned up: ${file.path}');
        }
      }
      
      Logger.info('Download cleanup completed');
    } catch (e) {
      Logger.error('Failed to cleanup downloads', error: e);
    }
  }

  /// Clean version tag (remove 'v' prefix if present)
  String _cleanVersionTag(String tag) {
    return tag.startsWith('v') ? tag.substring(1) : tag;
  }

  /// Determine if this is a forced update based on release notes
  bool _isForceUpdate(String releaseNotes) {
    final lowerNotes = releaseNotes.toLowerCase();
    return lowerNotes.contains('[forced]') || 
           lowerNotes.contains('[critical]') ||
           lowerNotes.contains('security fix') ||
           lowerNotes.contains('critical fix');
  }

  /// Determine update type based on version difference
  UpdateType _determineUpdateType(String currentVersion, String latestVersion) {
    try {
      // Remove build numbers for comparison
      final currentClean = currentVersion.split('+')[0];
      final latestClean = latestVersion.split('+')[0];
      
      final current = currentClean.split('.').map(int.parse).toList();
      final latest = latestClean.split('.').map(int.parse).toList();
      
      // Ensure both lists have at least 3 elements (major.minor.patch)
      while (current.length < 3) {
        current.add(0);
      }
      while (latest.length < 3) {
        latest.add(0);
      }
      
      // Major version change
      if (latest[0] > current[0]) return UpdateType.recommended;
      
      // Minor version change  
      if (latest[1] > current[1]) return UpdateType.recommended;
      
      // Patch version change
      if (latest[2] > current[2]) return UpdateType.optional;
      
      return UpdateType.optional;
    } catch (e) {
      return UpdateType.optional;
    }
  }

  /// Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Skip a specific version
  @override
  Future<void> skipVersion(String version) async {
    if (_preferences != null) {
      _preferences!.skipVersion(version);
      await _preferences!.save();
      Logger.info('Version $version added to skip list');
    }
  }

  /// Get current update preferences
  @override
  UpdatePreferences? get preferences => _preferences;

  /// Update preferences and save
  @override
  Future<void> updatePreferences(UpdatePreferences newPreferences) async {
    _preferences = newPreferences;
    await _preferences!.save();
    Logger.info('Update preferences saved: $_preferences');
  }

  /// Check if auto download is enabled and suitable
  @override
  bool shouldAutoDownload(UpdateInfo updateInfo) {
    if (_preferences == null || !_preferences!.autoDownloadEnabled) {
      return false;
    }
    
    return _networkService.isSuitableForDownload(
      wifiOnly: _preferences!.wifiOnlyDownload,
    );
  }

  /// Dispose resources
  @override
  void dispose() {
    _updateController.close();
    _downloadController.close();
    _networkService.dispose();
  }
}