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
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.forgotPasswordTitle),
        content: const Text(AppStrings.forgotPasswordBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
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
