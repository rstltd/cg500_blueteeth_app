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
        final currentVersion = _currentVersion ?? '1.0.0';
        
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

  /// Download APK update directly from GitHub
  Future<bool> downloadUpdate(UpdateInfo updateInfo) async {
    return _downloadWithRetry(updateInfo, 0);
  }

  /// Download with retry mechanism
  Future<bool> _downloadWithRetry(UpdateInfo updateInfo, int attemptNumber) async {
    try {
      // Check network connectivity
      if (!_networkService.isSuitableForDownload(
          wifiOnly: _preferences?.wifiOnlyDownload ?? true)) {
        final networkStatus = _networkService.getStatusDescription();
        _notificationService.showError(
          title: 'Network Unsuitable',
          message: _preferences?.wifiOnlyDownload == true 
              ? 'WiFi connection required for downloads. Currently: $networkStatus'
              : 'No internet connection available',
        );
        return false;
      }

      // Show network warning for mobile data
      if (_networkService.currentStatus == NetworkStatus.mobile && 
          _preferences?.wifiOnlyDownload != false) {
        final estimatedTime = _networkService.estimateDownloadTime(updateInfo.downloadSize);
        Logger.info('Downloading via mobile data - Estimated time: $estimatedTime');
      }

      Logger.info('Downloading from GitHub (attempt ${attemptNumber + 1}): ${updateInfo.downloadUrl}');
      
      // Download directly from GitHub's download URL
      final response = await http.get(
        Uri.parse(updateInfo.downloadUrl),
        headers: {
          'Accept': 'application/octet-stream',
          'User-Agent': 'CG500-BLE-App',
        },
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/cg500_ble_app_${updateInfo.latestVersion}.apk';
      final file = File(filePath);

      // Write APK file
      await file.writeAsBytes(response.bodyBytes);
      
      _downloadController.add(DownloadProgress(
        progress: 1.0,
        downloadedBytes: response.bodyBytes.length,
        totalBytes: response.bodyBytes.length,
        filePath: filePath,
      ));

      Logger.info('APK downloaded successfully: $filePath (${_formatBytes(response.bodyBytes.length)})');
      
      _notificationService.showSuccess(
        title: 'Download Complete',
        message: 'Update is ready to install',
      );

      return true;
    } catch (e) {
      Logger.error('Download failed (attempt ${attemptNumber + 1})', error: e);
      
      // Retry if we haven't exceeded max retries
      if (attemptNumber < _maxRetries - 1) {
        Logger.info('Retrying download in 3 seconds... (${attemptNumber + 2}/$_maxRetries)');
        
        _notificationService.showInfo(
          title: 'Download Failed',
          message: 'Retrying download (${attemptNumber + 2}/$_maxRetries)...',
        );
        
        await Future.delayed(const Duration(seconds: 3));
        return _downloadWithRetry(updateInfo, attemptNumber + 1);
      } else {
        _notificationService.showError(
          title: 'Download Failed',
          message: 'Unable to download update after $_maxRetries attempts: $e',
        );
        return false;
      }
    }
  }

  /// Install APK update (Android only)
  Future<bool> installUpdate(String apkPath) async {
    if (!Platform.isAndroid) {
      Logger.warning('APK installation only supported on Android');
      return false;
    }

    try {
      // Use platform channel to install APK
      const platform = MethodChannel('com.cg500.ble_app/update');
      final result = await platform.invokeMethod('installApk', {'filePath': apkPath});
      
      Logger.info('Install APK result: $result');
      return result == true;
    } catch (e) {
      Logger.error('Failed to install APK', error: e);
      return false;
    }
  }

  /// Get current app version info
  Map<String, String> getCurrentVersionInfo() {
    return {
      'version': _currentVersion ?? 'Unknown',
      'buildNumber': _currentBuildNumber ?? 'Unknown',
    };
  }

  /// Clean up downloaded update files
  Future<void> cleanupDownloads() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file.path.contains('update_') && file.path.endsWith('.apk')) {
          await file.delete();
          Logger.debug('Cleaned up: ${file.path}');
        }
      }
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
    // Remove build numbers (everything after +)
    String v1Clean = version1.split('+')[0];
    String v2Clean = version2.split('+')[0];
    
    List<int> v1Parts = v1Clean.split('.').map(int.parse).toList();
    List<int> v2Parts = v2Clean.split('.').map(int.parse).toList();
    
    // Ensure both lists have at least 3 elements (major.minor.patch)
    while (v1Parts.length < 3) {
      v1Parts.add(0);
    }
    while (v2Parts.length < 3) {
      v2Parts.add(0);
    }
    
    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    
    // If main versions are equal, compare build numbers if present
    List<String> v1Build = version1.split('+');
    List<String> v2Build = version2.split('+');
    
    if (v1Build.length > 1 && v2Build.length > 1) {
      try {
        int build1 = int.parse(v1Build[1]);
        int build2 = int.parse(v2Build[1]);
        if (build1 < build2) return -1;
        if (build1 > build2) return 1;
      } catch (e) {
        // If build numbers can't be parsed, ignore them
      }
    } else if (v2Build.length > 1) {
      // Version2 has build number, version1 doesn't - version2 is newer
      return -1;
    } else if (v1Build.length > 1) {
      // Version1 has build number, version2 doesn't - version1 is newer
      return 1;
    }
    
    return 0;
  }
}

/// Download progress information
class DownloadProgress {
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final String? filePath;

  const DownloadProgress({
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    this.filePath,
  });

  String get progressText => '${(progress * 100).toInt()}%';
  String get sizeText => '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}';

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