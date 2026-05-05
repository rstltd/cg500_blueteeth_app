import 'package:shared_preferences/shared_preferences.dart';

/// Update preferences model for managing user update settings
class UpdatePreferences {
  static const String _keyAutoCheck = 'update_auto_check';
  static const String _keyAutoDownload = 'update_auto_download';
  static const String _keyWifiOnly = 'update_wifi_only';
  static const String _keySkipVersions = 'update_skip_versions';
  static const String _keyUpdateFrequency = 'update_frequency';
  static const String _keyUpdateChannel = 'update_channel';

  bool autoCheckEnabled;
  bool autoDownloadEnabled;
  bool wifiOnlyDownload;
  List<String> skippedVersions;
  UpdateFrequency updateFrequency;
  UpdateChannel updateChannel;

  UpdatePreferences({
    this.autoCheckEnabled = true,
    this.autoDownloadEnabled = false,
    this.wifiOnlyDownload = true,
    this.skippedVersions = const [],
    this.updateFrequency = UpdateFrequency.daily,
    this.updateChannel = UpdateChannel.stable,
  });

  /// Load preferences from SharedPreferences
  static Future<UpdatePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();

    return UpdatePreferences(
      autoCheckEnabled: prefs.getBool(_keyAutoCheck) ?? true,
      autoDownloadEnabled: prefs.getBool(_keyAutoDownload) ?? false,
      wifiOnlyDownload: prefs.getBool(_keyWifiOnly) ?? true,
      skippedVersions: prefs.getStringList(_keySkipVersions) ?? [],
      updateFrequency: UpdateFrequency.values.firstWhere(
        (freq) => freq.name == prefs.getString(_keyUpdateFrequency),
        orElse: () => UpdateFrequency.daily,
      ),
      updateChannel: UpdateChannel.values.firstWhere(
        (ch) => ch.name == prefs.getString(_keyUpdateChannel),
        orElse: () => UpdateChannel.stable,
      ),
    );
  }

  /// Save preferences to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyAutoCheck, autoCheckEnabled);
    await prefs.setBool(_keyAutoDownload, autoDownloadEnabled);
    await prefs.setBool(_keyWifiOnly, wifiOnlyDownload);
    await prefs.setStringList(_keySkipVersions, skippedVersions);
    await prefs.setString(_keyUpdateFrequency, updateFrequency.name);
    await prefs.setString(_keyUpdateChannel, updateChannel.name);
  }

  /// Add a version to skip list
  void skipVersion(String version) {
    if (!skippedVersions.contains(version)) {
      skippedVersions = [...skippedVersions, version];
    }
  }

  /// Remove a version from skip list
  void unskipVersion(String version) {
    skippedVersions = skippedVersions.where((v) => v != version).toList();
  }

  /// Check if a version should be skipped
  bool shouldSkipVersion(String version) {
    return skippedVersions.contains(version);
  }

  /// Clear all skipped versions
  void clearSkippedVersions() {
    skippedVersions = [];
  }

  /// Copy with new values
  UpdatePreferences copyWith({
    bool? autoCheckEnabled,
    bool? autoDownloadEnabled,
    bool? wifiOnlyDownload,
    List<String>? skippedVersions,
    UpdateFrequency? updateFrequency,
    UpdateChannel? updateChannel,
  }) {
    return UpdatePreferences(
      autoCheckEnabled: autoCheckEnabled ?? this.autoCheckEnabled,
      autoDownloadEnabled: autoDownloadEnabled ?? this.autoDownloadEnabled,
      wifiOnlyDownload: wifiOnlyDownload ?? this.wifiOnlyDownload,
      skippedVersions: skippedVersions ?? this.skippedVersions,
      updateFrequency: updateFrequency ?? this.updateFrequency,
      updateChannel: updateChannel ?? this.updateChannel,
    );
  }

  @override
  String toString() {
    return 'UpdatePreferences(autoCheck: $autoCheckEnabled, '
           'autoDownload: $autoDownloadEnabled, '
           'wifiOnly: $wifiOnlyDownload, '
           'skipped: ${skippedVersions.length} versions, '
           'frequency: ${updateFrequency.name}, '
           'channel: ${updateChannel.name})';
  }
}

/// Update frequency options
enum UpdateFrequency {
  never('Never'),
  daily('Daily'),
  weekly('Weekly'),
  manual('Manual only');

  const UpdateFrequency(this.displayName);
  final String displayName;
}

/// Release channel the user is subscribed to.
///
/// - [stable]: only fetch GitHub releases that are NOT marked as pre-release
///   (i.e. tag matches `vYY.0M[.MICRO]`).
/// - [beta]: fetch all releases, including those tagged `-beta.N` / `-rc.N`.
///   Beta-channel users see beta builds AND stable builds — whichever is newer
///   by [AppVersion] ordering wins.
///
/// See `docs/VERSIONING.md` for the channel policy.
enum UpdateChannel {
  stable,
  beta;

  /// Whether GitHub releases marked `prerelease=true` are eligible for this
  /// channel. Stable channel rejects them; beta channel accepts them.
  bool get acceptsPrereleases => this == UpdateChannel.beta;
}