import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../design/design_system.dart';
import '../../models/ble_device.dart';

/// Widget for displaying BLE connection status and device information
class ConnectionStatusWidget extends StatelessWidget {
  final BleControllerInterface controller;
  final bool showDeviceInfo;
  final bool compact;

  const ConnectionStatusWidget({
    super.key,
    required this.controller,
    this.showDeviceInfo = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BleDeviceModel?>(
      stream: controller.connectedDeviceStream,
      builder: (context, snapshot) {
        final device = snapshot.data ?? controller.connectedDevice;
        return device != null 
            ? _buildConnectedStatus(context, device)
            : _buildDisconnectedStatus(context);
      },
    );
  }

  Widget _buildConnectedStatus(BuildContext context, BleDeviceModel device) {
    if (compact) {
      return _buildCompactConnectedStatus(context, device);
    }

    return Container(
      padding: DesignTokens.paddingM,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DesignTokens.borderRadiusM,
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: DesignTokens.blurRadiusM,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(context, true),
          if (showDeviceInfo) ...[
            SizedBox(height: DesignTokens.spacingSM),
            _buildDeviceInfo(context, device),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactConnectedStatus(BuildContext context, BleDeviceModel device) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.bluetooth_connected,
          color: Colors.green,
          size: ResponsiveUtils.getIconSize(context, base: 20),
        ),
        SizedBox(width: DesignTokens.spacingS),
        Text(
          'Connected',
          style: AppTextStyles.labelLarge(context).copyWith(
            color: Colors.green,
          ),
        ),
        if (showDeviceInfo) ...[
          Text(
            ' • ${device.displayName}',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: ResponsiveUtils.getFontSize(context, base: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDisconnectedStatus(BuildContext context) {
    if (compact) {
      return _buildCompactDisconnectedStatus(context);
    }

    return Container(
      padding: DesignTokens.paddingM,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: DesignTokens.borderRadiusM,
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(context, false),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Please connect a BLE device to send commands',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDisconnectedStatus(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.bluetooth_disabled,
          color: Colors.red,
          size: ResponsiveUtils.getIconSize(context, base: 20),
        ),
        SizedBox(width: DesignTokens.spacingS),
        Text(
          'Disconnected',
          style: AppTextStyles.labelLarge(context).copyWith(
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(BuildContext context, bool isConnected) {
    return Row(
      children: [
        Container(
          padding: DesignTokens.paddingS,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: DesignTokens.borderRadiusS,
          ),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.warning_rounded,
            color: isConnected ? Colors.green.shade700 : Colors.orange.shade700,
            size: ResponsiveUtils.getIconSize(context, base: 20),
          ),
        ),
        SizedBox(width: DesignTokens.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConnected ? 'Device Connected' : 'No Device Connected',
                style: AppTextStyles.titleSmall(context).copyWith(
                  color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
              Text(
                isConnected ? 'Ready to send commands' : 'Connect a device first',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo(BuildContext context, BleDeviceModel device) {
    return Container(
      padding: DesignTokens.paddingSM,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: DesignTokens.borderRadiusS,
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(context, 'Device', device.displayName),
          _buildInfoRow(context, 'ID', device.id),
          _buildInfoRow(context, 'RSSI', '${device.rssi} dBm'),
          if (device.services.isNotEmpty)
            _buildInfoRow(context, 'Services', '${device.services.length} available'),
          if (device.connectionDuration != null)
            _buildInfoRow(context, 'Connected', _formatDuration(device.connectionDuration!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS / 2),
      child: Row(
        children: [
          SizedBox(
            width: ResponsiveUtils.isDesktop(context) ? 100 : 80,
            child: Text(
              '$label:',
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontFamily: label == 'ID' ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}

/// A specialized app bar widget showing connection status
class ConnectionStatusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final BleControllerInterface controller;
  final String title;
  final List<Widget>? actions;

  const ConnectionStatusAppBar({
    super.key,
    required this.controller,
    this.title = 'Command Interface',
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        ConnectionStatusWidget(
          controller: controller,
          compact: true,
          showDeviceInfo: false,
        ),
        SizedBox(width: DesignTokens.spacingM),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}