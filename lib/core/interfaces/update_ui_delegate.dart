import 'package:flutter/material.dart';

/// Result of an installation attempt
enum InstallResult {
  success,
  failed,
  error,
}

/// Delegate for update-related UI operations.
///
/// This class separates UI concerns from business logic in UpdateLogicManager,
/// making the manager easier to test and maintaining single responsibility.
/// Uses SnackBars and AlertDialogs for UI feedback.
class UpdateUIDelegate {
  const UpdateUIDelegate();

  /// Show a message indicating installation has started successfully
  void showInstallationStarted(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Installation started. Follow the system prompts to complete.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a message indicating installation failed
  void showInstallationFailed(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Installation failed. Please check permissions and try again.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a message indicating an installation error with details
  void showInstallationError(BuildContext context, String errorMessage) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Installation error: $errorMessage')),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show skip version confirmation dialog
  /// Returns true if user confirmed skip, false if cancelled
  Future<bool> showSkipVersionConfirmation(
    BuildContext context,
    String version,
  ) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Skip Version'),
        content: Text(
          'Do you want to skip version $version? '
          'You won\'t be notified about this version again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show a message indicating version was skipped with undo option
  void showVersionSkipped(
    BuildContext context,
    String version,
    VoidCallback onUndo,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Version $version skipped'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: onUndo,
        ),
      ),
    );
  }

  /// Close any open dialogs (e.g., update dialog)
  void closeDialogs(BuildContext context, {int count = 1}) {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    for (int i = 0; i < count; i++) {
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}
