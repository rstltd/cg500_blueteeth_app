import '../controllers/update_controller.dart';
import '../services/update_preferences_store.dart';
import '../services/network_service.dart';
import '../services/role_service.dart';
import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../models/role/user_role.dart';
import '../models/update_preferences.dart';

/// ViewModel for the Update Settings View.
///
/// Manages:
/// - Update preferences loading and saving (via the shared store)
/// - Network status monitoring
/// - Update checking state (delegated to UpdateController)
class UpdateSettingsViewModel extends BaseViewModel {
  /// Creates an UpdateSettingsViewModel.
  ///
  /// All dependencies are optional for testing. If null they are
  /// retrieved from the service locator.
  UpdateSettingsViewModel({
    UpdatePreferencesStore? preferencesStore,
    NetworkService? networkService,
    RoleService? roleService,
    UpdateController? updateManager,
  })  : _injectedPreferencesStore = preferencesStore,
        _injectedNetworkService = networkService,
        _injectedRoleService = roleService,
        _injectedUpdateManager = updateManager;

  final UpdatePreferencesStore? _injectedPreferencesStore;
  final NetworkService? _injectedNetworkService;
  final RoleService? _injectedRoleService;
  final UpdateController? _injectedUpdateManager;

  late final UpdatePreferencesStore _preferencesStore;
  late final NetworkService _networkService;
  late final RoleService _roleService;
  late final UpdateController _updateManager;

  NetworkStatus _networkStatus = NetworkStatus.unknown;
  bool _isCheckingUpdate = false;
  DateTime? _lastCheckAt;

  // --- Getters ---

  /// The current update preferences (read from the shared store).
  /// Null before [onInit] has wired up the store.
  UpdatePreferences? get preferences =>
      isInitialized ? _preferencesStore.current : null;

  /// Whether preferences have been loaded.
  bool get hasPreferences =>
      isInitialized && _preferencesStore.isLoaded;

  /// The current network status.
  NetworkStatus get networkStatus => _networkStatus;

  /// Whether an update check is in progress.
  bool get isCheckingUpdate => _isCheckingUpdate;

  /// When the user last ran a manual update check during this session.
  /// Null means no check has been run yet in the current session.
  DateTime? get lastCheckAt => _lastCheckAt;

  /// The network service instance.
  NetworkService get networkService => _networkService;

  /// Get current version info from the update controller.
  Map<String, String> get currentVersionInfo =>
      _updateManager.getCurrentVersionInfo();

  /// Network status description.
  String get networkStatusDescription => _networkService.getStatusDescription();

  @override
  Future<void> onInit() async {
    _preferencesStore =
        _injectedPreferencesStore ?? getIt<UpdatePreferencesStore>();
    _networkService =
        _injectedNetworkService ?? getIt<NetworkService>();
    _roleService = _injectedRoleService ?? getIt<RoleService>();
    _updateManager = _injectedUpdateManager ?? getIt<UpdateController>();

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

    // Subscribe to preferences changes so the settings UI reflects edits
    // made anywhere else (e.g. the dialog's skip-version flow updating
    // skippedVersions while the settings screen is open).
    subscribe<UpdatePreferences>(
      _preferencesStore.changeStream,
      (_) => safeNotifyListeners(),
    );

    // Set initial network status
    _networkStatus = _networkService.currentStatus;

    // Load preferences via the store. No-op if already loaded.
    if (!_preferencesStore.isLoaded) {
      await _preferencesStore.load();
    }
    safeNotifyListeners();
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

  // --- Preference Update Methods ---
  //
  // Only the WiFi-only download toggle and the skip-list management are
  // user-controllable from the settings page. Auto-check, auto-download,
  // and check frequency stay at their developer-chosen defaults (always
  // on, manual download, daily poll) and are no longer exposed as UI.

  /// Update WiFi only download setting.
  Future<void> setWifiOnlyDownload(bool value) =>
      _preferencesStore.setWifiOnlyDownload(value);

  /// Switch the user between the stable and beta update channels.
  /// See `docs/VERSIONING.md` for the channel policy.
  Future<void> setUpdateChannel(UpdateChannel channel) =>
      _preferencesStore.setUpdateChannel(channel);

  /// Unskip a version.
  Future<void> unskipVersion(String version) =>
      _preferencesStore.unskipVersion(version);

  /// Clear all skipped versions.
  Future<void> clearSkippedVersions() =>
      _preferencesStore.clearSkippedVersions();

  // --- Update Checking ---

  /// Manually trigger an update check. Routes through UpdateController so
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
