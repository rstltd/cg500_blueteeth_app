import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/logger.dart';
import '../models/update_info.dart';
import '../models/update_type.dart';

/// Service responsible for checking app updates via GitHub Releases API.
///
/// This service handles:
/// - Fetching latest release information from GitHub
/// - Comparing versions to determine if update is available
/// - Determining update type (optional, recommended, forced)
/// - Extracting metadata from release notes (checksums, force flags)
///
/// Use [UpdateChecker.withDependencies()] constructor for dependency injection.
class UpdateChecker {
  /// Named constructor for dependency injection.
  UpdateChecker.withDependencies();

  // GitHub repository configuration
  static const String _githubOwner = 'rstltd';
  static const String _githubRepo = 'cg500_blueteeth_app';
  static const String _githubApiUrl = 'https://api.github.com';
  static const String _releasesEndpoint =
      '$_githubApiUrl/repos/$_githubOwner/$_githubRepo/releases/latest';

  // Local version info
  String? _currentVersion;
  String? _currentBuildNumber;
  bool _isInitialized = false;

  /// Check if the checker has been initialized
  bool get isInitialized => _isInitialized;

  /// Get current version string
  String? get currentVersion => _currentVersion;

  /// Get current build number
  String? get currentBuildNumber => _currentBuildNumber;

  /// Initialize the update checker by loading package info
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      _currentBuildNumber = packageInfo.buildNumber;
      _isInitialized = true;

      Logger.info(
          'UpdateChecker initialized - Version: $_currentVersion ($_currentBuildNumber)');
      return true;
    } catch (e) {
      Logger.error('Failed to initialize UpdateChecker', error: e);
      return false;
    }
  }

  /// Check for available updates via GitHub Releases
  ///
  /// Returns [UpdateInfo] if an update is available, null otherwise.
  /// The [skippedVersions] parameter allows filtering out versions the user has chosen to skip.
  Future<UpdateInfo?> checkForUpdates({
    List<String> skippedVersions = const [],
  }) async {
    if (!_isInitialized) {
      Logger.warning('UpdateChecker not initialized, initializing now...');
      await initialize();
    }

    try {
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
        return _parseReleaseData(data, skippedVersions);
      } else if (response.statusCode == 404) {
        Logger.warning('No releases found or repository not accessible');
        return null;
      } else {
        Logger.error('GitHub API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Logger.error('Error checking for updates', error: e);
      rethrow;
    }
  }

  /// Parse GitHub release data into UpdateInfo
  UpdateInfo? _parseReleaseData(
    Map<String, dynamic> data,
    List<String> skippedVersions,
  ) {
    // Parse GitHub release data
    final latestVersion = _cleanVersionTag(data['tag_name'] ?? '1.0.0');

    // Build complete current version string with build number if available
    final currentVersionBase = _currentVersion ?? '1.0.0';
    final buildNumber = _currentBuildNumber ?? '';
    final currentVersion =
        buildNumber.isNotEmpty ? '$currentVersionBase+$buildNumber' : currentVersionBase;

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

    // Extract SHA256 checksum from release notes (optional)
    final releaseNotes = data['body'] ?? 'No release notes available';
    final sha256Checksum = _extractChecksumFromReleaseNotes(releaseNotes);
    if (sha256Checksum != null) {
      Logger.info('SHA256 checksum found in release notes');
    }

    final updateInfo = UpdateInfo(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      downloadUrl: apkAsset['browser_download_url'] ?? '',
      downloadSize: apkAsset['size'] ?? 0,
      releaseNotes: releaseNotes,
      isForced: _isForceUpdate(releaseNotes),
      updateType: _determineUpdateType(currentVersion, latestVersion),
      releaseDate:
          DateTime.tryParse(data['published_at'] ?? '') ?? DateTime.now(),
      sha256Checksum: sha256Checksum,
    );

    // Log version comparison for debugging
    Logger.debug(
        'Version comparison: current=$currentVersion, latest=$latestVersion');
    Logger.debug('Has update check: ${updateInfo.hasUpdate}');

    if (updateInfo.hasUpdate) {
      // Check if this version should be skipped
      if (skippedVersions.contains(latestVersion)) {
        Logger.info('Version $latestVersion is skipped by user preference');
        return null;
      }

      Logger.info('Update available: $currentVersion -> $latestVersion');
      return updateInfo;
    } else {
      Logger.info('App is up to date ($currentVersion)');
      return null;
    }
  }

  /// Get current app version info
  Map<String, String> getCurrentVersionInfo() {
    return {
      'version': _currentVersion ?? 'Unknown',
      'buildNumber': _currentBuildNumber ?? 'Unknown',
    };
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

  /// Extract SHA256 checksum from release notes
  ///
  /// Looks for pattern "SHA256: <64-character-hex-string>" in the release notes.
  /// Returns null if not found.
  String? _extractChecksumFromReleaseNotes(String releaseNotes) {
    final regex = RegExp(r'SHA256:\s*([a-fA-F0-9]{64})', caseSensitive: false);
    final match = regex.firstMatch(releaseNotes);
    return match?.group(1)?.toLowerCase();
  }

  /// Compare two version strings
  ///
  /// Returns:
  /// - Negative if version1 < version2
  /// - Zero if version1 == version2
  /// - Positive if version1 > version2
  int compareVersions(String version1, String version2) {
    try {
      final v1Clean = version1.split('+')[0];
      final v2Clean = version2.split('+')[0];

      final v1Parts = v1Clean.split('.').map(int.parse).toList();
      final v2Parts = v2Clean.split('.').map(int.parse).toList();

      // Pad shorter version with zeros
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

      return 0;
    } catch (e) {
      Logger.warning('Failed to compare versions: $version1 vs $version2');
      return 0;
    }
  }
}
