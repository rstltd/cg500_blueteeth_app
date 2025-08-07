import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../models/ble_device.dart';
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';

/// Widget for displaying BLE connection status and device information
class ConnectionStatusWidget extends StatelessWidget {
  final SimpleBleController controller;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(context, true),
          if (showDeviceInfo) ...[
            const SizedBox(height: 12),
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
        const SizedBox(width: 8),
        Text(
          'Connected',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getFontSize(context, base: 14),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(context, false),
          const SizedBox(height: 8),
          Text(
            'Please connect a BLE device to send commands',
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, base: 14),
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
        const SizedBox(width: 8),
        Text(
          'Disconnected',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getFontSize(context, base: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(BuildContext context, bool isConnected) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.warning_rounded,
            color: isConnected ? Colors.green.shade700 : Colors.orange.shade700,
            size: ResponsiveUtils.getIconSize(context, base: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConnected ? 'Device Connected' : 'No Device Connected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getFontSize(context, base: 16),
                  color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
              Text(
                isConnected ? 'Ready to send commands' : 'Connect a device first',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, base: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: ResponsiveUtils.isDesktop(context) ? 100 : 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveUtils.getFontSize(context, base: 12),
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, base: 12),
                color: AppColors.textPrimary(context),
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
  final SimpleBleController controller;
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
        const SizedBox(width: 16),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}