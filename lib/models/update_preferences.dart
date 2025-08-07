import 'package:shared_preferences/shared_preferences.dart';

/// Update preferences model for managing user update settings
class UpdatePreferences {
  static const String _keyAutoCheck = 'update_auto_check';
  static const String _keyAutoDownload = 'update_auto_download';
  static const String _keyWifiOnly = 'update_wifi_only';
  static const String _keySkipVersions = 'update_skip_versions';
  static const String _keyUpdateFrequency = 'update_frequency';

  bool autoCheckEnabled;
  bool autoDownloadEnabled;
  bool wifiOnlyDownload;
  List<String> skippedVersions;
  UpdateFrequency updateFrequency;

  UpdatePreferences({
    this.autoCheckEnabled = true,
    this.autoDownloadEnabled = false,
    this.wifiOnlyDownload = true,
    this.skippedVersions = const [],
    this.updateFrequency = UpdateFrequency.daily,
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
  }) {
    return UpdatePreferences(
      autoCheckEnabled: autoCheckEnabled ?? this.autoCheckEnabled,
      autoDownloadEnabled: autoDownloadEnabled ?? this.autoDownloadEnabled,
      wifiOnlyDownload: wifiOnlyDownload ?? this.wifiOnlyDownload,
      skippedVersions: skippedVersions ?? this.skippedVersions,
      updateFrequency: updateFrequency ?? this.updateFrequency,
    );
  }

  @override
  String toString() {
    return 'UpdatePreferences(autoCheck: $autoCheckEnabled, '
           'autoDownload: $autoDownloadEnabled, '
           'wifiOnly: $wifiOnlyDownload, '
           'skipped: ${skippedVersions.length} versions, '
           'frequency: ${updateFrequency.name})';
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