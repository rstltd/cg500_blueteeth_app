import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/update_service.dart';
import '../core/view_model/view_model.dart';
import '../design/design_system.dart';
import '../models/update_preferences.dart';
import '../utils/formatting_utils.dart';
import '../view_models/update_settings_view_model.dart';

/// Update Settings View using ViewModelProvider pattern.
///
/// Uses the ViewModelProvider pattern for better separation of concerns.
///
/// Key features:
/// - State management via UpdateSettingsViewModel
/// - Automatic subscription lifecycle management
/// - Clean, testable code structure
class UpdateSettingsView extends StatelessWidget {
  /// Creates an UpdateSettingsView using the service locator.
  const UpdateSettingsView({super.key})
      : _updateService = null,
        _networkService = null;

  /// Creates an UpdateSettingsView with explicit dependencies for testing.
  const UpdateSettingsView.withDependencies({
    super.key,
    required UpdateService updateService,
    required NetworkService networkService,
  })  : _updateService = updateService,
        _networkService = networkService;

  final UpdateService? _updateService;
  final NetworkService? _networkService;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<UpdateSettingsViewModel>(
      create: () => UpdateSettingsViewModel(
        updateService: _updateService,
        networkService: _networkService,
      ),
      builder: (context, viewModel, child) {
        return _UpdateSettingsContent(viewModel: viewModel);
      },
    );
  }
}

/// The main content widget that uses the ViewModel.
class _UpdateSettingsContent extends StatelessWidget {
  const _UpdateSettingsContent({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Settings'),
        backgroundColor: AppColors.backgroundGradientStart(context),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: viewModel.isCheckingUpdate ? null : viewModel.checkForUpdates,
            icon: viewModel.isCheckingUpdate
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Check for Updates',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Show loading state
    if (!viewModel.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (!viewModel.hasPreferences) {
      return const Center(
        child: Text('Failed to load update settings'),
      );
    }

    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGradientStart(context),
            AppColors.backgroundGradientEnd(context),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? DesignTokens.spacingXL : DesignTokens.spacingM,
          vertical: DesignTokens.spacingM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NetworkStatusCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _UpdateCheckSettingsCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _DownloadSettingsCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _SkippedVersionsCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _CurrentVersionCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _ResetSettingsCard(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}

// --- Card Widgets ---

class _NetworkStatusCard extends StatelessWidget {
  const _NetworkStatusCard({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final statusColor = FormattingUtils.getNetworkStatusColor(viewModel.networkStatus);
    final statusIcon = FormattingUtils.getNetworkStatusIcon(viewModel.networkStatus);

    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      padding: DesignTokens.paddingM,
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: DesignTokens.borderRadiusM,
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: DesignTokens.paddingS,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: DesignTokens.borderRadiusS,
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: DesignTokens.iconM,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Status',
                  style: AppTextStyles.titleSmall(context),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  viewModel.networkStatusDescription,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateCheckSettingsCard extends StatelessWidget {
  const _UpdateCheckSettingsCard({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final prefs = viewModel.preferences!;

    return _SettingsSection(
      title: 'Update Checking',
      icon: Icons.update,
      children: [
        SwitchListTile(
          title: const Text('Auto Check for Updates'),
          subtitle: const Text('Automatically check for updates when app starts'),
          value: prefs.autoCheckEnabled,
          onChanged: viewModel.setAutoCheckEnabled,
          activeColor: Colors.blue.shade600,
        ),
        ListTile(
          title: const Text('Check Frequency'),
          subtitle: const Text('How often to check for updates'),
          trailing: DropdownButton<UpdateFrequency>(
            value: prefs.updateFrequency,
            onChanged: prefs.autoCheckEnabled
                ? (value) {
                    if (value != null) {
                      viewModel.setUpdateFrequency(value);
                    }
                  }
                : null,
            items: UpdateFrequency.values.map((item) {
              return DropdownMenuItem<UpdateFrequency>(
                value: item,
                child: Text(item.displayName),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DownloadSettingsCard extends StatelessWidget {
  const _DownloadSettingsCard({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final prefs = viewModel.preferences!;

    return _SettingsSection(
      title: 'Download Settings',
      icon: Icons.download,
      children: [
        SwitchListTile(
          title: const Text('Auto Download Updates'),
          subtitle: const Text('Automatically download updates when found'),
          value: prefs.autoDownloadEnabled,
          onChanged: viewModel.setAutoDownloadEnabled,
          activeColor: Colors.blue.shade600,
        ),
        SwitchListTile(
          title: const Text('WiFi Only Downloads'),
          subtitle: const Text('Only download updates when connected to WiFi'),
          value: prefs.wifiOnlyDownload,
          onChanged: viewModel.setWifiOnlyDownload,
          activeColor: Colors.blue.shade600,
        ),
      ],
    );
  }
}

class _SkippedVersionsCard extends StatelessWidget {
  const _SkippedVersionsCard({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final prefs = viewModel.preferences!;

    return _SettingsSection(
      title: 'Skipped Versions',
      icon: Icons.skip_next,
      children: [
        if (prefs.skippedVersions.isEmpty)
          Padding(
            padding: DesignTokens.paddingVerticalM,
            child: Text(
              'No versions skipped',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...prefs.skippedVersions.map((version) => ListTile(
                leading: const Icon(Icons.block),
                title: Text('Version $version'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => viewModel.unskipVersion(version),
                ),
              )),
        if (prefs.skippedVersions.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: DesignTokens.spacingS),
            child: TextButton.icon(
              onPressed: viewModel.clearSkippedVersions,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All'),
            ),
          ),
      ],
    );
  }
}

class _CurrentVersionCard extends StatelessWidget {
  const _CurrentVersionCard({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final versionInfo = viewModel.currentVersionInfo;

    return _SettingsSection(
      title: 'Current Version',
      icon: Icons.info_outline,
      children: [
        ListTile(
          title: const Text('Version'),
          trailing: Text(
            versionInfo['version'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text('Build Number'),
          trailing: Text(
            versionInfo['buildNumber'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ResetSettingsCard extends StatelessWidget {
  const _ResetSettingsCard({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Reset',
      icon: Icons.restore,
      children: [
        ListTile(
          title: const Text('Reset to Defaults'),
          subtitle: const Text('Reset all update settings to default values'),
          trailing: const Icon(Icons.restore),
          onTap: () => _showResetDialog(context),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all update settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DesignTokens.elevationM,
      color: AppColors.cardColor(context),
      child: Column(
        children: [
          Container(
            padding: DesignTokens.paddingM,
            decoration: BoxDecoration(
              color: AppColors.backgroundGradientStart(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusM),
                topRight: Radius.circular(DesignTokens.radiusM),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textPrimary(context)),
                SizedBox(width: DesignTokens.spacingM),
                Text(
                  title,
                  style: AppTextStyles.titleMedium(context),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
