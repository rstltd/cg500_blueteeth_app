import 'dart:async';
import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/network_service.dart';
import '../core/interfaces/update_ui_delegate.dart';
import '../core/service_locator.dart' show getIt;
import '../utils/logger.dart';

/// Manager for handling update logic including download, install, and skip operations
class UpdateLogicManager {
  late final UpdateService _updateService;
  late final NetworkService _networkService;
  late final UpdateUIDelegate _uiDelegate;

  // StreamSubscription management
  final List<StreamSubscription> _subscriptions = [];

  // State management
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  NetworkStatus _networkStatus = NetworkStatus.unknown;

  // Getters
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get downloadStatus => _downloadStatus;
  NetworkStatus get networkStatus => _networkStatus;
  UpdateService get updateService => _updateService;
  NetworkService get networkService => _networkService;
  UpdateUIDelegate get uiDelegate => _uiDelegate;

  // Callbacks
  Function(bool)? onDownloadStateChanged;
  Function(double, String)? onProgressUpdated;
  Function(NetworkStatus)? onNetworkStatusChanged;

  UpdateLogicManager({
    this.onDownloadStateChanged,
    this.onProgressUpdated,
    this.onNetworkStatusChanged,
    UpdateUIDelegate? uiDelegate,
  }) {
    _updateService = getIt<UpdateService>();
    _networkService = getIt<NetworkService>();
    _uiDelegate = uiDelegate ?? const UpdateUIDelegate();
  }

  /// Constructor for dependency injection (used in testing)
  UpdateLogicManager.withDependencies({
    required UpdateService updateService,
    required NetworkService networkService,
    UpdateUIDelegate? uiDelegate,
    this.onDownloadStateChanged,
    this.onProgressUpdated,
    this.onNetworkStatusChanged,
  }) {
    _updateService = updateService;
    _networkService = networkService;
    _uiDelegate = uiDelegate ?? const UpdateUIDelegate();
  }

  /// Initialize the manager with listeners
  void initialize() {
    // Get initial network status
    _networkStatus = _networkService.currentStatus;
    onNetworkStatusChanged?.call(_networkStatus);

    // Listen to network changes
    _subscriptions.add(
      _networkService.networkStream.listen((status) {
        _networkStatus = status;
        onNetworkStatusChanged?.call(status);
      }),
    );

    // Listen to download progress
    _subscriptions.add(
      _updateService.downloadStream.listen((progress) {
        _downloadProgress = progress.progress;
        _downloadStatus = progress.sizeText;
        onProgressUpdated?.call(_downloadProgress, _downloadStatus);
      }),
    );
  }

  /// Start update download
  Future<void> startUpdate(UpdateInfo updateInfo, BuildContext context) async {
    _isDownloading = true;
    onDownloadStateChanged?.call(true);

    try {
      final apkFilePath = await _updateService.downloadUpdate(updateInfo);
      
      if (apkFilePath != null) {
        // Download completed successfully, now install
        Logger.info('Download completed, starting installation: $apkFilePath');
        
        // Reset downloading state
        _isDownloading = false;
        onDownloadStateChanged?.call(false);
        
        // Start installation process
        if (context.mounted) {
          await _installUpdate(apkFilePath, context);
        }
      } else {
        // Download failed
        Logger.error('Download failed: no file path returned');
        _isDownloading = false;
        onDownloadStateChanged?.call(false);
      }
    } catch (e) {
      Logger.error('Error during update process', error: e);
      _isDownloading = false;
      onDownloadStateChanged?.call(false);
    }
  }

  /// Install update directly without guide dialog
  Future<void> _installUpdate(String apkPath, BuildContext context) async {
    if (!context.mounted) return;

    Logger.info('Installing APK directly: $apkPath');

    try {
      // Trigger APK installation directly - Android system will handle UI
      final success = await _updateService.installUpdate(apkPath);

      if (!context.mounted) return;

      if (success) {
        Logger.info('✅ APK installation triggered successfully - Android system will take over');
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

    // Reset download state after installation attempt
    _isDownloading = false;
    onDownloadStateChanged?.call(false);
  }

  /// Skip version with confirmation dialog
  Future<void> skipVersion(
    UpdateInfo updateInfo,
    BuildContext context,
    VoidCallback? onComplete,
  ) async {
    final confirmed = await _uiDelegate.showSkipVersionConfirmation(
      context,
      updateInfo.latestVersion,
    );

    if (!confirmed || !context.mounted) return;

    // Close dialogs (confirmation + update dialog)
    _uiDelegate.closeDialogs(context, count: 2);

    await _updateService.skipVersion(updateInfo.latestVersion);
    onComplete?.call();

    if (context.mounted) {
      _uiDelegate.showVersionSkipped(
        context,
        updateInfo.latestVersion,
        () {
          _updateService.preferences?.unskipVersion(updateInfo.latestVersion);
          _updateService.preferences?.save();
        },
      );
    }
  }

  /// Clean up resources
  void dispose() {
    // Cancel all stream subscriptions to prevent memory leaks
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}