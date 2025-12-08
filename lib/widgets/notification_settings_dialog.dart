import 'package:flutter/material.dart';
import '../design/design_system.dart';
import '../services/smart_notification_service.dart';

/// Dialog for configuring notification preferences
class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  final SmartNotificationService _notificationService = SmartNotificationService();
  
  // Settings state
  bool _showConnectionNotifications = true;
  bool _showScanningNotifications = false;
  bool _showMtuNotifications = false;
  bool _showCommandNotifications = false;
  bool _enableSmartFiltering = true;
  
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
            Flexible(child: _buildContent()),
            _buildActions(),
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
                  'Notification Settings',
                  style: AppTextStyles.titleLarge(context),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  'Configure when and how notifications are shown',
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
          _buildSectionHeader('Smart Filtering', Icons.filter_alt),
          _buildSmartFilteringCard(),

          SizedBox(height: DesignTokens.spacingL),
          _buildSectionHeader('Notification Categories', Icons.category),
          _buildNotificationCategories(),

          SizedBox(height: DesignTokens.spacingL),
          _buildSectionHeader('Statistics', Icons.analytics),
          _buildStatisticsCard(),
        ],
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
          Text(
            title,
            style: AppTextStyles.titleSmall(context),
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
              title: const Text('Enable Smart Filtering'),
              subtitle: const Text('Automatically reduce notification spam and duplicates'),
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
                        'Smart filtering prevents duplicate notifications, reduces connection status spam, and silences internal operations.',
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
              'Connection Events',
              'Show notifications when devices connect/disconnect',
              _showConnectionNotifications,
              (value) => setState(() => _showConnectionNotifications = value),
              Icons.bluetooth_connected,
            ),
            const Divider(height: 24),
            _buildCategorySwitch(
              'Scanning Events',
              'Show notifications during device scanning',
              _showScanningNotifications,
              (value) => setState(() => _showScanningNotifications = value),
              Icons.radar,
            ),
            const Divider(height: 24),
            _buildCategorySwitch(
              'MTU Configuration',
              'Show notifications about MTU setup',
              _showMtuNotifications,
              (value) => setState(() => _showMtuNotifications = value),
              Icons.settings_ethernet,
            ),
            const Divider(height: 24),
            _buildCategorySwitch(
              'Command Feedback',
              'Show notifications for sent commands',
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
            _buildStatRow('Total Notifications', '${stats['total_notifications']}'),
            SizedBox(height: DesignTokens.spacingS),
            _buildStatRow('Filtered Notifications', '${stats['filtered_notifications']}'),
            SizedBox(height: DesignTokens.spacingS),
            _buildStatRow('Pending Notifications', '${stats['pending_notifications']}'),
            SizedBox(height: DesignTokens.spacingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _notificationService.clearFilters();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification filters cleared'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
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
            child: const Text('Cancel'),
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
            child: const Text('Apply Settings'),
          ),
        ],
      ),
    );
  }

  void _applySettings() {
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
    
    // Apply configuration
    _notificationService.configureSettings(
      additionalSilentOperations: silentOperations,
    );
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings applied successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    Navigator.of(context).pop();
  }
}