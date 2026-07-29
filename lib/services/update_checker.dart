import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_version.dart';
import '../utils/logger.dart';
import '../models/update_info.dart';
import '../models/update_preferences.dart';
import '../models/update_type.dart';

/// Service responsible for checking app updates via GitHub Releases API.
///
/// Channel semantics (see `docs/VERSIONING.md`):
/// - [UpdateChannel.stable]: queries `/releases/latest`, which GitHub already
///   filters to non-prerelease tags only.
/// - [UpdateChannel.beta]: queries `/releases` (all tags) and picks the highest
///   by [AppVersion] ordering. Stable releases still beat older betas, so
///   beta-channel users automatically downgrade to stable once one ships.
class UpdateChecker {
  /// Named constructor for dependency injection.
  UpdateChecker.withDependencies();

  // GitHub repository configuration
  static const String _githubOwner = 'rstltd';
  static const String _githubRepo = 'cg500_blueteeth_app';
  static const String _githubApiUrl = 'https://api.github.com';
  static const String _latestReleaseEndpoint =
      '$_githubApiUrl/repos/$_githubOwner/$_githubRepo/releases/latest';
  static const String _allReleasesEndpoint =
      '$_githubApiUrl/repos/$_githubOwner/$_githubRepo/releases';

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

  /// Check for available updates via GitHub Releases.
  ///
  /// Returns [UpdateInfo] when an update on the requested [channel] is
  /// available, otherwise null. [skippedVersions] filters out tags the user
  /// has chosen to skip.
  Future<UpdateInfo?> checkForUpdates({
    List<String> skippedVersions = const [],
    UpdateChannel channel = UpdateChannel.stable,
  }) async {
    if (!_isInitialized) {
      Logger.warning('UpdateChecker not initialized, initializing now...');
      await initialize();
    }

    try {
      Logger.info('Checking for updates via GitHub Releases (channel: ${channel.name})...');

      final headers = {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'CG500-BLE-App',
      };

      final Map<String, dynamic>? releaseData;
      if (channel == UpdateChannel.stable) {
        releaseData = await _fetchLatestStable(headers);
      } else {
        releaseData = await _fetchLatestForBeta(headers);
      }

      if (releaseData == null) return null;
      return _parseReleaseData(releaseData, skippedVersions);
    } catch (e) {
      Logger.error('Error checking for updates', error: e);
      rethrow;
    }
  }

  /// Stable channel: GitHub's `/releases/latest` already excludes pre-releases.
  Future<Map<String, dynamic>?> _fetchLatestStable(Map<String, String> headers) async {
    final response = await http
        .get(Uri.parse(_latestReleaseEndpoint), headers: headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      Logger.warning('No stable releases found or repository not accessible');
      return null;
    }
    Logger.error('GitHub API error: ${response.statusCode}');
    return null;
  }

  /// Beta channel: fetch the list of releases and pick the highest by version.
  /// Stable releases still beat older betas because [AppVersion.compareTo]
  /// orders `26.05` above `26.05-beta.N`.
  Future<Map<String, dynamic>?> _fetchLatestForBeta(Map<String, String> headers) async {
    final response = await http
        .get(Uri.parse('$_allReleasesEndpoint?per_page=20'), headers: headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      Logger.error('GitHub API error: ${response.statusCode}');
      return null;
    }
    final list = json.decode(response.body) as List<dynamic>;
    if (list.isEmpty) {
      Logger.warning('No releases found');
      return null;
    }

    Map<String, dynamic>? winner;
    AppVersion? winnerVersion;
    for (final raw in list) {
      final release = raw as Map<String, dynamic>;
      if (release['draft'] == true) continue;
      final tag = release['tag_name'] as String?;
      if (tag == null) continue;
      final v = AppVersion.tryParse(tag);
      if (v == null) continue;
      if (winnerVersion == null || v.compareTo(winnerVersion) > 0) {
        winner = release;
        winnerVersion = v;
      }
    }
    return winner;
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

  /// Determine if this is a forced update based on release notes.
  ///
  /// Only the official bracketed markers (`[forced]` / `[critical]`, see
  /// CLAUDE.md "Version Management") trigger a forced update. Loose phrase
  /// matching (e.g. "security fix") is deliberately not used here — normal
  /// English release-note prose can contain those words without the release
  /// actually being forced, which would lock users into an undismissable
  /// update dialog.
  bool _isForceUpdate(String releaseNotes) {
    final lowerNotes = releaseNotes.toLowerCase();
    return lowerNotes.contains('[forced]') || lowerNotes.contains('[critical]');
  }

  /// Classify the magnitude of the version delta. Recommended for changes that
  /// roll over a year/month boundary (CalVer) or a major/minor (legacy);
  /// optional for hotfixes and pre-release iterations.
  UpdateType _determineUpdateType(String currentVersion, String latestVersion) {
    final current = AppVersion.tryParse(currentVersion);
    final latest = AppVersion.tryParse(latestVersion);
    if (current == null || latest == null) return UpdateType.optional;

    final cur = current.mainParts;
    final lat = latest.mainParts;

    // Compare the first two segments — for CalVer this is year+month, for
    // legacy SemVer it is major+minor. A change in either is "recommended."
    final curYearOrMajor = cur.isNotEmpty ? cur[0] : 0;
    final latYearOrMajor = lat.isNotEmpty ? lat[0] : 0;
    final curMonthOrMinor = cur.length > 1 ? cur[1] : 0;
    final latMonthOrMinor = lat.length > 1 ? lat[1] : 0;

    if (latYearOrMajor != curYearOrMajor) return UpdateType.recommended;
    if (latMonthOrMinor != curMonthOrMinor) return UpdateType.recommended;
    return UpdateType.optional;
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

  /// Compare two version strings, supporting CalVer and legacy SemVer.
  /// See [AppVersion] for ordering rules.
  int compareVersions(String version1, String version2) {
    final v1 = AppVersion.tryParse(version1);
    final v2 = AppVersion.tryParse(version2);
    if (v1 == null || v2 == null) {
      Logger.warning('Failed to compare versions: $version1 vs $version2');
      return 0;
    }
    return v1.compareTo(v2);
  }
}
