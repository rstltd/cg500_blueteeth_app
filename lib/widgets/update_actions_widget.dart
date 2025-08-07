import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../services/theme_service.dart';

/// Widget for update dialog action buttons and browser download option
class UpdateActionsWidget extends StatelessWidget {
  final UpdateInfo updateInfo;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onStartUpdate;
  final VoidCallback? onSkipVersion;
  final VoidCallback? onDismiss;

  const UpdateActionsWidget({
    super.key,
    required this.updateInfo,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onStartUpdate,
    this.onSkipVersion,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildDownloadFailureWarning(context),
          _buildActionButtons(context),
          const SizedBox(height: 12),
          _buildBrowserDownloadButton(context),
        ],
      ),
    );
  }

  /// Build download failure warning message
  Widget _buildDownloadFailureWarning(BuildContext context) {
    if (!(isDownloading && downloadProgress == 0.0)) {
      return const SizedBox.shrink();
    }

    return Container(
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
    );
  }

  /// Build main action buttons row
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        ..._buildOptionalButtons(context),
        if (_shouldShowOptionalButtons())
          const SizedBox(width: 8),
        _buildUpdateButton(context),
      ],
    );
  }

  /// Build optional buttons (Skip and Later) for non-forced updates
  List<Widget> _buildOptionalButtons(BuildContext context) {
    if (!_shouldShowOptionalButtons()) {
      return [];
    }

    return [
      Expanded(
        child: TextButton.icon(
          onPressed: onSkipVersion,
          icon: const Icon(Icons.block),
          label: const Text('Skip'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
        ),
      ),
      Expanded(
        child: TextButton(
          onPressed: onDismiss,
          child: const Text('Later'),
        ),
      ),
    ];
  }

  /// Build main update button
  Widget _buildUpdateButton(BuildContext context) {
    return Expanded(
      flex: _getUpdateButtonFlex(),
      child: ElevatedButton(
        onPressed: isDownloading ? null : onStartUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getPrimaryColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildUpdateButtonChild(),
      ),
    );
  }

  /// Build update button child widget (loading or text)
  Widget _buildUpdateButtonChild() {
    if (isDownloading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Text(
      _getUpdateButtonText(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  /// Build browser download button as backup option
  Widget _buildBrowserDownloadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openBrowserDownload(context),
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
    );
  }

  /// Check if update is forced (critical or forced type)
  bool _isUpdateForced() {
    return updateInfo.isForced;
  }

  /// Check if optional buttons should be shown
  bool _shouldShowOptionalButtons() {
    return !_isUpdateForced() && !isDownloading;
  }

  /// Get button text based on update type
  String _getUpdateButtonText() {
    return _isUpdateForced() ? 'Update Now' : 'Update';
  }

  /// Get button flex value based on update type
  int _getUpdateButtonFlex() {
    return _isUpdateForced() ? 2 : 1;
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

  /// Open browser download as backup option
  Future<void> _openBrowserDownload(BuildContext context) async {
    const url = 'https://github.com/rstltd/cg500_blueteeth_app/releases/latest';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show guidance dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => _buildDownloadGuideDialog(context),
          );
        }
      } else {
        if (context.mounted) {
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
      if (context.mounted) {
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

  /// Build download guide dialog
  Widget _buildDownloadGuideDialog(BuildContext context) {
    return AlertDialog(
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
    );
  }
}