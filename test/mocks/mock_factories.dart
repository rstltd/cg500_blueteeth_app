import 'package:cg500_blueteeth_app/models/update_info.dart';
import 'package:cg500_blueteeth_app/models/download_progress.dart';
import 'package:cg500_blueteeth_app/models/update_type.dart';

/// Factory class for creating mock UpdateInfo instances for testing.
///
/// Provides convenient factory methods with sensible defaults that can be
/// overridden for specific test scenarios.
class MockUpdateInfoFactory {
  /// Create a standard update info with optional overrides
  static UpdateInfo create({
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
    String downloadUrl = 'https://example.com/app.apk',
    int downloadSize = 10 * 1024 * 1024, // 10 MB
    String releaseNotes = 'Bug fixes and improvements',
    bool isForced = false,
    UpdateType updateType = UpdateType.optional,
    DateTime? releaseDate,
  }) {
    return UpdateInfo(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      downloadUrl: downloadUrl,
      downloadSize: downloadSize,
      releaseNotes: releaseNotes,
      isForced: isForced,
      updateType: updateType,
      releaseDate: releaseDate ?? DateTime.now(),
    );
  }

  /// Create an update info where hasUpdate returns true
  static UpdateInfo withUpdate({
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
    UpdateType updateType = UpdateType.optional,
    bool isForced = false,
    String? releaseNotes,
    int? downloadSize,
  }) {
    return create(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      updateType: updateType,
      isForced: isForced,
      releaseNotes: releaseNotes ?? 'New version available',
      downloadSize: downloadSize ?? 10 * 1024 * 1024,
    );
  }

  /// Create an update info where hasUpdate returns false (same version)
  static UpdateInfo noUpdate({
    String version = '1.0.0',
  }) {
    return create(
      latestVersion: version,
      currentVersion: version,
    );
  }

  /// Create a forced update info
  static UpdateInfo forced({
    String latestVersion = '3.0.0',
    String currentVersion = '1.0.0',
    String releaseNotes = 'Critical security update - installation required',
  }) {
    return create(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      isForced: true,
      updateType: UpdateType.forced,
      releaseNotes: releaseNotes,
    );
  }

  /// Create a critical update info (important but not forced)
  static UpdateInfo critical({
    String latestVersion = '2.5.0',
    String currentVersion = '1.0.0',
    String releaseNotes = 'Critical bug fixes',
  }) {
    return create(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      isForced: false,
      updateType: UpdateType.critical,
      releaseNotes: releaseNotes,
    );
  }

  /// Create a recommended update info
  static UpdateInfo recommended({
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
    String releaseNotes = 'Recommended improvements',
  }) {
    return create(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      isForced: false,
      updateType: UpdateType.recommended,
      releaseNotes: releaseNotes,
    );
  }

  /// Create an update with specific version bump type
  static UpdateInfo majorUpdate({String currentVersion = '1.0.0'}) {
    final parts = currentVersion.split('.');
    final major = int.parse(parts[0]) + 1;
    return create(
      latestVersion: '$major.0.0',
      currentVersion: currentVersion,
      updateType: UpdateType.recommended,
      releaseNotes: 'Major version update with new features',
    );
  }

  static UpdateInfo minorUpdate({String currentVersion = '1.0.0'}) {
    final parts = currentVersion.split('.');
    final major = int.parse(parts[0]);
    final minor = int.parse(parts[1]) + 1;
    return create(
      latestVersion: '$major.$minor.0',
      currentVersion: currentVersion,
      updateType: UpdateType.optional,
      releaseNotes: 'Minor update with improvements',
    );
  }

  static UpdateInfo patchUpdate({String currentVersion = '1.0.0'}) {
    final parts = currentVersion.split('.');
    final major = int.parse(parts[0]);
    final minor = int.parse(parts[1]);
    final patch = int.parse(parts[2]) + 1;
    return create(
      latestVersion: '$major.$minor.$patch',
      currentVersion: currentVersion,
      updateType: UpdateType.optional,
      releaseNotes: 'Patch update with bug fixes',
    );
  }

  /// Create an update with a specific download size
  static UpdateInfo withSize({
    required int bytes,
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
  }) {
    return create(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      downloadSize: bytes,
    );
  }

  /// Create an update with empty download URL (simulates unavailable download)
  static UpdateInfo unavailable({
    String latestVersion = '2.0.0',
    String currentVersion = '1.0.0',
  }) {
    return create(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      downloadUrl: '',
      downloadSize: 0,
    );
  }
}

/// Factory class for creating mock DownloadProgress instances for testing.
///
/// Provides convenient factory methods for various download states.
class MockDownloadProgressFactory {
  /// Create a download progress with optional overrides
  static DownloadProgress create({
    double progress = 0.0,
    int downloadedBytes = 0,
    int totalBytes = 10 * 1024 * 1024, // 10 MB
    String? filePath,
    String status = '',
    double? speed,
    Duration? estimatedTimeRemaining,
  }) {
    return DownloadProgress(
      progress: progress,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      filePath: filePath,
      status: status,
      speed: speed,
      estimatedTimeRemaining: estimatedTimeRemaining,
    );
  }

  /// Create a progress representing download not started
  static DownloadProgress notStarted({int totalBytes = 10 * 1024 * 1024}) {
    return create(
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: totalBytes,
      status: 'Waiting to start',
    );
  }

  /// Create a progress representing download in progress
  static DownloadProgress inProgress({
    double progress = 0.5,
    int totalBytes = 10 * 1024 * 1024,
    double? speedBytesPerSecond,
  }) {
    final downloadedBytes = (totalBytes * progress).round();
    final speed = speedBytesPerSecond ?? 1024 * 1024; // default 1 MB/s
    final remainingBytes = totalBytes - downloadedBytes;
    final remainingSeconds = remainingBytes / speed;

    return create(
      progress: progress,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      status: 'Downloading...',
      speed: speed,
      estimatedTimeRemaining: Duration(seconds: remainingSeconds.round()),
    );
  }

  /// Create a progress representing completed download
  static DownloadProgress completed({
    int totalBytes = 10 * 1024 * 1024,
    String filePath = '/path/to/downloaded/app.apk',
  }) {
    return create(
      progress: 1.0,
      downloadedBytes: totalBytes,
      totalBytes: totalBytes,
      filePath: filePath,
      status: 'Download complete',
      speed: 0,
      estimatedTimeRemaining: Duration.zero,
    );
  }

  /// Create a progress representing download failure
  static DownloadProgress failed({
    double progressAtFailure = 0.3,
    int totalBytes = 10 * 1024 * 1024,
    String errorMessage = 'Download failed',
  }) {
    return create(
      progress: progressAtFailure,
      downloadedBytes: (totalBytes * progressAtFailure).round(),
      totalBytes: totalBytes,
      status: errorMessage,
      speed: 0,
    );
  }

  /// Create a progress representing paused download
  static DownloadProgress paused({
    double progress = 0.5,
    int totalBytes = 10 * 1024 * 1024,
  }) {
    return create(
      progress: progress,
      downloadedBytes: (totalBytes * progress).round(),
      totalBytes: totalBytes,
      status: 'Paused',
      speed: 0,
    );
  }

  /// Create a progress at specific percentage
  static DownloadProgress atPercentage(
    int percentage, {
    int totalBytes = 10 * 1024 * 1024,
  }) {
    final progress = percentage / 100.0;
    return inProgress(
      progress: progress,
      totalBytes: totalBytes,
    );
  }

  /// Create a sequence of progress updates for simulating download
  static List<DownloadProgress> downloadSequence({
    int steps = 10,
    int totalBytes = 10 * 1024 * 1024,
    double speedBytesPerSecond = 1024 * 1024,
    String filePath = '/path/to/app.apk',
  }) {
    final List<DownloadProgress> sequence = [];

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final downloadedBytes = (totalBytes * progress).round();
      final remainingBytes = totalBytes - downloadedBytes;
      final remainingSeconds =
          remainingBytes > 0 ? remainingBytes / speedBytesPerSecond : 0;

      sequence.add(create(
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        status: i == steps ? 'Download complete' : 'Downloading...',
        speed: i == steps ? 0 : speedBytesPerSecond,
        estimatedTimeRemaining: Duration(seconds: remainingSeconds.round()),
        filePath: i == steps ? filePath : null,
      ));
    }

    return sequence;
  }

  /// Create a progress with slow connection
  static DownloadProgress slowConnection({
    double progress = 0.2,
    int totalBytes = 10 * 1024 * 1024,
  }) {
    return inProgress(
      progress: progress,
      totalBytes: totalBytes,
      speedBytesPerSecond: 10 * 1024, // 10 KB/s
    );
  }

  /// Create a progress with fast connection
  static DownloadProgress fastConnection({
    double progress = 0.5,
    int totalBytes = 10 * 1024 * 1024,
  }) {
    return inProgress(
      progress: progress,
      totalBytes: totalBytes,
      speedBytesPerSecond: 10 * 1024 * 1024, // 10 MB/s
    );
  }
}
