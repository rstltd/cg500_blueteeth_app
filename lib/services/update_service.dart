import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import 'smart_notification_service.dart';

/// Service for handling app updates and version management
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final SmartNotificationService _notificationService = SmartNotificationService();
  
  // Update server configuration
  static const String _updateServerUrl = 'https://your-update-server.com/api';
  static const String _versionCheckEndpoint = '$_updateServerUrl/version';
  static const String _downloadEndpoint = '$_updateServerUrl/download';
  
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
      
      Logger.info('Update Service initialized - Version: $_currentVersion ($_currentBuildNumber)');
      return true;
    } catch (e) {
      Logger.error('Failed to initialize Update Service', error: e);
      return false;
    }
  }

  /// Check for available updates
  Future<UpdateInfo?> checkForUpdates({bool showNotification = true}) async {
    try {
      Logger.info('Checking for updates...');
      
      final response = await http.get(
        Uri.parse(_versionCheckEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Current-Version': _currentVersion ?? '1.0.0',
          'Current-Build': _currentBuildNumber ?? '1',
          'Platform': Platform.isAndroid ? 'android' : 'ios',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updateInfo = UpdateInfo.fromJson(data);
        
        if (updateInfo.hasUpdate) {
          Logger.info('Update available: ${updateInfo.latestVersion}');
          
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
      } else {
        Logger.error('Update check failed: ${response.statusCode}');
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

  /// Download APK update
  Future<bool> downloadUpdate(UpdateInfo updateInfo) async {
    try {
      Logger.info('Starting download for version ${updateInfo.latestVersion}');
      
      final response = await http.get(
        Uri.parse('$_downloadEndpoint/${updateInfo.downloadUrl}'),
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/update_${updateInfo.latestVersion}.apk';
      final file = File(filePath);

      // Write APK file
      await file.writeAsBytes(response.bodyBytes);
      
      _downloadController.add(DownloadProgress(
        progress: 1.0,
        downloadedBytes: response.bodyBytes.length,
        totalBytes: response.bodyBytes.length,
        filePath: filePath,
      ));

      Logger.info('Update downloaded to: $filePath');
      
      _notificationService.showSuccess(
        title: 'Download Complete',
        message: 'Update is ready to install',
      );

      return true;
    } catch (e) {
      Logger.error('Download failed', error: e);
      _notificationService.showError(
        title: 'Download Failed',
        message: 'Unable to download update: $e',
      );
      return false;
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

  /// Dispose resources
  void dispose() {
    _updateController.close();
    _downloadController.close();
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

  /// Compare version strings (e.g., "1.2.3" vs "1.2.4")
  static int _compareVersions(String version1, String version2) {
    List<int> v1Parts = version1.split('.').map(int.parse).toList();
    List<int> v2Parts = version2.split('.').map(int.parse).toList();
    
    int maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    for (int i = 0; i < maxLength; i++) {
      int v1 = i < v1Parts.length ? v1Parts[i] : 0;
      int v2 = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
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