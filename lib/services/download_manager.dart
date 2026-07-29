import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import '../models/update_info.dart';
import '../models/download_progress.dart';
import 'notification_service.dart';
import 'network_service.dart';
import '../l10n/app_strings.dart';

/// Service responsible for downloading app updates with progress tracking.
///
/// This service handles:
/// - APK file downloads from GitHub Releases
/// - Real-time download progress reporting
/// - Retry mechanism with exponential backoff
/// - SHA256 checksum verification
/// - Cleanup of temporary/old download files
///
/// Use [DownloadManager.withDependencies()] constructor for dependency injection.
class DownloadManager {
  /// Named constructor for dependency injection.
  DownloadManager.withDependencies({
    required NotificationService notificationService,
    required NetworkService networkService,
  })  : _notificationService = notificationService,
        _networkService = networkService;

  final NotificationService _notificationService;
  final NetworkService _networkService;

  static const int _maxRetries = 3;

  // Download concurrency lock - prevents multiple simultaneous downloads
  Completer<String?>? _downloadCompleter;
  bool get isDownloading =>
      _downloadCompleter != null && !_downloadCompleter!.isCompleted;

  // Progress throttling - reduces UI rebuilds
  DateTime? _lastProgressUpdate;
  static const Duration _progressThrottleInterval = Duration(milliseconds: 100);

  // Exponential backoff configuration
  static const int _baseRetryDelaySeconds = 5;

  // Download state
  final StreamController<DownloadProgress> _downloadController =
      StreamController<DownloadProgress>.broadcast();

  /// Stream of download progress updates
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;

  /// Download APK update with real-time progress tracking
  ///
  /// Uses a Completer-based lock to prevent concurrent downloads.
  /// If a download is already in progress, returns the existing download's future.
  ///
  /// [updateInfo] - Information about the update to download
  /// [wifiOnly] - If true, only download on WiFi connection
  Future<String?> downloadUpdate(
    UpdateInfo updateInfo, {
    bool wifiOnly = true,
  }) async {
    // Check if download is already in progress
    if (_downloadCompleter != null && !_downloadCompleter!.isCompleted) {
      Logger.info('Download already in progress, returning existing future');
      return _downloadCompleter!.future;
    }

    // Create new download lock
    _downloadCompleter = Completer<String?>();
    _lastProgressUpdate = null; // Reset progress throttle

    try {
      final result = await _downloadWithRetry(updateInfo, 0, wifiOnly);
      _downloadCompleter!.complete(result);
      return result;
    } catch (e) {
      _downloadCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Download with retry mechanism and real progress tracking
  Future<String?> _downloadWithRetry(
    UpdateInfo updateInfo,
    int attemptNumber,
    bool wifiOnly,
  ) async {
    try {
      // Check network connectivity
      if (!_networkService.isSuitableForDownload(wifiOnly: wifiOnly)) {
        final networkStatus = _networkService.getStatusDescription();
        _notificationService.showError(
          title: AppStrings.downloadNetworkUnsuitableTitle,
          message: wifiOnly
              ? AppStrings.downloadWifiRequiredMessage(networkStatus)
              : AppStrings.downloadNoInternetAvailableMessage,
        );
        return null;
      }

      // Show network info for mobile data
      if (_networkService.currentStatus == NetworkStatus.mobile && !wifiOnly) {
        final estimatedTime =
            _networkService.estimateDownloadTime(updateInfo.downloadSize);
        Logger.info(
            'Downloading via mobile data - Estimated time: $estimatedTime');
      }

      Logger.info(
          'Starting download from GitHub (attempt ${attemptNumber + 1}): ${updateInfo.downloadUrl}');

      // Initialize progress
      _downloadController.add(DownloadProgress(
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: updateInfo.downloadSize > 0
            ? updateInfo.downloadSize
            : 10 * 1024 * 1024, // Default 10MB if unknown
        status: AppStrings.downloadStatusStarting,
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

        // Setup file path - use app files directory for FileProvider compatibility
        Directory directory;
        try {
          directory = await getApplicationDocumentsDirectory();
          Logger.info('Using documents directory: ${directory.path}');
        } catch (e) {
          // Fallback to support directory if documents directory fails
          directory = await getApplicationSupportDirectory();
          Logger.warning(
              'Documents directory failed, using support directory: ${directory.path}');
        }

        final filePath =
            '${directory.path}/cg500_ble_app_${updateInfo.latestVersion}.apk';
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

            // Throttle progress updates to reduce UI rebuilds (100ms interval)
            final now = DateTime.now();
            final shouldUpdate = _lastProgressUpdate == null ||
                now.difference(_lastProgressUpdate!) >= _progressThrottleInterval;

            if (shouldUpdate) {
              _lastProgressUpdate = now;

              final progress =
                  contentLength > 0 ? downloadedBytes / contentLength : 0.0;

              final elapsed = now.difference(startTime);
              final elapsedSeconds = elapsed.inMilliseconds / 1000.0;
              final speed =
                  elapsedSeconds > 0 ? downloadedBytes / elapsedSeconds : 0.0;
              final remainingBytes = contentLength - downloadedBytes;
              final estimatedRemaining = speed > 0
                  ? Duration(seconds: (remainingBytes / speed).round())
                  : Duration.zero;

              _downloadController.add(DownloadProgress(
                progress: progress.clamp(0.0, 1.0),
                downloadedBytes: downloadedBytes,
                totalBytes: contentLength,
                status:
                    AppStrings.downloadStatusProgress(_formatBytes(downloadedBytes), _formatBytes(contentLength)),
                speed: speed,
                estimatedTimeRemaining: estimatedRemaining,
              ));
            }
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

        // Verify SHA256 checksum if provided
        if (updateInfo.hasChecksum) {
          _downloadController.add(DownloadProgress(
            progress: 1.0,
            downloadedBytes: downloadedBytes,
            totalBytes: contentLength,
            status: AppStrings.downloadStatusVerifying,
          ));

          final isValid =
              await _verifyFileChecksum(file, updateInfo.sha256Checksum!);
          if (!isValid) {
            Logger.error('SHA256 checksum verification failed');
            await file.delete();
            _notificationService.showError(
              title: AppStrings.downloadVerificationFailedTitle,
              message: AppStrings.downloadCorruptedMessage,
            );
            return null;
          }
          Logger.info('SHA256 checksum verified successfully');
        } else {
          Logger.debug(
              'No checksum provided, skipping verification (backward compatible)');
        }

        // Final progress update
        _downloadController.add(DownloadProgress(
          progress: 1.0,
          downloadedBytes: downloadedBytes,
          totalBytes: contentLength,
          status: AppStrings.downloadStatusComplete,
          filePath: filePath,
        ));

        Logger.info(
            'APK downloaded successfully: $filePath (${_formatBytes(downloadedBytes)})');

        _notificationService.showSuccess(
          title: AppStrings.downloadCompleteTitle,
          message: AppStrings.downloadReadyToInstallMessage(_formatBytes(downloadedBytes)),
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
        status: AppStrings.downloadStatusFailed(e),
      ));

      // Retry if we haven't exceeded max retries with exponential backoff
      if (attemptNumber < _maxRetries - 1) {
        final retryDelay = _getRetryDelayForAttempt(attemptNumber);
        Logger.info(
            'Retrying download in ${retryDelay.inSeconds} seconds... (${attemptNumber + 2}/$_maxRetries)');

        _notificationService.showInfo(
          title: AppStrings.downloadFailedTitle,
          message:
              AppStrings.downloadRetryingMessage(retryDelay.inSeconds, attemptNumber + 2, _maxRetries),
        );

        await Future.delayed(retryDelay);
        return _downloadWithRetry(updateInfo, attemptNumber + 1, wifiOnly);
      } else {
        _notificationService.showError(
          title: AppStrings.downloadFailedTitle,
          message:
              AppStrings.downloadExhaustedMessage(_maxRetries),
        );
        return null;
      }
    }
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

  /// Verify file SHA256 checksum
  Future<bool> _verifyFileChecksum(File file, String expectedChecksum) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final actualChecksum = digest.toString().toLowerCase();
      final expected = expectedChecksum.toLowerCase();

      Logger.debug('Expected checksum: $expected');
      Logger.debug('Actual checksum: $actualChecksum');

      return actualChecksum == expected;
    } catch (e) {
      Logger.error('Error verifying checksum', error: e);
      return false;
    }
  }

  /// Calculate retry delay with exponential backoff
  ///
  /// Returns delay duration based on attempt number:
  /// - Attempt 0: 5 seconds
  /// - Attempt 1: 10 seconds
  /// - Attempt 2: 20 seconds
  Duration _getRetryDelayForAttempt(int attemptNumber) {
    final seconds =
        _baseRetryDelaySeconds * (1 << attemptNumber); // 5, 10, 20
    return Duration(seconds: seconds);
  }

  /// Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Dispose resources
  void dispose() {
    _downloadController.close();
  }
}
