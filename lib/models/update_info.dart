import '../utils/app_version.dart';
import '../utils/logger.dart';
import 'update_type.dart';

/// Update information model containing details about an available app update.
class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final int downloadSize;
  final String releaseNotes;
  final bool isForced;
  final UpdateType updateType;
  final DateTime releaseDate;
  /// SHA256 checksum for APK verification (optional, for backward compatibility)
  final String? sha256Checksum;

  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.downloadSize,
    required this.releaseNotes,
    this.isForced = false,
    this.updateType = UpdateType.optional,
    required this.releaseDate,
    this.sha256Checksum,
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
      sha256Checksum: json['sha256_checksum'],
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
      if (sha256Checksum != null) 'sha256_checksum': sha256Checksum,
    };
  }

  /// Check if this update has a checksum for verification
  bool get hasChecksum => sha256Checksum != null && sha256Checksum!.isNotEmpty;

  /// Compares version strings, supporting CalVer (`vYY.0M[.MICRO][-beta.N]`)
  /// and legacy SemVer (`MAJOR.MINOR.PATCH`). See [AppVersion] for full rules.
  static int _compareVersions(String version1, String version2) {
    final v1 = AppVersion.tryParse(version1);
    final v2 = AppVersion.tryParse(version2);
    if (v1 == null || v2 == null) {
      Logger.warning('Cannot compare versions: "$version1" vs "$version2"');
      return 0;
    }
    return v1.compareTo(v2);
  }
}
