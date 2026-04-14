import '../services/update_service.dart';
import '../services/network_service.dart';
import '../services/role_service.dart';
import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../models/role/user_role.dart';
import '../models/update_preferences.dart';

/// ViewModel for the Update Settings View.
///
/// Manages:
/// - Update preferences loading and saving
/// - Network status monitoring
/// - Update checking state
///
/// Example usage:
/// ```dart
/// ViewModelProvider<UpdateSettingsViewModel>(
///   create: () => UpdateSettingsViewModel(),
///   builder: (context, viewModel, child) {
///     return UpdateSettingsContent(viewModel: viewModel);
///   },
/// )
/// ```
class UpdateSettingsViewModel extends BaseViewModel {
  /// Creates an UpdateSettingsViewModel.
  ///
  /// [updateService] - Optional update service for dependency injection (testing).
  /// [networkService] - Optional network service for dependency injection (testing).
  /// If null, services are retrieved from the service locator.
  UpdateSettingsViewModel({
    UpdateService? updateService,
    NetworkService? networkService,
    RoleService? roleService,
  })  : _injectedUpdateService = updateService,
        _injectedNetworkService = networkService,
        _injectedRoleService = roleService;

  final UpdateService? _injectedUpdateService;
  final NetworkService? _injectedNetworkService;
  final RoleService? _injectedRoleService;

  late final UpdateService _updateService;
  late final NetworkService _networkService;
  late final RoleService _roleService;

  UpdatePreferences? _preferences;
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  bool _isCheckingUpdate = false;

  // --- Getters ---

  /// The current update preferences.
  UpdatePreferences? get preferences => _preferences;

  /// Whether preferences have been loaded.
  bool get hasPreferences => _preferences != null;

  /// The current network status.
  NetworkStatus get networkStatus => _networkStatus;

  /// Whether an update check is in progress.
  bool get isCheckingUpdate => _isCheckingUpdate;

  /// The update service instance.
  UpdateService get updateService => _updateService;

  /// The network service instance.
  NetworkService get networkService => _networkService;

  /// Get current version info from the update service.
  Map<String, String> get currentVersionInfo =>
      _updateService.getCurrentVersionInfo();

  /// Network status description.
  String get networkStatusDescription => _networkService.getStatusDescription();

  @override
  Future<void> onInit() async {
    // Use injected services or get from service locator
    _updateService = _injectedUpdateService ?? getIt<UpdateService>();
    _networkService =
        _injectedNetworkService ?? getIt<NetworkService>();
    _roleService = _injectedRoleService ?? getIt<RoleService>();

    // Subscribe to network status changes
    subscribe<NetworkStatus>(
      _networkService.networkStream,
      _onNetworkStatusChanged,
    );

    // Subscribe to role changes so the developer-mode switch reflects
    // the current state immediately after unlock or disable.
    subscribe<UserRole>(
      _roleService.roleStream,
      (_) => safeNotifyListeners(),
    );

    // Set initial network status
    _networkStatus = _networkService.currentStatus;

    // Load preferences
    await _loadPreferences();
  }

  // --- Developer Mode ---

  /// Whether the app is currently in developer mode.
  bool get isDeveloperMode => _roleService.currentRole.isDeveloper;

  /// Leave developer mode. No password required.
  void disableDeveloperMode() {
    _roleService.disableDeveloperMode();
  }

  void _onNetworkStatusChanged(NetworkStatus status) {
    _networkStatus = status;
    safeNotifyListeners();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await UpdatePreferences.load();
      _preferences = preferences;
      safeNotifyListeners();
    } catch (e) {
      _preferences = UpdatePreferences();
      safeNotifyListeners();
    }
  }

  /// Save the current preferences.
  Future<void> savePreferences() async {
    if (_preferences != null) {
      await _preferences!.save();
      // Update the UpdateService with new preferences
      await _updateService.updatePreferences(_preferences!);
    }
  }

  // --- Preference Update Methods ---

  /// Update auto check enabled setting.
  void setAutoCheckEnabled(bool value) {
    if (_preferences == null) return;
    _preferences = _preferences!.copyWith(autoCheckEnabled: value);
    safeNotifyListeners();
    savePreferences();
  }

  /// Update update frequency setting.
  void setUpdateFrequency(UpdateFrequency value) {
    if (_preferences == null) return;
    _preferences = _preferences!.copyWith(updateFrequency: value);
    safeNotifyListeners();
    savePreferences();
  }

  /// Update auto download enabled setting.
  void setAutoDownloadEnabled(bool value) {
    if (_preferences == null) return;
    _preferences = _preferences!.copyWith(autoDownloadEnabled: value);
    safeNotifyListeners();
    savePreferences();
  }

  /// Update WiFi only download setting.
  void setWifiOnlyDownload(bool value) {
    if (_preferences == null) return;
    _preferences = _preferences!.copyWith(wifiOnlyDownload: value);
    safeNotifyListeners();
    savePreferences();
  }

  /// Unskip a version.
  void unskipVersion(String version) {
    if (_preferences == null) return;
    _preferences!.unskipVersion(version);
    safeNotifyListeners();
    savePreferences();
  }

  /// Clear all skipped versions.
  void clearSkippedVersions() {
    if (_preferences == null) return;
    _preferences!.clearSkippedVersions();
    safeNotifyListeners();
    savePreferences();
  }

  /// Reset preferences to defaults.
  void resetToDefaults() {
    _preferences = UpdatePreferences();
    safeNotifyListeners();
    savePreferences();
  }

  // --- Update Checking ---

  /// Check for updates.
  Future<void> checkForUpdates() async {
    if (_isCheckingUpdate) return;

    _isCheckingUpdate = true;
    safeNotifyListeners();

    try {
      await _updateService.checkForUpdates(showNotification: true);
    } finally {
      _isCheckingUpdate = false;
      safeNotifyListeners();
    }
  }
}
