import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/update_service.dart';
import '../../services/theme_service.dart';

/// Simplified version info widget for the update dialog.
///
/// Shows only the three pieces of information a field operator needs:
/// current version, new version, and download size. All other details
/// (SHA256, release date, raw release notes) have been removed.
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
        _buildInfoRow(
          context,
          AppStrings.currentVersionLabel,
          updateInfo.currentVersion,
        ),
        _buildInfoRow(
          context,
          AppStrings.newVersionLabel,
          updateInfo.latestVersion,
        ),
        _buildInfoRow(
          context,
          AppStrings.downloadSizeLabel,
          '${(updateInfo.downloadSize / (1024 * 1024)).toStringAsFixed(1)} MB',
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
              '$label：',
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
