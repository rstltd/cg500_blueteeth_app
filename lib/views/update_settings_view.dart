import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/network_service.dart';
import '../services/update_preferences_store.dart';
import '../core/view_model/view_model.dart';
import '../design/design_system.dart';
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
      : _preferencesStore = null,
        _networkService = null;

  /// Creates an UpdateSettingsView with explicit dependencies for testing.
  const UpdateSettingsView.withDependencies({
    super.key,
    required UpdatePreferencesStore preferencesStore,
    required NetworkService networkService,
  })  : _preferencesStore = preferencesStore,
        _networkService = networkService;

  final UpdatePreferencesStore? _preferencesStore;
  final NetworkService? _networkService;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<UpdateSettingsViewModel>(
      create: () => UpdateSettingsViewModel(
        preferencesStore: _preferencesStore,
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
        title: const Text(AppStrings.updateSettings),
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
            tooltip: AppStrings.checkUpdateTooltip,
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
        child: Text(AppStrings.cannotLoadUpdateSettings),
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
            _CurrentVersionCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _NetworkStatusCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _DownloadSettingsCard(viewModel: viewModel),
            SizedBox(height: DesignTokens.spacingL),
            _SkippedVersionsCard(viewModel: viewModel),
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
                  AppStrings.networkStatus,
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

class _DownloadSettingsCard extends StatelessWidget {
  const _DownloadSettingsCard({required this.viewModel});

  final UpdateSettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final prefs = viewModel.preferences!;

    return _SettingsSection(
      title: AppStrings.downloadSettings,
      icon: Icons.download,
      children: [
        SwitchListTile(
          title: const Text(AppStrings.wifiOnlyDownload),
          subtitle: const Text(AppStrings.wifiOnlyDownloadDesc),
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
      title: AppStrings.skippedVersions,
      icon: Icons.skip_next,
      children: [
        if (prefs.skippedVersions.isEmpty)
          Padding(
            padding: DesignTokens.paddingVerticalM,
            child: Text(
              AppStrings.noSkippedVersions,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...prefs.skippedVersions.map((version) => ListTile(
                leading: const Icon(Icons.block),
                title: Text(AppStrings.version(version)),
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
              label: const Text(AppStrings.clearAll),
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
      title: AppStrings.currentVersion,
      icon: Icons.info_outline,
      children: [
        ListTile(
          title: const Text(AppStrings.versionLabel),
          trailing: Text(
            versionInfo['version'] ?? AppStrings.unknown,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text(AppStrings.buildNumber),
          trailing: Text(
            versionInfo['buildNumber'] ?? AppStrings.unknown,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: const Text(AppStrings.lastCheckedLabel),
          trailing: Text(
            _formatLastChecked(viewModel.lastCheckAt),
            style: TextStyle(
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }

  /// Human-friendly relative timestamp for "last checked" row.
  /// Returns "尚未檢查" when no check has been run in the current session.
  String _formatLastChecked(DateTime? at) {
    if (at == null) return AppStrings.lastCheckedNever;
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return AppStrings.lastCheckedJustNow;
    if (diff.inHours < 1) {
      return AppStrings.lastCheckedMinutesAgo(diff.inMinutes);
    }
    return AppStrings.lastCheckedHoursAgo(diff.inHours);
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
