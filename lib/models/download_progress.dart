/// Download progress information with enhanced tracking.
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
