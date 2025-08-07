import 'package:flutter/material.dart';
import '../models/update_preferences.dart';
import '../services/update_service.dart';
import '../services/network_service.dart';
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';

/// Settings view for managing app update preferences
class UpdateSettingsView extends StatefulWidget {
  const UpdateSettingsView({super.key});

  @override
  State<UpdateSettingsView> createState() => _UpdateSettingsViewState();
}

class _UpdateSettingsViewState extends State<UpdateSettingsView> {
  final UpdateService _updateService = UpdateService();
  final NetworkService _networkService = NetworkService();
  
  UpdatePreferences? _preferences;
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  bool _isLoading = true;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _listenToNetwork();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await UpdatePreferences.load();
      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _preferences = UpdatePreferences();
        _isLoading = false;
      });
    }
  }

  void _listenToNetwork() {
    _networkService.networkStream.listen((status) {
      if (mounted) {
        setState(() {
          _networkStatus = status;
        });
      }
    });
    _networkStatus = _networkService.currentStatus;
  }

  Future<void> _savePreferences() async {
    if (_preferences != null) {
      await _preferences!.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Settings'),
        backgroundColor: AppColors.backgroundGradientStart(context),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isCheckingUpdate ? null : _checkForUpdates,
            icon: _isCheckingUpdate
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_preferences == null) {
      return const Center(
        child: Text('Failed to load update settings'),
      );
    }

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
          horizontal: isDesktop ? 32 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNetworkStatus(),
            const SizedBox(height: 24),
            _buildUpdateCheckSettings(),
            const SizedBox(height: 24),
            _buildDownloadSettings(),
            const SizedBox(height: 24),
            _buildSkippedVersions(),
            const SizedBox(height: 24),
            _buildCurrentVersion(),
            const SizedBox(height: 24),
            _buildResetSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getNetworkStatusColor(),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getNetworkStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getNetworkStatusIcon(),
              color: _getNetworkStatusColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _networkService.getStatusDescription(),
                  style: TextStyle(
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

  Widget _buildUpdateCheckSettings() {
    return _buildSettingsSection(
      title: 'Update Checking',
      icon: Icons.update,
      children: [
        _buildSwitchTile(
          title: 'Auto Check for Updates',
          subtitle: 'Automatically check for updates when app starts',
          value: _preferences!.autoCheckEnabled,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(autoCheckEnabled: value);
            });
            _savePreferences();
          },
        ),
        _buildDropdownTile<UpdateFrequency>(
          title: 'Check Frequency',
          subtitle: 'How often to check for updates',
          value: _preferences!.updateFrequency,
          items: UpdateFrequency.values,
          onChanged: _preferences!.autoCheckEnabled
              ? (value) {
                  if (value != null) {
                    setState(() {
                      _preferences = _preferences!.copyWith(updateFrequency: value);
                    });
                    _savePreferences();
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDownloadSettings() {
    return _buildSettingsSection(
      title: 'Download Settings',
      icon: Icons.download,
      children: [
        _buildSwitchTile(
          title: 'Auto Download Updates',
          subtitle: 'Automatically download updates when found',
          value: _preferences!.autoDownloadEnabled,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(autoDownloadEnabled: value);
            });
            _savePreferences();
          },
        ),
        _buildSwitchTile(
          title: 'WiFi Only Downloads',
          subtitle: 'Only download updates when connected to WiFi',
          value: _preferences!.wifiOnlyDownload,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(wifiOnlyDownload: value);
            });
            _savePreferences();
          },
        ),
      ],
    );
  }

  Widget _buildSkippedVersions() {
    return _buildSettingsSection(
      title: 'Skipped Versions',
      icon: Icons.skip_next,
      children: [
        if (_preferences!.skippedVersions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No versions skipped',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ..._preferences!.skippedVersions.map((version) => ListTile(
                leading: const Icon(Icons.block),
                title: Text('Version $version'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _preferences!.unskipVersion(version);
                    });
                    _savePreferences();
                  },
                ),
              )),
        if (_preferences!.skippedVersions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _preferences!.clearSkippedVersions();
                });
                _savePreferences();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All'),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentVersion() {
    final versionInfo = _updateService.getCurrentVersionInfo();
    
    return _buildSettingsSection(
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

  Widget _buildResetSettings() {
    return _buildSettingsSection(
      title: 'Reset',
      icon: Icons.restore,
      children: [
        ListTile(
          title: const Text('Reset to Defaults'),
          subtitle: const Text('Reset all update settings to default values'),
          trailing: const Icon(Icons.restore),
          onTap: _showResetDialog,
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      color: AppColors.cardColor(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundGradientStart(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textPrimary(context)),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue.shade600,
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        onChanged: onChanged,
        items: items.map((item) {
          String displayName;
          if (item is UpdateFrequency) {
            displayName = item.displayName;
          } else {
            displayName = item.toString();
          }
          
          return DropdownMenuItem<T>(
            value: item,
            child: Text(displayName),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      await _updateService.checkForUpdates(showNotification: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  void _showResetDialog() {
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
              _resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _preferences = UpdatePreferences();
    });
    _savePreferences();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
      ),
    );
  }

  Color _getNetworkStatusColor() {
    switch (_networkStatus) {
      case NetworkStatus.wifi:
        return Colors.green;
      case NetworkStatus.mobile:
        return Colors.orange;
      case NetworkStatus.none:
        return Colors.red;
      case NetworkStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getNetworkStatusIcon() {
    switch (_networkStatus) {
      case NetworkStatus.wifi:
        return Icons.wifi;
      case NetworkStatus.mobile:
        return Icons.signal_cellular_4_bar;
      case NetworkStatus.none:
        return Icons.wifi_off;
      case NetworkStatus.unknown:
        return Icons.help_outline;
    }
  }
}