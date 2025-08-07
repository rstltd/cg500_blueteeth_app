import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import '../models/update_preferences.dart';
import 'smart_notification_service.dart';
import 'network_service.dart';

/// Service for handling app updates and version management
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final SmartNotificationService _notificationService = SmartNotificationService();
  final NetworkService _networkService = NetworkService();
  
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
      
  Stream<UpdateInfo> get updateStream => _updateController.stream;
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;

  /// Initialize the update service
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
      
      if (result == true) {
        Logger.info('✅ APK installation triggered successfully');
        _notificationService.showSuccess(
          title: 'Installation Started',
          message: 'Follow the installation prompts to complete the update.',
        );
        return true;
      } else {
        Logger.warning('❌ APK installation trigger returned false');
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
  Map<String, String> getCurrentVersionInfo() {
    return {
      'version': _currentVersion ?? 'Unknown',
      'buildNumber': _currentBuildNumber ?? 'Unknown',
    };
  }

  /// Clean up downloaded update files (keeps only latest version)
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
    _downloadController.close();
    _networkService.dispose();
  }
}

/// Update information model
class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final int downloadSize;
  final String releaseNotes;
  final bool isForced;
  final UpdateType updateType;
  final DateTime releaseDate;

  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.downloadSize,
    required this.releaseNotes,
    this.isForced = false,
    this.updateType = UpdateType.optional,
    required this.releaseDate,
  });

  bool get hasUpdate => _compareVersions(latestVersion, currentVersion) > 0;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'] ?? '1.0.0',
      currentVersion: json['current_version'] ?? '1.0.0',
      downloadUrl: json['download_url'] ?? '',
      downloadSize: json['download_size'] ?? 0,
      releaseNotes: json['release_notes'] ?? '',
      isForced: json['is_forced'] ?? false,
      updateType: UpdateType.values.firstWhere(
        (type) => type.name == json['update_type'],
        orElse: () => UpdateType.optional,
      ),
      releaseDate: DateTime.tryParse(json['release_date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'current_version': currentVersion,
      'download_url': downloadUrl,
      'download_size': downloadSize,
      'release_notes': releaseNotes,
      'is_forced': isForced,
      'update_type': updateType.name,
      'release_date': releaseDate.toIso8601String(),
    };
  }

  /// Compare version strings (e.g., "1.2.3" vs "1.2.4+5")
  static int _compareVersions(String version1, String version2) {
    // Log for debugging
    Logger.debug('Comparing versions: "$version1" vs "$version2"');
    
    // Remove build numbers (everything after +)
    String v1Clean = version1.split('+')[0];
    String v2Clean = version2.split('+')[0];
    
    Logger.debug('Clean versions: "$v1Clean" vs "$v2Clean"');
    
    try {
      List<int> v1Parts = v1Clean.split('.').map(int.parse).toList();
      List<int> v2Parts = v2Clean.split('.').map(int.parse).toList();
      
      // Ensure both lists have at least 3 elements (major.minor.patch)
      while (v1Parts.length < 3) {
        v1Parts.add(0);
      }
      while (v2Parts.length < 3) {
        v2Parts.add(0);
      }
      
      Logger.debug('Version parts: v1=$v1Parts, v2=$v2Parts');
      
      for (int i = 0; i < 3; i++) {
        if (v1Parts[i] < v2Parts[i]) {
          Logger.debug('v1[$i]=${v1Parts[i]} < v2[$i]=${v2Parts[i]} -> -1');
          return -1;
        }
        if (v1Parts[i] > v2Parts[i]) {
          Logger.debug('v1[$i]=${v1Parts[i]} > v2[$i]=${v2Parts[i]} -> 1');
          return 1;
        }
      }
      
      // If main versions are equal, compare build numbers if present
      List<String> v1Build = version1.split('+');
      List<String> v2Build = version2.split('+');
      
      Logger.debug('Build parts: v1Build=${v1Build.length > 1 ? v1Build[1] : 'none'}, v2Build=${v2Build.length > 1 ? v2Build[1] : 'none'}');
      
      if (v1Build.length > 1 && v2Build.length > 1) {
        try {
          int build1 = int.parse(v1Build[1]);
          int build2 = int.parse(v2Build[1]);
          Logger.debug('Comparing builds: $build1 vs $build2');
          if (build1 < build2) return -1;
          if (build1 > build2) return 1;
        } catch (e) {
          // If build numbers can't be parsed, ignore them
          Logger.debug('Failed to parse build numbers: $e');
        }
      } else if (v2Build.length > 1) {
        // Version2 has build number, version1 doesn't - version2 is newer
        Logger.debug('v2 has build number, v1 doesn\'t -> -1');
        return -1;
      } else if (v1Build.length > 1) {
        // Version1 has build number, version2 doesn't - version1 is newer
        Logger.debug('v1 has build number, v2 doesn\'t -> 1');
        return 1;
      }
      
      Logger.debug('Versions are equal -> 0');
      return 0;
    } catch (e) {
      Logger.error('Error comparing versions: $version1 vs $version2', error: e);
      return 0; // Treat as equal if there's an error
    }
  }
}

/// Download progress information with enhanced tracking
class DownloadProgress {
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final String? filePath;
  final String status;
  final double? speed; // bytes per second
  final Duration? estimatedTimeRemaining;

  const DownloadProgress({
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    this.filePath,
    this.status = '',
    this.speed,
    this.estimatedTimeRemaining,
  });

  String get progressText => '${(progress * 100).toInt()}%';
  String get sizeText => '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}';
  
  String get speedText {
    if (speed == null || speed! <= 0) return '';
    return '${_formatBytes(speed!.round())}/s';
  }
  
  String get timeRemainingText {
    if (estimatedTimeRemaining == null) return '';
    final duration = estimatedTimeRemaining!;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s remaining';
    } else {
      return '${duration.inSeconds}s remaining';
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Update type enumeration
enum UpdateType {
  optional,      // User can choose to update
  recommended,   // Strongly recommended but not forced
  critical,      // Critical security/bug fixes
  forced,        // Must update to continue using app
}