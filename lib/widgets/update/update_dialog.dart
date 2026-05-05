import 'package:flutter/material.dart';
import '../../services/update_service.dart' show UpdateInfo;
import '../../controllers/update_controller.dart';
import '../../core/service_locator.dart' show getIt;
import '../layout/responsive_layout.dart';
import 'update_header_widget.dart';
import 'version_info_widget.dart';
import 'update_progress_widget.dart';
import 'update_actions_widget.dart';

/// Simplified update dialog.
///
/// Shows only what a field operator needs: version numbers, download size,
/// download progress, and action buttons. NetworkInfoWidget and the 4-step
/// InstallGuideDialog have been removed.
///
/// State (download in progress, current progress %, status text) is read
/// from the shared `UpdateController` via `ListenableBuilder`. The previous
/// per-dialog `UpdateLogicManager` instance is gone — opening the dialog
/// twice no longer creates two listeners on the same download stream.
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

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late final UpdateController _controller;

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

    _controller = getIt<UpdateController>();
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
                maxWidth:
                    isDesktop ? 500 : MediaQuery.of(context).size.width * 0.9,
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
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final isDownloading = _controller.isDownloading;
                  final progress = _controller.downloadProgress;
                  final status = _controller.downloadStatus;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UpdateHeaderWidget(updateInfo: widget.updateInfo),
                      _buildContent(
                        isDownloading: isDownloading,
                        downloadProgress: progress,
                        downloadStatus: status,
                      ),
                      UpdateActionsWidget(
                        updateInfo: widget.updateInfo,
                        isDownloading: isDownloading,
                        downloadProgress: progress,
                        onStartUpdate: _startUpdate,
                        onSkipVersion: _skipVersion,
                        onDismiss: () {
                          Navigator.of(context).pop();
                          widget.onDismiss?.call();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required bool isDownloading,
    required double downloadProgress,
    required String downloadStatus,
  }) {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VersionInfoWidget(updateInfo: widget.updateInfo),
            if (isDownloading) ...[
              const SizedBox(height: 24),
              UpdateProgressWidget(
                progress: downloadProgress,
                statusText: downloadStatus,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startUpdate() async {
    await _controller.startUpdate(widget.updateInfo, context);
  }

  void _skipVersion() {
    _controller.skipVersion(widget.updateInfo, context, widget.onDismiss);
  }
}
