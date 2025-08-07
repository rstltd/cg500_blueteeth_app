import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../services/network_service.dart';
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';
import 'install_guide_dialog.dart';

/// Dialog for displaying update information and handling user actions
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onDismiss;
  final VoidCallback? onUpdateComplete;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onDismiss,
    this.onUpdateComplete,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> with TickerProviderStateMixin {
  final UpdateService _updateService = UpdateService();
  final NetworkService _networkService = NetworkService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  NetworkStatus _networkStatus = NetworkStatus.unknown;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    
    // Get initial network status
    _networkStatus = _networkService.currentStatus;
    
    // Listen to network changes
    _networkService.networkStream.listen((status) {
      if (mounted) {
        setState(() {
          _networkStatus = status;
        });
      }
    });
    
    // Listen to download progress
    _updateService.downloadStream.listen((progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress.progress;
          _downloadStatus = progress.sizeText;
        });
        
        // Auto install when download completes
        if (progress.progress >= 1.0 && progress.filePath != null) {
          _installUpdate(progress.filePath!);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 500 : MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildContent(),
                  _buildActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.updateInfo.updateType == UpdateType.critical
                ? Colors.red.shade600
                : widget.updateInfo.updateType == UpdateType.forced
                    ? Colors.orange.shade600
                    : Colors.blue.shade600,
            widget.updateInfo.updateType == UpdateType.critical
                ? Colors.red.shade500
                : widget.updateInfo.updateType == UpdateType.forced
                    ? Colors.orange.shade500
                    : Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.updateInfo.updateType == UpdateType.critical
                  ? Icons.security
                  : widget.updateInfo.updateType == UpdateType.forced
                      ? Icons.system_update
                      : Icons.system_update_alt,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.updateInfo.updateType == UpdateType.critical
                      ? 'Critical Update'
                      : widget.updateInfo.updateType == UpdateType.forced
                          ? 'Required Update'
                          : 'Update Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version ${widget.updateInfo.latestVersion}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version info
            _buildInfoRow('Current Version', widget.updateInfo.currentVersion),
            _buildInfoRow('New Version', widget.updateInfo.latestVersion),
            _buildInfoRow(
              'Download Size',
              '${(widget.updateInfo.downloadSize / (1024 * 1024)).toStringAsFixed(1)} MB',
            ),
            _buildInfoRow(
              'Release Date',
              _formatDate(widget.updateInfo.releaseDate),
            ),
            _buildNetworkInfo(),
            
            const SizedBox(height: 24),
            
            // Release notes
            Text(
              'What\'s New:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundGradientStart(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderColor(context),
                ),
              ),
              child: Text(
                widget.updateInfo.releaseNotes.isNotEmpty
                    ? widget.updateInfo.releaseNotes
                    : 'Bug fixes and performance improvements',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ),
            
            // Download progress
            if (_isDownloading) ...[
              const SizedBox(height: 24),
              _buildDownloadProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            Text(
              _downloadStatus,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _downloadProgress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_downloadProgress * 100).toInt()}% complete',
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Show download failure message if needed
          if (_isDownloading && _downloadProgress == 0.0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If download fails, try "Browser Download" below',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
            children: [
              // Skip version button (only for non-forced updates)
              if (!widget.updateInfo.isForced && !_isDownloading)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _skipVersion(),
                    icon: const Icon(Icons.block),
                    label: const Text('Skip'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),
              
              // Later button
              if (!widget.updateInfo.isForced && !_isDownloading)
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDismiss?.call();
                    },
                    child: const Text('Later'),
                  ),
                ),
              
              if (!widget.updateInfo.isForced && !_isDownloading)
                const SizedBox(width: 8),
              
              // Update button
              Expanded(
                flex: widget.updateInfo.isForced ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _isDownloading ? null : _startUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.updateInfo.updateType == UpdateType.critical
                        ? Colors.red.shade600
                        : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.updateInfo.isForced ? 'Update Now' : 'Update',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
          
          // Browser download button (backup option)
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openBrowserDownload,
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Browser Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
                side: BorderSide(color: Colors.blue.shade600),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
    });

    final success = await _updateService.downloadUpdate(widget.updateInfo);
    
    if (!success) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _installUpdate(String apkPath) async {
    // Show installation guide first
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => InstallGuideDialog(
          onComplete: () async {
            // Save context references before async operation
            NavigatorState? navigator;
            ScaffoldMessengerState? scaffoldMessenger;
            
            if (mounted) {
              navigator = Navigator.of(context);
              scaffoldMessenger = ScaffoldMessenger.of(context);
            }
            
            // After guide is complete, try to install the APK
            final success = await _updateService.installUpdate(apkPath);
            
            if (success) {
              // Installation started, close dialogs
              if (mounted && navigator != null) {
                navigator.pop(); // Close guide dialog if still open
                navigator.pop(); // Close update dialog
                widget.onUpdateComplete?.call();
              }
            } else {
              // Installation failed, reset download state
              if (mounted) {
                setState(() {
                  _isDownloading = false;
                });
                
                // Show error message
                if (scaffoldMessenger != null) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Installation failed. Please try again or install manually.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
      );
    }
  }

  Widget _buildNetworkInfo() {
    final isWifiRequired = _updateService.preferences?.wifiOnlyDownload ?? true;
    final networkSuitable = _networkService.isSuitableForDownload(wifiOnly: isWifiRequired);
    final estimatedTime = _networkService.estimateDownloadTime(widget.updateInfo.downloadSize);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Network:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  _getNetworkIcon(),
                  size: 16,
                  color: networkSuitable ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _networkService.getNetworkTypeDisplayName(),
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!networkSuitable)
                        Text(
                          'WiFi recommended',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        'Est. $estimatedTime',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNetworkIcon() {
    switch (_networkStatus) {
      case NetworkStatus.wifi:
        return Icons.wifi;
      case NetworkStatus.mobile:
        return Icons.signal_cellular_4_bar;
      case NetworkStatus.none:
        return Icons.wifi_off;
      case NetworkStatus.unknown:
        return Icons.help_outline;
    }
  }

  void _skipVersion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Version'),
        content: Text(
          'Do you want to skip version ${widget.updateInfo.latestVersion}? '
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
              
              if (mounted) {
                navigator = Navigator.of(context);
                scaffoldMessenger = ScaffoldMessenger.of(context);
                navigator.pop(); // Close confirmation dialog
                navigator.pop(); // Close update dialog
              }
              
              await _updateService.skipVersion(widget.updateInfo.latestVersion);
              widget.onDismiss?.call();
              
              if (mounted && scaffoldMessenger != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Version ${widget.updateInfo.latestVersion} skipped'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        _updateService.preferences?.unskipVersion(widget.updateInfo.latestVersion);
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Open browser download as backup option
  Future<void> _openBrowserDownload() async {
    const url = 'https://github.com/rstltd/cg500_blueteeth_app/releases/latest';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show guidance dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Download Guide'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📱 Manual Download Instructions:'),
                  SizedBox(height: 12),
                  Text('1. Find the APK file on GitHub'),
                  Text('2. Tap to download the APK'),
                  Text('3. Open Downloads folder'),
                  Text('4. Tap the APK to install'),
                  Text('5. Allow "Install from unknown sources" if prompted'),
                  SizedBox(height: 12),
                  Text('The APK file will be named like:\ncg500_ble_app_v1.1.0.apk'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Cannot open browser. Please visit:\n$url'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to open browser: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}