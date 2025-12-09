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
