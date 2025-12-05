import 'dart:async';
import '../../services/update_service.dart';
import '../../models/update_preferences.dart';

/// Interface for application update services.
///
/// Implementations of this interface provide update checking,
/// downloading, and installation capabilities.
abstract class UpdateServiceInterface {
  // ============================================
  // Streams for reactive UI updates
  // ============================================

  /// Stream of update information when updates are available.
  Stream<UpdateInfo> get updateStream;

  /// Stream of download progress during update downloads.
  Stream<DownloadProgress> get downloadStream;

  // ============================================
  // Lifecycle operations
  // ============================================

  /// Initialize the update service.
  ///
  /// Loads current version info and user preferences.
  /// Returns `true` if initialization was successful.
  Future<bool> initialize();

  /// Release all resources held by this service.
  void dispose();

  // ============================================
  // Update checking
  // ============================================

  /// Check for available updates.
  ///
  /// When [showNotification] is true, shows user notifications about
  /// the update status (available, up-to-date, or error).
  ///
  /// Returns [UpdateInfo] if an update is available, null otherwise.
  Future<UpdateInfo?> checkForUpdates({bool showNotification = true});

  // ============================================
  // Download operations
  // ============================================

  /// Download an update APK.
  ///
  /// Progress is reported via [downloadStream].
  /// Returns the file path of the downloaded APK, or null if download failed.
  Future<String?> downloadUpdate(UpdateInfo updateInfo);

  /// Clean up old downloaded update files.
  ///
  /// If [keepVersion] is specified, keeps the APK for that version.
  Future<void> cleanupDownloads({String? keepVersion});

  // ============================================
  // Installation operations
  // ============================================

  /// Install a downloaded APK update.
  ///
  /// Only supported on Android. Returns `true` if installation started.
  Future<bool> installUpdate(String apkPath);

  /// Check if the device can install APK files.
  ///
  /// Returns `true` if the app has permission to install APKs.
  Future<bool> canInstallApks();

  /// Request permission to install APK files.
  Future<void> requestInstallPermission();

  /// Diagnose APK installation permissions and configuration.
  ///
  /// Returns a map with diagnostic information.
  Future<Map<String, dynamic>> diagnosePermissions();

  // ============================================
  // Version and preferences
  // ============================================

  /// Get current app version information.
  ///
  /// Returns a map with 'version' and 'buildNumber' keys.
  Map<String, String> getCurrentVersionInfo();

  /// Skip a specific version so it won't prompt for update.
  Future<void> skipVersion(String version);

  /// Get current update preferences.
  UpdatePreferences? get preferences;

  /// Update and save preferences.
  Future<void> updatePreferences(UpdatePreferences newPreferences);

  /// Check if auto-download should proceed based on preferences and network.
  bool shouldAutoDownload(UpdateInfo updateInfo);
}
