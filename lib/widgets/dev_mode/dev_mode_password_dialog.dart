import 'package:flutter/material.dart';

import '../../core/service_locator.dart' show getIt;
import '../../l10n/app_strings.dart';
import '../../services/role_service.dart';

/// Modal dialog that asks for the developer-mode password.
///
/// Returns `true` via [Navigator.pop] if the user successfully unlocks
/// developer mode, `false` otherwise (cancel, dismiss, or repeated wrong
/// passwords). Includes a "forgot password" path that resets the stored
/// hash to the factory default — see [RoleService.resetPasswordToDefault]
/// for why this is safe.
class DevModePasswordDialog extends StatefulWidget {
  const DevModePasswordDialog({super.key});

  static Future<bool> show({required BuildContext context}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DevModePasswordDialog(),
    );
    return result ?? false;
  }

  @override
  State<DevModePasswordDialog> createState() => _DevModePasswordDialogState();
}

class _DevModePasswordDialogState extends State<DevModePasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _attemptUnlock() async {
    final input = _controller.text;
    if (input.isEmpty) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final ok = await getIt<RoleService>().tryEnableDeveloperMode(input);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _errorText = AppStrings.incorrectPassword;
      _controller.clear();
    });
  }

  Future<void> _onForgotPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.orange,
          ),
          title: const Text(AppStrings.forgotPasswordTitle),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBullet(
                  context: ctx,
                  text: AppStrings.forgotPasswordBullet1,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(height: 8),
                _buildBullet(
                  context: ctx,
                  text: AppStrings.forgotPasswordBullet2,
                  color: colorScheme.onSurface,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(AppStrings.forgotPasswordResetButton),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await getIt<RoleService>().resetPasswordToDefault();
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _errorText = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.passwordResetSuccess)),
    );
  }

  Widget _buildBullet({
    required BuildContext context,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.enterDeveloperPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            enabled: !_busy,
            decoration: InputDecoration(
              hintText: AppStrings.passwordHint,
              border: const OutlineInputBorder(),
              errorText: _errorText,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            onSubmitted: (_) => _attemptUnlock(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _onForgotPassword,
              child: const Text(AppStrings.forgotPassword),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _attemptUnlock,
          child: const Text(AppStrings.confirm),
        ),
      ],
    );
  }
}
