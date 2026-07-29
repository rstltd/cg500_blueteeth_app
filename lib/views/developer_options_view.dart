import 'package:flutter/material.dart';

import '../core/service_locator.dart' show getIt;
import '../l10n/app_strings.dart';
import '../models/role/user_role.dart';
import '../services/role_service.dart';
import '../utils/logger.dart';
import '../widgets/dev_mode/change_password_dialog.dart';
import '../widgets/dev_mode/dev_mode_password_dialog.dart';
import 'custom_commands_view.dart';

/// Standalone developer options screen.
///
/// Previously this was a card inside the Update Settings page, which made
/// it effectively invisible to dev testers. It now lives behind a dedicated
/// AppBar popup-menu entry so it is one tap away from the scanner.
class DeveloperOptionsView extends StatefulWidget {
  const DeveloperOptionsView({super.key});

  @override
  State<DeveloperOptionsView> createState() => _DeveloperOptionsViewState();
}

class _DeveloperOptionsViewState extends State<DeveloperOptionsView> {
  late final RoleService _roleService;

  @override
  void initState() {
    super.initState();
    _roleService = getIt<RoleService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.developerMode),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<UserRole>(
        stream: _roleService.roleStream,
        initialData: _roleService.currentRole,
        builder: (context, snapshot) {
          final isDev = snapshot.data?.isDeveloper ?? false;
          return ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.developer_mode),
                title: const Text(AppStrings.developerMode),
                subtitle: Text(
                  isDev
                      ? AppStrings.developerModeEnabled
                      : AppStrings.developerModeDisabled,
                ),
                value: isDev,
                activeThumbColor: Colors.orange.shade700,
                onChanged: (value) async {
                  if (value) {
                    await DevModePasswordDialog.show(context: context);
                  } else {
                    _roleService.disableDeveloperMode();
                  }
                },
              ),
              const Divider(height: 1),
              if (isDev) ...[
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text(AppStrings.changePasswordTitle),
                  onTap: () => ChangePasswordDialog.show(context: context),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text(AppStrings.manageCustomCommands),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomCommandsView(),
                    ),
                  ),
                ),
                // Logger.diagnosticEnabled defaults to kDebugMode and had no
                // other write site, so the raw-BLE trace was unreachable in
                // the release build field engineers actually run — which is
                // why response-corruption reports could not be diagnosed.
                // In-memory only, resets on cold start (same posture as the
                // developer-mode role itself, ADR-0005).
                SwitchListTile(
                  secondary: const Icon(Icons.bug_report),
                  title: const Text(AppStrings.diagnosticLogging),
                  subtitle: const Text(AppStrings.diagnosticLoggingSubtitle),
                  value: Logger.diagnosticEnabled,
                  activeThumbColor: Colors.orange.shade700,
                  onChanged: (value) =>
                      setState(() => Logger.diagnosticEnabled = value),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
