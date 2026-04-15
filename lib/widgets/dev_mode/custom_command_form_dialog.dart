import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/command/custom_command.dart';
import '../../services/custom_command_service.dart';

/// Shared form for adding and editing a [CustomCommand].
///
/// Returns the saved [CustomCommand] on success, or `null` if the user
/// cancels. Validation is delegated to the supplied [onSubmit] callback
/// (typically a thin wrapper around the ViewModel's add/update method
/// so the same [CustomCommandService] conflict checks apply).
class CustomCommandFormDialog extends StatefulWidget {
  const CustomCommandFormDialog({
    super.key,
    required this.onSubmit,
    this.initial,
  });

  /// Existing command being edited, or `null` for add-new mode.
  final CustomCommand? initial;

  /// Callback that performs the actual add/update. Returns the result
  /// from [CustomCommandService] so this widget can map it to an
  /// inline error message.
  final Future<CustomCommandResult> Function(CustomCommand submitted) onSubmit;

  static Future<bool> show({
    required BuildContext context,
    CustomCommand? initial,
    required Future<CustomCommandResult> Function(CustomCommand) onSubmit,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomCommandFormDialog(
        initial: initial,
        onSubmit: onSubmit,
      ),
    );
    return result ?? false;
  }

  @override
  State<CustomCommandFormDialog> createState() =>
      _CustomCommandFormDialogState();
}

class _CustomCommandFormDialogState extends State<CustomCommandFormDialog> {
  late final TextEditingController _commandCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  String? _errorText;
  bool _busy = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _commandCtrl = TextEditingController(text: widget.initial?.command ?? '');
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _descriptionCtrl =
        TextEditingController(text: widget.initial?.description ?? '');
  }

  @override
  void dispose() {
    _commandCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String? _clientSideValidation(CustomCommand cmd) {
    final trimmed = cmd.command.trim();
    if (trimmed.isEmpty) return AppStrings.customCommandEmptyError;
    if (!trimmed.startsWith(r'$')) {
      return AppStrings.customCommandMustStartWithDollar;
    }
    if (cmd.name.trim().isEmpty) {
      return AppStrings.customCommandNameEmptyError;
    }
    return null;
  }

  String? _mapResult(CustomCommandResult result) {
    switch (result) {
      case CustomCommandResult.success:
        return null;
      case CustomCommandResult.invalidFormat:
        return AppStrings.customCommandMustStartWithDollar;
      case CustomCommandResult.nameRequired:
        return AppStrings.customCommandNameEmptyError;
      case CustomCommandResult.duplicateInCustom:
        return AppStrings.customCommandDuplicateInCustom;
      case CustomCommandResult.duplicateInBuiltIn:
        return AppStrings.customCommandDuplicateInBuiltIn;
      case CustomCommandResult.notFound:
        return '';
    }
  }

  Future<void> _onSave() async {
    final cmd = CustomCommand(
      command: _commandCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
    );

    final clientError = _clientSideValidation(cmd);
    if (clientError != null) {
      setState(() => _errorText = clientError);
      return;
    }

    setState(() {
      _busy = true;
      _errorText = null;
    });

    final result = await widget.onSubmit(cmd);
    if (!mounted) return;

    final error = _mapResult(result);
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _busy = false;
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit
          ? AppStrings.editCustomCommand
          : AppStrings.addCustomCommand),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _commandCtrl,
              autofocus: !_isEdit,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: AppStrings.customCommandStringHint,
                hintText: r'$MAC,CN001',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.terminal),
                errorText: _errorText,
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: AppStrings.customCommandNameHint,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              enabled: !_busy,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.customCommandDescriptionHint,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
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
          onPressed: _busy ? null : _onSave,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
