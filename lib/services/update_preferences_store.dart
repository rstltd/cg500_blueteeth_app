import 'dart:async';

import '../models/update_preferences.dart';

/// Single-source-of-truth holder for [UpdatePreferences].
///
/// Owns the in-memory copy of the user's update settings and persists every
/// mutation to disk. All consumers — `UpdateService`, the settings screen,
/// the network info widget — read from this store instead of holding their
/// own field, so the disk and the UI cannot diverge.
///
/// Lifecycle: register as a singleton in the service locator. Call [load]
/// once during app initialization (typically from `UpdateService.initialize`)
/// before reading [current].
class UpdatePreferencesStore {
  UpdatePreferences? _current;

  final StreamController<UpdatePreferences> _changeController =
      StreamController<UpdatePreferences>.broadcast();

  /// The most recently loaded preferences, or null if [load] has not yet
  /// been called or completed. Mirrors the legacy `UpdateService.preferences`
  /// nullability contract so callers can keep their existing null checks.
  UpdatePreferences? get current => _current;

  /// Whether [load] has populated [current].
  bool get isLoaded => _current != null;

  /// Emits the new preferences value after every successful mutation.
  Stream<UpdatePreferences> get changeStream => _changeController.stream;

  /// Read preferences from `SharedPreferences`. Idempotent — a second call
  /// reloads from disk, which is useful in tests and after a manual reset.
  Future<void> load() async {
    _current = await UpdatePreferences.load();
    _emit();
  }

  /// Replace the entire preferences object (e.g. when a settings screen
  /// edits multiple fields and saves them in one go).
  Future<void> replace(UpdatePreferences prefs) async {
    _current = prefs;
    await prefs.save();
    _emit();
  }

  Future<void> setWifiOnlyDownload(bool value) =>
      _mutate((p) => p.wifiOnlyDownload = value);

  Future<void> setAutoCheckEnabled(bool value) =>
      _mutate((p) => p.autoCheckEnabled = value);

  Future<void> setAutoDownloadEnabled(bool value) =>
      _mutate((p) => p.autoDownloadEnabled = value);

  Future<void> skipVersion(String version) =>
      _mutate((p) => p.skipVersion(version));

  Future<void> unskipVersion(String version) =>
      _mutate((p) => p.unskipVersion(version));

  Future<void> clearSkippedVersions() =>
      _mutate((p) => p.clearSkippedVersions());

  /// Releases the change-stream controller. Only call at app shutdown — the
  /// store is shared across the app so disposing it from one consumer kills
  /// every other consumer's subscription.
  void dispose() {
    _changeController.close();
  }

  Future<void> _mutate(void Function(UpdatePreferences) mutator) async {
    final prefs = _current;
    if (prefs == null) return;
    mutator(prefs);
    await prefs.save();
    _emit();
  }

  void _emit() {
    final c = _current;
    if (c != null && !_changeController.isClosed) {
      _changeController.add(c);
    }
  }
}
