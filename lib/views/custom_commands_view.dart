import 'package:flutter/material.dart';

import '../core/view_model/view_model.dart';
import '../l10n/app_strings.dart';
import '../models/command/custom_command.dart';
import '../view_models/custom_commands_view_model.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/dev_mode/custom_command_form_dialog.dart';

/// Management screen for user-defined BLE commands.
///
/// Only reachable from the developer-mode section of the settings view.
/// The role gate itself is enforced elsewhere — this screen simply
/// assumes the caller verified the user is in developer mode.
class CustomCommandsView extends StatelessWidget {
  const CustomCommandsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<CustomCommandsViewModel>(
      create: () => CustomCommandsViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.customCommands),
          ),
          body: _CustomCommandsBody(viewModel: viewModel),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _onAdd(context, viewModel),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addCustomCommand),
          ),
        );
      },
    );
  }

  Future<void> _onAdd(
    BuildContext context,
    CustomCommandsViewModel viewModel,
  ) async {
    await CustomCommandFormDialog.show(
      context: context,
      onSubmit: viewModel.addCommand,
    );
  }
}

class _CustomCommandsBody extends StatelessWidget {
  const _CustomCommandsBody({required this.viewModel});

  final CustomCommandsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (viewModel.hasConflicts) _ConflictsBanner(viewModel: viewModel),
        Expanded(
          child: viewModel.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 96, left: 8, right: 8),
                  itemCount: viewModel.commands.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cmd = viewModel.commands[index];
                    return _CommandListTile(
                      command: cmd,
                      onEdit: () => _onEdit(context, viewModel, cmd),
                      onDelete: () => _onDelete(context, viewModel, cmd),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _onEdit(
    BuildContext context,
    CustomCommandsViewModel viewModel,
    CustomCommand cmd,
  ) async {
    await CustomCommandFormDialog.show(
      context: context,
      initial: cmd,
      onSubmit: (updated) => viewModel.updateCommand(cmd.command, updated),
    );
  }

  Future<void> _onDelete(
    BuildContext context,
    CustomCommandsViewModel viewModel,
    CustomCommand cmd,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.customCommandDeleteTitle),
        content: Text(AppStrings.customCommandDeleteBody(cmd.command)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await viewModel.removeCommand(cmd.command);
    }
  }
}

class _ConflictsBanner extends StatelessWidget {
  const _ConflictsBanner({required this.viewModel});

  final CustomCommandsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(
                AppStrings.customCommandConflictsTitle,
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(AppStrings.customCommandConflictsBody),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: viewModel.conflicts
                .map(
                  (c) => Chip(
                    label: Text(
                      c.command,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    backgroundColor: Colors.orange.shade100,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // FAB already provides the "add" affordance; keeping it here too would
    // give the screen two primary actions for the same thing.
    return AppEmptyState(
      icon: Icons.edit_note,
      title: AppStrings.customCommandsEmpty,
      message: AppStrings.customCommandsEmptyExamples,
    );
  }
}

class _CommandListTile extends StatelessWidget {
  const _CommandListTile({
    required this.command,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomCommand command;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.terminal),
      title: Text(
        command.command,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(command.name),
          if (command.description.isNotEmpty)
            Text(
              command.description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
        ],
      ),
      isThreeLine: command.description.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}
