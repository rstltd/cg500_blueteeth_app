import 'package:flutter/material.dart';

import '../../core/service_locator.dart' show getIt;
import '../../l10n/app_strings.dart';
import '../../services/role_service.dart';

/// Modal dialog for changing the developer-mode password while in dev mode.
///
/// Requires the old password and a matching pair of new password entries.
/// Returns `true` via [Navigator.pop] on success.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<bool> show({required BuildContext context}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
    return result ?? false;
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _oldCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  String? _errorText;
  bool _busy = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _attemptChange() async {
    final oldPwd = _oldCtrl.text;
    final newPwd = _newCtrl.text;
    final confirmPwd = _confirmCtrl.text;

    if (newPwd.length < RoleService.minPasswordLength) {
      setState(() => _errorText = AppStrings.passwordTooShort);
      return;
    }
    if (newPwd != confirmPwd) {
      setState(() => _errorText = AppStrings.passwordMismatch);
      return;
    }

    setState(() {
      _busy = true;
      _errorText = null;
    });

    final ok = await getIt<RoleService>().changePassword(oldPwd, newPwd);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.changePasswordSuccess)),
      );
      return;
    }

    setState(() {
      _busy = false;
      _errorText = AppStrings.incorrectPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.changePasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _oldCtrl,
              obscureText: true,
              autofocus: true,
              enabled: !_busy,
              decoration: const InputDecoration(
                hintText: AppStrings.oldPasswordHint,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(
                hintText: AppStrings.newPasswordHint,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              enabled: !_busy,
              decoration: InputDecoration(
                hintText: AppStrings.confirmNewPasswordHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.check),
                errorText: _errorText,
              ),
              onSubmitted: (_) => _attemptChange(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _attemptChange,
          child: const Text(AppStrings.confirm),
        ),
      ],
    );
  }
}
