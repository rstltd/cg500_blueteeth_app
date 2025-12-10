import 'package:flutter/material.dart';
import '../../controllers/app_update_manager.dart';
import '../../design/design_system.dart';
import '../../services/update_service.dart';
import '../../utils/logger.dart';
import '../../l10n/app_strings.dart';

/// Banner widget that shows update notification at the top of the app
/// Replaces the legacy update banner with enhanced functionality
class UpdateNotificationBanner extends StatefulWidget {
  final AppUpdateManager updateManager;
  
  const UpdateNotificationBanner({
    super.key,
    required this.updateManager,
  });

  @override
  State<UpdateNotificationBanner> createState() => _UpdateNotificationBannerState();
}

class _UpdateNotificationBannerState extends State<UpdateNotificationBanner> 
    with SingleTickerProviderStateMixin {
  UpdateInfo? _updateInfo;
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

    // Listen for update information
    _checkForUpdateInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkForUpdateInfo() {
    // Get latest update info from manager
    _updateInfo = widget.updateManager.latestUpdateInfo;
    
    if (_updateInfo != null && !_isDismissed) {
      Logger.debug('Showing update notification banner for version ${_updateInfo!.latestVersion}');
      _animationController.forward();
    }
  }

  void _dismissBanner() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isDismissed = true;
          _updateInfo = null;
        });
      }
    });
  }

  void _showUpdateDialog() {
    if (_updateInfo != null) {
      Logger.debug('Opening update dialog from banner');
      widget.updateManager.showUpdateDialogIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh update info on each build
    if (!_isDismissed && _updateInfo == null) {
      _checkForUpdateInfo();
    }

    if (_updateInfo == null || _isDismissed) {
      return const SizedBox.shrink();
    }

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
                colors: _getGradientColors(),
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
                          _getUpdateIcon(),
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
                              _getUpdateTitle(),
                              style: TextStyle(
                                color: AppColors.textOnPrimary(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getUpdateMessage(),
                              style: TextStyle(
                                color: AppColors.whiteOverlay90(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      if (!_updateInfo!.isForced) ...[
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
                            foregroundColor: _getPrimaryColor(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            _updateInfo!.isForced ? AppStrings.updateNow : AppStrings.update,
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

  List<Color> _getGradientColors() {
    switch (_updateInfo!.updateType) {
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

  IconData _getUpdateIcon() {
    switch (_updateInfo!.updateType) {
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

  String _getUpdateTitle() {
    switch (_updateInfo!.updateType) {
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

  String _getUpdateMessage() {
    return AppStrings.updateDescription(_updateInfo!.latestVersion);
  }

  Color _getPrimaryColor() {
    switch (_updateInfo!.updateType) {
      case UpdateType.critical:
        return AppColors.updateForcedColor(context);
      case UpdateType.forced:
        return AppColors.updateRecommendedColor(context);
      default:
        return AppColors.updateRequiredColor(context);
    }
  }
}