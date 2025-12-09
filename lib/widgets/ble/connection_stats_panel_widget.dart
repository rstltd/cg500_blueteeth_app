import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../controllers/command_manager.dart';
import '../../models/ble_device.dart';
import '../../utils/formatting_utils.dart';
import '../layout/responsive_layout.dart';

/// A widget that displays connection statistics for a BLE device.
///
/// Shows device name, signal strength, services count, MTU size,
/// messages sent, and connection duration.
///
/// This widget is primarily designed for desktop layouts where
/// there is more screen real estate to display detailed stats.
class ConnectionStatsPanelWidget extends StatelessWidget {
  const ConnectionStatsPanelWidget({
    super.key,
    required this.controller,
    required this.commandManager,
  });

  /// The BLE controller to get device and connection info from.
  final BleControllerInterface controller;

  /// The command manager to get message history from.
  final CommandManager commandManager;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BleDeviceModel?>(
      stream: controller.connectedDeviceStream,
      initialData: controller.connectedDevice,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final device = snapshot.data!;
        final commandInfo = controller.getCommandInfo();

        return ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _StatRow(
                label: 'Device Name',
                value: device.displayName,
              ),
              _StatRow(
                label: 'Signal Strength',
                value: '${device.rssi} dBm',
              ),
              _StatRow(
                label: 'Services',
                value: '${device.services.length}',
              ),
              _StatRow(
                label: 'MTU Size',
                value: '${commandInfo['mtu']} bytes',
              ),
              _StatRow(
                label: 'Messages Sent',
                value: '${commandManager.commandHistory.length}',
              ),
              if (device.connectionDuration != null)
                _StatRow(
                  label: 'Connected For',
                  value: FormattingUtils.formatDuration(device.connectionDuration!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        ResponsiveText(
          'Connection Stats',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
        ),
      ],
    );
  }
}

/// A single row displaying a label-value pair in the stats panel.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ResponsiveText(
              label,
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          ResponsiveText(
            value,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ],
      ),
    );
  }
}
