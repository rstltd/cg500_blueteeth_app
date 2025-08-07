import 'package:flutter/material.dart';
import '../services/update_service.dart';

/// Widget for update dialog header with type-specific styling
class UpdateHeaderWidget extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateHeaderWidget({
    super.key,
    required this.updateInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildHeaderDecoration(),
      child: Row(
        children: [
          _buildHeaderIcon(),
          const SizedBox(width: 16),
          _buildHeaderText(),
        ],
      ),
    );
  }

  /// Build header decoration with gradient
  BoxDecoration _buildHeaderDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          _getPrimaryColor(),
          _getSecondaryColor(),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    );
  }

  /// Build header icon container
  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getUpdateTypeIcon(),
        color: Colors.white,
        size: 28,
      ),
    );
  }

  /// Build header text content
  Widget _buildHeaderText() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getUpdateTypeTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version ${updateInfo.latestVersion}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Get primary color based on update type
  Color _getPrimaryColor() {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return Colors.red.shade600;
      case UpdateType.forced:
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  /// Get secondary color based on update type
  Color _getSecondaryColor() {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return Colors.red.shade500;
      case UpdateType.forced:
        return Colors.orange.shade500;
      default:
        return Colors.blue.shade500;
    }
  }

  /// Get update type title
  String _getUpdateTypeTitle() {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return 'Critical Update';
      case UpdateType.forced:
        return 'Required Update';
      default:
        return 'Update Available';
    }
  }

  /// Get update type icon
  IconData _getUpdateTypeIcon() {
    switch (updateInfo.updateType) {
      case UpdateType.critical:
        return Icons.security;
      case UpdateType.forced:
        return Icons.system_update;
      default:
        return Icons.system_update_alt;
    }
  }
}