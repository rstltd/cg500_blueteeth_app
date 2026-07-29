import 'package:flutter/material.dart';
import '../../controllers/update_controller.dart';
import '../../design/design_system.dart';
import '../../models/update_info.dart';
import '../../models/update_type.dart';
import '../../utils/logger.dart';
import '../../l10n/app_strings.dart';

/// Banner widget that shows update notification at the top of the app
/// Replaces the legacy update banner with enhanced functionality
class UpdateNotificationBanner extends StatefulWidget {
  final UpdateController updateManager;

  const UpdateNotificationBanner({
    super.key,
    required this.updateManager,
  });

  @override
  State<UpdateNotificationBanner> createState() => _UpdateNotificationBannerState();
}

class _UpdateNotificationBannerState extends State<UpdateNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Play the slide-in once the banner becomes visible. Scheduled after the
  /// frame because starting an animation during build would mark widgets
  /// dirty mid-build.
  void _revealBanner() {
    if (_animationController.status != AnimationStatus.dismissed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDismissed) return;
      final info = widget.updateManager.latestUpdateInfo;
      if (info == null) return;
      if (_animationController.status != AnimationStatus.dismissed) return;
      Logger.debug(
          'Showing update notification banner for version ${info.latestVersion}');
      _animationController.forward();
    });
  }

  void _dismissBanner() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    });
  }

  void _showUpdateDialog() {
    Logger.debug('Opening update dialog from banner');
    widget.updateManager.showUpdateDialogIfAvailable();
  }

  @override
  Widget build(BuildContext context) {
    // The controller is the single owner of update state — read it on every
    // notification instead of caching a private copy, so a skipped or
    // completed update makes the banner disappear immediately.
    return ListenableBuilder(
      listenable: widget.updateManager,
      builder: (context, _) {
        final updateInfo = widget.updateManager.latestUpdateInfo;

        if (updateInfo == null || _isDismissed) {
          return const SizedBox.shrink();
        }

        _revealBanner();

        return _buildBanner(updateInfo);
      },
    );
  }

  Widget _buildBanner(UpdateInfo updateInfo) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 60),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(updateInfo),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor(context),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: AppColors.surfaceColor(context).withValues(alpha: 0),
              child: InkWell(
                onTap: _showUpdateDialog,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Update icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.whiteOverlay20(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getUpdateIcon(updateInfo),
                          color: AppColors.textOnPrimary(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Update information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getUpdateTitle(updateInfo),
                              style: TextStyle(
                                color: AppColors.textOnPrimary(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getUpdateMessage(updateInfo),
                              style: TextStyle(
                                color: AppColors.whiteOverlay90(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      if (!updateInfo.isForced) ...[
                        IconButton(
                          onPressed: _dismissBanner,
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textOnPrimary(context),
                            size: 20,
                          ),
                          tooltip: AppStrings.close,
                        ),
                      ],

                      // Update button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.textOnPrimary(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: _showUpdateDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: _getPrimaryColor(updateInfo),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            updateInfo.isForced ? AppStrings.updateNow : AppStrings.update,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors(UpdateInfo updateInfo) {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return [AppColors.updateForcedColor(context), AppColors.errorColor(context)];
      case UpdateType.forced:
        return [AppColors.updateRecommendedColor(context), AppColors.warningColor(context)];
      case UpdateType.recommended:
        return [AppColors.updateRequiredColor(context), AppColors.infoColor(context)];
      default:
        return [AppColors.updateOptionalColor(context), AppColors.successColor(context)];
    }
  }

  IconData _getUpdateIcon(UpdateInfo updateInfo) {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return Icons.warning;
      case UpdateType.forced:
        return Icons.update;
      case UpdateType.recommended:
        return Icons.system_update;
      default:
        return Icons.system_update_alt;
    }
  }

  String _getUpdateTitle(UpdateInfo updateInfo) {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return AppStrings.importantUpdateAvailable;
      case UpdateType.forced:
        return AppStrings.requiredUpdate;
      case UpdateType.recommended:
        return AppStrings.updateAvailable;
      default:
        return AppStrings.optionalUpdate;
    }
  }

  String _getUpdateMessage(UpdateInfo updateInfo) {
    return AppStrings.updateDescription(updateInfo.latestVersion);
  }

  Color _getPrimaryColor(UpdateInfo updateInfo) {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return AppColors.updateForcedColor(context);
      case UpdateType.forced:
        return AppColors.updateRecommendedColor(context);
      default:
        return AppColors.updateRequiredColor(context);
    }
  }
}
