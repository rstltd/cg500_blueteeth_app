import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/theme_service.dart';

/// Widget for displaying version information and release notes
class VersionInfoWidget extends StatelessWidget {
  final UpdateInfo updateInfo;

  const VersionInfoWidget({
    super.key,
    required this.updateInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version info
        _buildInfoRow(context, 'Current Version', updateInfo.currentVersion),
        _buildInfoRow(context, 'New Version', updateInfo.latestVersion),
        _buildInfoRow(
          context,
          'Download Size',
          '${(updateInfo.downloadSize / (1024 * 1024)).toStringAsFixed(1)} MB',
        ),
        _buildInfoRow(
          context,
          'Release Date',
          _formatDate(updateInfo.releaseDate),
        ),
        
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
            updateInfo.releaseNotes.isNotEmpty
                ? updateInfo.releaseNotes
                : 'Bug fixes and performance improvements',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}