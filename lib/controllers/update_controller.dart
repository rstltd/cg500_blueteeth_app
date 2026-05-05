import 'dart:async';

import 'package:flutter/material.dart';

import '../core/interfaces/update_ui_delegate.dart';
import '../core/service_locator.dart' show getIt;
import '../l10n/app_strings.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../utils/logger.dart';
import '../widgets/update/update_dialog.dart';

/// App-wide update flow coordinator.
///
/// Replaces the previous split between `AppUpdateManager` (app-level
/// state: latest update info, periodic check, dialog context) and
/// `UpdateLogicManager` (per-dialog state: download progress, install
/// flow, skip-version flow). The split caused two listeners on the same
/// download stream, two dispose paths that both called
/// `NetworkService.dispose()`, and forced consumers to learn two
/// different surfaces to ask the same question.
///
/// One singleton, one set of subscriptions, one dispose path. State
/// changes notify listeners via [ChangeNotifier], so any widget that
/// renders update state can use a `ListenableBuilder` instead of
/// rolling per-instance callbacks.
class UpdateController with ChangeNotifier {
  /// Default constructor pulls dependencies from the service locator.
  /// Used in production; tests should prefer [withDependencies].
  UpdateController()
      : _updateService = getIt<UpdateService>(),
        _networkService = getIt<NetworkService>(),
        _notificationService = getIt<NotificationService>(),
        _uiDelegate = const UpdateUIDelegate();

  /// Named constructor for dependency injection.
  UpdateController.withDependencies({
    required UpdateService updateService,
    required NetworkService networkService,
    required NotificationService notificationService,
    UpdateUIDelegate? uiDelegate,
  })  : _updateService = updateService,
        _networkService = networkService,
        _notificationService = notificationService,
        _uiDelegate = uiDelegate ?? const UpdateUIDelegate();

  final UpdateService _updateService;
  final NetworkService _networkService;
  final NotificationService _notificationService;
  final UpdateUIDelegate _uiDelegate;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _periodicTimer;
  Timer? _initialCheckTimer;
  Timer? _wifiRecheckTimer;

  // ---- Lifecycle ----
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ---- Update check state ----
  bool _isCheckingForUpdates = false;
  bool get isCheckingForUpdates => _isCheckingForUpdates;
  UpdateInfo? _latestUpdateInfo;
  UpdateInfo? get latestUpdateInfo => _latestUpdateInfo;

  // ---- Download state (was UpdateLogicManager) ----
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;
  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;
  String _downloadStatus = '';
  String get downloadStatus => _downloadStatus;

  // ---- Network state (was UpdateLogicManager) ----
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  NetworkStatus get networkStatus => _networkStatus;

  // ---- Dialog context (was AppUpdateManager) ----
  BuildContext? _dialogContext;

  /// Set the BuildContext used for showing update dialogs. Typically
  /// called once from the top-level app shell after the first frame.
  void setDialogContext(BuildContext context) {
    _dialogContext = context;
  }

  /// Backwards-compatible alias matching `AppUpdateManager.setContext`.
  void setContext(BuildContext context) => setDialogContext(context);

  // ---- Service references (kept so legacy view models can read prefs /
  //      version info without restructuring in the same step) ----
  UpdateService get updateService => _updateService;
  NetworkService get networkService => _networkService;
  UpdateUIDelegate get uiDelegate => _uiDelegate;

  /// Initialize the controller and its underlying services.
  Future<bool> initialize() async {
    if (_isInitialized) {
      Logger.debug('UpdateController already initialized');
      return true;
    }
    try {
      Logger.info('Initializing UpdateController...');

      await _updateService.initialize();
      await _networkService.initialize();

      _networkStatus = _networkService.currentStatus;

      _subscriptions.add(
        _updateService.updateStream.listen(_onUpdateAvailable),
      );
      _subscriptions.add(
        _networkService.networkStream.listen(_onNetworkStatusChanged),
      );
      _subscriptions.add(
        _updateService.downloadStream.listen(_onDownloadProgress),
      );

      _isInitialized = true;
      notifyListeners();

      Logger.info('UpdateController initialized successfully');
      _scheduleInitialUpdateCheck();
      return true;
    } catch (e) {
      Logger.error('Failed to initialize UpdateController', error: e);
      return false;
    }
  }

  void _scheduleInitialUpdateCheck() {
    _initialCheckTimer?.cancel();
    _initialCheckTimer = Timer(const Duration(seconds: 3), () {
      checkForUpdatesWithUI();
    });
  }

  // ---- Stream handlers ----

  void _onUpdateAvailable(UpdateInfo info) {
    _latestUpdateInfo = info;
    Logger.info('Update event received: ${info.latestVersion}');
    notifyListeners();
    if (info.isForced && _dialogContext != null && _dialogContext!.mounted) {
      _showUpdateDialog(info);
    }
  }

  void _onNetworkStatusChanged(NetworkStatus status) {
    _networkStatus = status;
    Logger.debug('Network status changed: $status');
    notifyListeners();
    // Trigger a silent recheck on WiFi reconnect — was AppUpdateManager
    // behaviour. UpdateLogicManager only updated _networkStatus here, so
    // no behaviour is lost.
    if (status == NetworkStatus.wifi) {
      Logger.debug('WiFi connected, scheduling silent update check');
      _wifiRecheckTimer?.cancel();
      _wifiRecheckTimer = Timer(
        const Duration(seconds: 2),
        checkForUpdatesSilently,
      );
    }
  }

  void _onDownloadProgress(DownloadProgress progress) {
    _downloadProgress = progress.progress;
    _downloadStatus = progress.sizeText;
    notifyListeners();
  }

  // ---- Update check API ----

  /// Check for updates and show the update dialog if one is available.
  ///
  /// [force] bypasses the in-flight-check guard.
  /// [showUpToDateMessage] surfaces a toast when no update is available
  /// or the check fails — leave it false for periodic background checks.
  Future<UpdateInfo?> checkForUpdatesWithUI({
    bool force = false,
    bool showUpToDateMessage = false,
  }) async {
    if (_isCheckingForUpdates && !force) {
      Logger.debug('Update check already in progress');
      return _latestUpdateInfo;
    }

    _isCheckingForUpdates = true;
    notifyListeners();

    try {
      Logger.info('Checking for updates with UI...');

      final updateInfo =
          await _updateService.checkForUpdates(showNotification: false);

      if (updateInfo != null) {
        _latestUpdateInfo = updateInfo;
        Logger.info(
            'Update found: ${updateInfo.currentVersion} -> ${updateInfo.latestVersion}');

        if (_dialogContext != null && _dialogContext!.mounted) {
          _showUpdateDialog(updateInfo);
        } else {
          _notificationService.showInfo(
            title: 'Update Available',
            message: 'Version ${updateInfo.latestVersion} is available',
          );
        }
        return updateInfo;
      } else {
        Logger.info('No updates available');
        if (showUpToDateMessage) {
          _notificationService.showSuccess(
            title: AppStrings.upToDateTitle,
            message: AppStrings.upToDateMessage,
          );
        }
        return null;
      }
    } catch (e) {
      Logger.error('Failed to check for updates', error: e);
      if (showUpToDateMessage) {
        _notificationService.showError(
          title: AppStrings.updateCheckFailedTitle,
          message: AppStrings.updateCheckFailedMessage,
        );
      }
      return null;
    } finally {
      _isCheckingForUpdates = false;
      notifyListeners();
    }
  }

  /// Check for updates silently — no UI feedback, used by periodic and
  /// network-driven re-checks.
  Future<UpdateInfo?> checkForUpdatesSilently() async {
    try {
      Logger.debug('Checking for updates silently...');
      final updateInfo =
          await _updateService.checkForUpdates(showNotification: false);

      if (updateInfo != null) {
        _latestUpdateInfo = updateInfo;
        Logger.info(
            'Silent update check: Update available ${updateInfo.latestVersion}');
        notifyListeners();
      }
      return updateInfo;
    } catch (e) {
      Logger.error('Silent update check failed', error: e);
      return null;
    }
  }

  /// Open the update dialog if a known update info is cached. Used by the
  /// notification banner when the user taps it.
  void showUpdateDialogIfAvailable() {
    if (_latestUpdateInfo != null &&
        _dialogContext != null &&
        _dialogContext!.mounted) {
      _showUpdateDialog(_latestUpdateInfo!);
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    if (_dialogContext == null || !_dialogContext!.mounted) {
      Logger.warning('Cannot show update dialog: context not available');
      return;
    }

    showDialog<void>(
      context: _dialogContext!,
      barrierDismissible: !info.isForced,
      builder: (context) => UpdateDialog(
        updateInfo: info,
        onDismiss: () {
          Logger.debug('Update dialog dismissed');
        },
        onUpdateComplete: () {
          Logger.info('Update completed, clearing cached update info');
          _latestUpdateInfo = null;
          notifyListeners();
        },
      ),
    );
  }

  /// Start a periodic silent update check.
  void startPeriodicUpdateChecks(
      {Duration interval = const Duration(hours: 6)}) {
    _stopPeriodicUpdateChecks();
    Logger.info('Starting periodic update checks every ${interval.inHours}h');
    _periodicTimer = Timer.periodic(interval, (_) {
      Logger.debug('Periodic update check triggered');
      checkForUpdatesSilently();
    });
  }

  void _stopPeriodicUpdateChecks() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // ---- Update flow (was UpdateLogicManager) ----

  /// Download and then install the given update. Used by the dialog when
  /// the user taps "Update Now".
  Future<void> startUpdate(UpdateInfo info, BuildContext context) async {
    _isDownloading = true;
    notifyListeners();

    try {
      final apkPath = await _updateService.downloadUpdate(info);

      if (apkPath != null) {
        Logger.info('Download completed, starting installation: $apkPath');
        _isDownloading = false;
        notifyListeners();

        if (context.mounted) {
          await _installUpdate(apkPath, context);
        }
      } else {
        Logger.error('Download failed: no file path returned');
        _isDownloading = false;
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Error during update process', error: e);
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> _installUpdate(String apkPath, BuildContext context) async {
    if (!context.mounted) return;

    Logger.info('Installing APK directly: $apkPath');

    try {
      final success = await _updateService.installUpdate(apkPath);
      if (!context.mounted) return;
      if (success) {
        Logger.info(
            '✅ APK installation triggered successfully - Android system will take over');
        _uiDelegate.showInstallationStarted(context);
      } else {
        Logger.error('❌ Failed to trigger APK installation');
        _uiDelegate.showInstallationFailed(context);
      }
    } catch (e) {
      Logger.error('Error during APK installation', error: e);
      if (context.mounted) {
        _uiDelegate.showInstallationError(context, e.toString());
      }
    }

    _isDownloading = false;
    notifyListeners();
  }

  /// Mark a version as skipped after user confirmation.
  Future<void> skipVersion(
    UpdateInfo info,
    BuildContext context,
    VoidCallback? onComplete,
  ) async {
    final confirmed = await _uiDelegate.showSkipVersionConfirmation(
      context,
      info.latestVersion,
    );

    if (!confirmed || !context.mounted) return;

    // Close the confirmation dialog AND the parent update dialog.
    _uiDelegate.closeDialogs(context, count: 2);

    await _updateService.skipVersion(info.latestVersion);
    onComplete?.call();

    if (context.mounted) {
      _uiDelegate.showVersionSkipped(
        context,
        info.latestVersion,
        () {
          _updateService.preferences?.unskipVersion(info.latestVersion);
          _updateService.preferences?.save();
        },
      );
    }
  }

  /// Trigger a download for the cached latest update info. Used by
  /// callers that want to start a download outside the dialog flow.
  Future<String?> downloadUpdate() async {
    if (_latestUpdateInfo == null) {
      Logger.warning('No update info available for download');
      return null;
    }
    try {
      Logger.info('Starting update download...');
      return await _updateService.downloadUpdate(_latestUpdateInfo!);
    } catch (e) {
      Logger.error('Failed to download update', error: e);
      return null;
    }
  }

  // ---- Settings facade (was AppUpdateManager) ----

  Map<String, String> getCurrentVersionInfo() =>
      _updateService.getCurrentVersionInfo();

  bool get autoUpdatesEnabled =>
      _updateService.preferences?.autoCheckEnabled ?? true;

  bool get autoDownloadEnabled =>
      _updateService.preferences?.autoDownloadEnabled ?? false;

  Future<void> setAutoUpdatesEnabled(bool enabled) async {
    final prefs = _updateService.preferences;
    if (prefs != null) {
      prefs.autoCheckEnabled = enabled;
      await _updateService.updatePreferences(prefs);

      if (enabled) {
        startPeriodicUpdateChecks();
      } else {
        _stopPeriodicUpdateChecks();
      }
      Logger.info('Auto updates ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // ---- Dispose ----

  @override
  void dispose() {
    Logger.info('Disposing UpdateController...');
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _stopPeriodicUpdateChecks();
    _initialCheckTimer?.cancel();
    _initialCheckTimer = null;
    _wifiRecheckTimer?.cancel();
    _wifiRecheckTimer = null;
    // NOTE: do NOT dispose _updateService or _networkService — they are
    // service-locator singletons whose lifetime is owned by getIt, not
    // by us. The previous AppUpdateManager + UpdateService split called
    // _networkService.dispose() twice on shutdown.
    _dialogContext = null;
    _latestUpdateInfo = null;
    _isInitialized = false;
    super.dispose();
  }
}
