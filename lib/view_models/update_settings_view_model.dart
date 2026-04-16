import '../controllers/app_update_manager.dart';
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
    AppUpdateManager? updateManager,
  })  : _injectedUpdateService = updateService,
        _injectedNetworkService = networkService,
        _injectedRoleService = roleService,
        _injectedUpdateManager = updateManager;

  final UpdateService? _injectedUpdateService;
  final NetworkService? _injectedNetworkService;
  final RoleService? _injectedRoleService;
  final AppUpdateManager? _injectedUpdateManager;

  late final UpdateService _updateService;
  late final NetworkService _networkService;
  late final RoleService _roleService;
  late final AppUpdateManager _updateManager;

  UpdatePreferences? _preferences;
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  bool _isCheckingUpdate = false;
  DateTime? _lastCheckAt;

  // --- Getters ---

  /// The current update preferences.
  UpdatePreferences? get preferences => _preferences;

  /// Whether preferences have been loaded.
  bool get hasPreferences => _preferences != null;

  /// The current network status.
  NetworkStatus get networkStatus => _networkStatus;

  /// Whether an update check is in progress.
  bool get isCheckingUpdate => _isCheckingUpdate;

  /// When the user last ran a manual update check during this session.
  /// Null means no check has been run yet in the current session.
  DateTime? get lastCheckAt => _lastCheckAt;

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
    _updateManager = _injectedUpdateManager ?? getIt<AppUpdateManager>();

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
  //
  // Only the WiFi-only download toggle and the skip-list management are
  // user-controllable from the settings page. Auto-check, auto-download,
  // and check frequency stay at their developer-chosen defaults (always
  // on, manual download, daily poll) and are no longer exposed as UI.

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

  // --- Update Checking ---

  /// Manually trigger an update check. Routes through AppUpdateManager so
  /// the user gets the shared "up-to-date" / "check failed" toast feedback.
  Future<void> checkForUpdates() async {
    if (_isCheckingUpdate) return;

    _isCheckingUpdate = true;
    safeNotifyListeners();

    try {
      await _updateManager.checkForUpdatesWithUI(
        force: true,
        showUpToDateMessage: true,
      );
    } finally {
      _lastCheckAt = DateTime.now();
      _isCheckingUpdate = false;
      safeNotifyListeners();
    }
  }
}
