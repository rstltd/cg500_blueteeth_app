import 'package:flutter/material.dart';
import '../controllers/app_update_manager.dart';
import '../services/update_service.dart';
import '../utils/logger.dart';

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
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
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
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getUpdateIcon(),
                          color: Colors.white,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getUpdateMessage(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
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
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Dismiss',
                        ),
                      ],
                      
                      // Update button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            _updateInfo!.isForced ? 'Update Now' : 'Update',
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
        return [Colors.red.shade600, Colors.red.shade800];
      case UpdateType.forced:
        return [Colors.orange.shade600, Colors.orange.shade800];
      case UpdateType.recommended:
        return [Colors.blue.shade600, Colors.blue.shade800];
      default:
        return [Colors.green.shade600, Colors.green.shade800];
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
        return 'Critical Update Available';
      case UpdateType.forced:
        return 'Required Update';
      case UpdateType.recommended:
        return 'Update Available';
      default:
        return 'Optional Update';
    }
  }

  String _getUpdateMessage() {
    return 'Version ${_updateInfo!.latestVersion} with enhanced features is available';
  }

  Color _getPrimaryColor() {
    switch (_updateInfo!.updateType) {
      case UpdateType.critical:
        return Colors.red.shade600;
      case UpdateType.forced:
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}