import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/network_service.dart';
import '../utils/responsive_utils.dart';
import '../controllers/update_logic_manager.dart';
import '../widgets/update_header_widget.dart';
import '../widgets/version_info_widget.dart';
import '../widgets/update_progress_widget.dart';
import '../widgets/network_info_widget.dart';
import '../widgets/update_actions_widget.dart';

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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late UpdateLogicManager _updateManager;
  
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
    
    // Initialize update manager
    _updateManager = UpdateLogicManager(
      onDownloadStateChanged: (isDownloading) {
        if (mounted) {
          setState(() {
            _isDownloading = isDownloading;
          });
        }
      },
      onProgressUpdated: (progress, status) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = status;
          });
        }
      },
      onNetworkStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _networkStatus = status;
          });
        }
      },
    );
    
    _updateManager.initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateManager.dispose();
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
                  UpdateHeaderWidget(updateInfo: widget.updateInfo),
                  _buildContent(),
                  UpdateActionsWidget(
                    updateInfo: widget.updateInfo,
                    isDownloading: _isDownloading,
                    downloadProgress: _downloadProgress,
                    onStartUpdate: _startUpdate,
                    onSkipVersion: _skipVersion,
                    onDismiss: () {
                      Navigator.of(context).pop();
                      widget.onDismiss?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version info and release notes
            VersionInfoWidget(updateInfo: widget.updateInfo),
            
            // Network info
            NetworkInfoWidget(
              networkService: _updateManager.networkService,
              updateService: _updateManager.updateService,
              downloadSize: widget.updateInfo.downloadSize,
              networkStatus: _networkStatus,
            ),
            
            // Download progress
            if (_isDownloading) ...[
              const SizedBox(height: 24),
              UpdateProgressWidget(
                progress: _downloadProgress,
                statusText: _downloadStatus,
              ),
            ],
          ],
        ),
      ),
    );
  }




  Future<void> _startUpdate() async {
    await _updateManager.startUpdate(widget.updateInfo, context);
  }



  void _skipVersion() {
    _updateManager.skipVersion(widget.updateInfo, context, widget.onDismiss);
  }

}