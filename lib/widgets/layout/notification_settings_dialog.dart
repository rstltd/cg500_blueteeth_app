import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../core/interfaces/ble_notification_delegate.dart';
import '../../core/service_locator.dart' show getIt;
import '../../controllers/ble_controller_interface.dart';
import '../../design/design_system.dart';
import '../../services/smart_notification_service.dart';
import '../../l10n/app_strings.dart';

/// Dialog for configuring notification preferences
class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  late final SmartNotificationService _notificationService;
  late final BleControllerInterface _bleController;

  // SharedPreferences keys
  static const String _keyShowConnection = 'notification_show_connection';
  static const String _keyShowScanning = 'notification_show_scanning';
  static const String _keyShowMtu = 'notification_show_mtu';
  static const String _keyShowCommand = 'notification_show_command';
  static const String _keySmartFiltering = 'notification_smart_filtering';

  // Settings state
  bool _showConnectionNotifications = true;
  bool _showScanningNotifications = false;
  bool _showMtuNotifications = false;
  bool _showCommandNotifications = false;
  bool _enableSmartFiltering = true;
  bool _isLoading = true;
  BleNotificationVerbosity _bleVerbosity = BleNotificationVerbosity.minimal;

  @override
  void initState() {
    super.initState();
    // Get the singleton instances from service locator
    _notificationService = getIt<NotificationService>() as SmartNotificationService;
    _bleController = getIt<BleControllerInterface>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showConnectionNotifications = prefs.getBool(_keyShowConnection) ?? true;
        _showScanningNotifications = prefs.getBool(_keyShowScanning) ?? false;
        _showMtuNotifications = prefs.getBool(_keyShowMtu) ?? false;
        _showCommandNotifications = prefs.getBool(_keyShowCommand) ?? false;
        _enableSmartFiltering = prefs.getBool(_keySmartFiltering) ?? true;
        // Load BLE notification verbosity from preferences or controller
        final savedVerbosity = prefs.getInt(bleNotificationVerbosityKey);
        if (savedVerbosity != null && savedVerbosity < BleNotificationVerbosity.values.length) {
          _bleVerbosity = BleNotificationVerbosity.values[savedVerbosity];
        } else {
          _bleVerbosity = _bleController.notificationVerbosity ?? BleNotificationVerbosity.minimal;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowConnection, _showConnectionNotifications);
    await prefs.setBool(_keyShowScanning, _showScanningNotifications);
    await prefs.setBool(_keyShowMtu, _showMtuNotifications);
    await prefs.setBool(_keyShowCommand, _showCommandNotifications);
    await prefs.setBool(_keySmartFiltering, _enableSmartFiltering);
    await prefs.setInt(bleNotificationVerbosityKey, _bleVerbosity.index);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: DesignTokens.borderRadiusL,
          boxShadow: DesignTokens.elevatedShadow(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _isLoading ? _buildLoadingIndicator() : _buildContent()),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: DesignTokens.paddingXL,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.infoColor(context),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              AppStrings.loadingSettings,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: DesignTokens.paddingML,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundGradientStart(context),
            AppColors.backgroundGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusL),
          topRight: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: DesignTokens.paddingSM,
            decoration: BoxDecoration(
              color: AppColors.infoColor(context).withValues(alpha: 0.2),
              borderRadius: DesignTokens.borderRadiusM,
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.infoColor(context),
              size: DesignTokens.iconM,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.notificationSettings,
                  style: AppTextStyles.titleLarge(context),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  AppStrings.notificationSettingsSubtitle,
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: DesignTokens.paddingML,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(AppStrings.notificationLevel, Icons.notifications),
          _buildBleVerbosityCard(),

          SizedBox(height: DesignTokens.spacingL),
          _buildSectionHeader(AppStrings.smartFiltering, Icons.filter_alt),
          _buildSmartFilteringCard(),

          SizedBox(height: DesignTokens.spacingL),
          _buildSectionHeader(AppStrings.notificationCategories, Icons.category),
          _buildNotificationCategories(),

          SizedBox(height: DesignTokens.spacingL),
          _buildSectionHeader(AppStrings.statistics, Icons.analytics),
          _buildStatisticsCard(),
        ],
      ),
    );
  }

  Widget _buildBleVerbosityCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusM,
        side: BorderSide(
          color: AppColors.borderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: DesignTokens.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.controlBleNotifications,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildBleVerbosityOption(
              BleNotificationVerbosity.minimal,
              AppStrings.errorsOnly,
              AppStrings.errorsOnlyDesc,
              Icons.error_outline,
              AppColors.errorColor(context),
            ),
            _buildBleVerbosityOption(
              BleNotificationVerbosity.normal,
              AppStrings.errorsAndWarnings,
              AppStrings.errorsAndWarningsDesc,
              Icons.warning_amber,
              AppColors.warningColor(context),
            ),
            _buildBleVerbosityOption(
              BleNotificationVerbosity.verbose,
              AppStrings.allDetails,
              AppStrings.allDetailsDesc,
              Icons.notifications_active,
              AppColors.infoColor(context),
            ),
            _buildBleVerbosityOption(
              BleNotificationVerbosity.silent,
              AppStrings.silent,
              AppStrings.silentDesc,
              Icons.notifications_off,
              AppColors.neutralColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBleVerbosityOption(
    BleNotificationVerbosity verbosity,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _bleVerbosity == verbosity;
    return InkWell(
      onTap: () => setState(() => _bleVerbosity = verbosity),
      borderRadius: DesignTokens.borderRadiusS,
      child: Container(
        padding: DesignTokens.paddingSM,
        margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: DesignTokens.borderRadiusS,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: DesignTokens.paddingS,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: DesignTokens.borderRadiusS,
              ),
              child: Icon(icon, size: DesignTokens.iconS, color: color),
            ),
            SizedBox(width: DesignTokens.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge(context).copyWith(
                      color: isSelected ? color : AppColors.textPrimary(context),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: DesignTokens.iconM),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingSM),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconS,
            color: AppColors.textSecondary(context),
          ),
          SizedBox(width: DesignTokens.spacingS),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.titleSmall(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFilteringCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusM,
        side: BorderSide(
          color: AppColors.borderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: DesignTokens.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text(AppStrings.enableSmartFiltering),
              subtitle: const Text(AppStrings.smartFilteringDesc),
              value: _enableSmartFiltering,
              onChanged: (value) {
                setState(() {
                  _enableSmartFiltering = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_enableSmartFiltering) ...[
              SizedBox(height: DesignTokens.spacingSM),
              Container(
                padding: DesignTokens.paddingSM,
                decoration: BoxDecoration(
                  color: AppColors.infoContainer(context),
                  borderRadius: DesignTokens.borderRadiusS,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.onInfoContainer(context),
                      size: DesignTokens.iconS,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        AppStrings.smartFilteringExplanation,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.onInfoContainer(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCategories() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusM,
        side: BorderSide(
          color: AppColors.borderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: DesignTokens.paddingM,
        child: Column(
          children: [
            _buildCategorySwitch(
              AppStrings.connectionEvents,
              AppStrings.connectionEventsDesc,
              _showConnectionNotifications,
              (value) => setState(() => _showConnectionNotifications = value),
              Icons.bluetooth_connected,
            ),
            const Divider(height: 24),
            _buildCategorySwitch(
              AppStrings.scanningEvents,
              AppStrings.scanningEventsDesc,
              _showScanningNotifications,
              (value) => setState(() => _showScanningNotifications = value),
              Icons.radar,
            ),
            const Divider(height: 24),
            _buildCategorySwitch(
              AppStrings.mtuConfigurationCategory,
              AppStrings.mtuConfiguration,
              _showMtuNotifications,
              (value) => setState(() => _showMtuNotifications = value),
              Icons.settings_ethernet,
            ),
            const Divider(height: 24),
            _buildCategorySwitch(
              AppStrings.commandFeedback,
              AppStrings.commandFeedbackDesc,
              _showCommandNotifications,
              (value) => setState(() => _showCommandNotifications = value),
              Icons.send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: DesignTokens.paddingS,
          decoration: BoxDecoration(
            color: AppColors.backgroundGradientStart(context),
            borderRadius: DesignTokens.borderRadiusS,
          ),
          child: Icon(
            icon,
            size: DesignTokens.iconS,
            color: AppColors.infoColor(context),
          ),
        ),
        SizedBox(width: DesignTokens.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge(context),
              ),
              SizedBox(height: DesignTokens.spacingXS / 2), // 2dp
              Text(
                subtitle,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _notificationService.getStatistics();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusM,
        side: BorderSide(
          color: AppColors.borderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: DesignTokens.paddingM,
        child: Column(
          children: [
            _buildStatRow(AppStrings.totalNotifications, '${stats['total_notifications']}'),
            SizedBox(height: DesignTokens.spacingS),
            _buildStatRow(AppStrings.filteredNotifications, '${stats['filtered_notifications']}'),
            SizedBox(height: DesignTokens.spacingS),
            _buildStatRow(AppStrings.pendingNotifications, '${stats['pending_notifications']}'),
            SizedBox(height: DesignTokens.spacingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _notificationService.clearFilters();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.notificationFiltersCleared),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text(AppStrings.clearFilters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(context),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium(context),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: DesignTokens.paddingML,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          SizedBox(width: DesignTokens.spacingSM),
          ElevatedButton(
            onPressed: _applySettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoColor(context),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingL,
                vertical: DesignTokens.spacingSM,
              ),
            ),
            child: const Text(AppStrings.applySettings),
          ),
        ],
      ),
    );
  }

  Future<void> _applySettings() async {
    // Save settings to SharedPreferences first
    await _saveSettings();

    // Apply BLE notification verbosity to the controller immediately
    _bleController.setNotificationVerbosity(_bleVerbosity);

    // Configure the notification service based on settings
    final Set<String> silentOperations = {};

    if (!_showMtuNotifications) {
      silentOperations.addAll(['MTU Configured', 'MTU Warning']);
    }

    if (!_showCommandNotifications) {
      silentOperations.add('Command Sent');
    }

    if (!_showScanningNotifications) {
      silentOperations.addAll(['Scan Started', 'Scan Stopped']);
    }

    // Apply configuration to the singleton service
    _notificationService.configureSettings(
      additionalSilentOperations: silentOperations,
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.notificationSettingsSaved),
          backgroundColor: AppColors.successColor(context),
          duration: const Duration(seconds: 2),
        ),
      );

      // Return true to indicate settings were changed
      Navigator.of(context).pop(true);
    }
  }
}

/// Show the notification settings dialog and return true if settings were changed.
Future<bool> showNotificationSettingsDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => const NotificationSettingsDialog(),
  );
  return result ?? false;
}