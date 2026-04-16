import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../l10n/app_strings.dart';
import '../../models/ble_device.dart';
import '../../services/theme_service.dart';

/// Widget displaying connected device status with TX/RX/MTU indicators.
///
/// Shows device name, ID, and communication channel status in a
/// compact, visually appealing format. Used primarily in the
/// CommandInterfaceView to display the current connection state.
class DeviceStatusPanelWidget extends StatelessWidget {
  const DeviceStatusPanelWidget({
    super.key,
    required this.controller,
    this.firmwareName,
  });

  final BleControllerInterface controller;

  /// Firmware name parsed from the last $INFO response, or null.
  final String? firmwareName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: StreamBuilder<BleDeviceModel?>(
        stream: controller.connectedDeviceStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            final currentDevice = controller.connectedDevice;

            if (currentDevice != null) {
              return _DeviceStatusContent(
                device: currentDevice,
                commandInfo: controller.getCommandInfo(),
                firmwareName: firmwareName,
              );
            }

            return const _NoDeviceWarning();
          }

          return _DeviceStatusContent(
            device: snapshot.data!,
            commandInfo: controller.getCommandInfo(),
            firmwareName: firmwareName,
          );
        },
      ),
    );
  }
}

/// Content widget showing device status when connected.
class _DeviceStatusContent extends StatelessWidget {
  const _DeviceStatusContent({
    required this.device,
    required this.commandInfo,
    this.firmwareName,
  });

  final BleDeviceModel device;
  final Map<String, dynamic> commandInfo;
  final String? firmwareName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundGradientStart(context),
            AppColors.backgroundGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DeviceHeader(device: device),
          const SizedBox(height: 12),
          _StatusChipRow(
            commandInfo: commandInfo,
            firmwareName: firmwareName,
          ),
        ],
      ),
    );
  }
}

/// Device header with icon, name, and ID.
class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.device});

  final BleDeviceModel device;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blue.shade800.withValues(alpha: 0.3)
                : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.device_hub,
            color: AppColors.infoColor(context),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                device.id,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Row of status chips showing TX, RX, MTU, and firmware name.
class _StatusChipRow extends StatelessWidget {
  const _StatusChipRow({
    required this.commandInfo,
    this.firmwareName,
  });

  final Map<String, dynamic> commandInfo;
  final String? firmwareName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StatusChip(
          label: 'TX',
          isAvailable: commandInfo['hasCommandChannel'] ?? false,
          icon: Icons.upload,
        ),
        _StatusChip(
          label: 'RX',
          isAvailable: commandInfo['hasResponseChannel'] ?? false,
          icon: Icons.download,
        ),
        _InfoChip(
          label: 'MTU',
          value: '${commandInfo['mtu']}',
          icon: Icons.data_usage,
        ),
        if (firmwareName != null)
          _InfoChip(
            label: 'FW',
            value: firmwareName!,
            icon: Icons.memory,
          ),
      ],
    );
  }
}

/// Status chip showing availability (green/red).
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isAvailable,
    required this.icon,
  });

  final String label;
  final bool isAvailable;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info chip showing a value (blue).
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '$label:$value',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning widget shown when no device is connected.
class _NoDeviceWarning extends StatelessWidget {
  const _NoDeviceWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_rounded,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.noDeviceConnected,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.pleaseConnectBleDeviceFirst,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
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
