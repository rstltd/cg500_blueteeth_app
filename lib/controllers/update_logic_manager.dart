import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/network_service.dart';
// Removed InstallGuideDialog import - now using direct installation
import '../utils/logger.dart';

/// Manager for handling update logic including download, install, and skip operations
class UpdateLogicManager {
  final UpdateService _updateService = UpdateService();
  final NetworkService _networkService = NetworkService();
  
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

  // Callbacks
  Function(bool)? onDownloadStateChanged;
  Function(double, String)? onProgressUpdated;
  Function(NetworkStatus)? onNetworkStatusChanged;

  UpdateLogicManager({
    this.onDownloadStateChanged,
    this.onProgressUpdated,
    this.onNetworkStatusChanged,
  });

  /// Initialize the manager with listeners
  void initialize() {
    // Get initial network status
    _networkStatus = _networkService.currentStatus;
    onNetworkStatusChanged?.call(_networkStatus);
    
    // Listen to network changes
    _networkService.networkStream.listen((status) {
      _networkStatus = status;
      onNetworkStatusChanged?.call(status);
    });
    
    // Listen to download progress
    _updateService.downloadStream.listen((progress) {
      _downloadProgress = progress.progress;
      _downloadStatus = progress.sizeText;
      onProgressUpdated?.call(_downloadProgress, _downloadStatus);
    });
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

    // Save context reference before async operation
    ScaffoldMessengerState? scaffoldMessenger;
    if (context.mounted) {
      scaffoldMessenger = ScaffoldMessenger.of(context);
    }

    try {
      // Trigger APK installation directly - Android system will handle UI
      final success = await _updateService.installUpdate(apkPath);
      
      if (success) {
        Logger.info('✅ APK installation triggered successfully - Android system will take over');
        
        // Show simple success message
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Installation started. Follow the system prompts to complete.')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        Logger.error('❌ Failed to trigger APK installation');
        
        // Show error message with manual install option
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Installation failed. Please check permissions and try again.')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error during APK installation', error: e);

      scaffoldMessenger?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Installation error: $e')),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
          
    // Reset download state after installation attempt
    _isDownloading = false;
    onDownloadStateChanged?.call(false);
  }

  /// Skip version with confirmation dialog
  void skipVersion(UpdateInfo updateInfo, BuildContext context, VoidCallback? onComplete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Version'),
        content: Text(
          'Do you want to skip version ${updateInfo.latestVersion}? '
          'You won\'t be notified about this version again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save context references before async operation
              NavigatorState? navigator;
              ScaffoldMessengerState? scaffoldMessenger;
              
              if (context.mounted) {
                navigator = Navigator.of(context);
                scaffoldMessenger = ScaffoldMessenger.of(context);
                navigator.pop(); // Close confirmation dialog
                navigator.pop(); // Close update dialog
              }
              
              await _updateService.skipVersion(updateInfo.latestVersion);
              onComplete?.call();
              
              if (context.mounted && scaffoldMessenger != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Version ${updateInfo.latestVersion} skipped'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        _updateService.preferences?.unskipVersion(updateInfo.latestVersion);
                        _updateService.preferences?.save();
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  /// Clean up resources
  void dispose() {
    // No specific cleanup needed for now
    // Stream subscriptions are handled by the services themselves
  }
}