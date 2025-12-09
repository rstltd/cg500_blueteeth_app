import 'package:flutter/material.dart';
import '../../models/ble_device.dart';
import '../../models/connection_state.dart';
import '../../utils/formatting_utils.dart';

/// Dialog displaying detailed information about a BLE device.
///
/// Shows device name, ID, signal strength, connection state, services,
/// and timing information in a scrollable alert dialog.
class DeviceDetailsDialog extends StatelessWidget {
  const DeviceDetailsDialog({
    super.key,
    required this.device,
  });

  final BleDeviceModel device;

  /// Shows the device details dialog.
  static void show(BuildContext context, BleDeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => DeviceDetailsDialog(device: device),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(device.displayName),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(label: 'Device ID', value: device.id),
            _InfoRow(
              label: 'Name',
              value: device.name.isNotEmpty ? device.name : 'Unknown',
            ),
            _InfoRow(
              label: 'RSSI',
              value: '${device.rssi} dBm (${device.rssiDescription})',
            ),
            _InfoRow(
              label: 'Connection',
              value: device.connectionState.displayName,
            ),
            if (device.lastSeen != null)
              _InfoRow(
                label: 'Last Seen',
                value: FormattingUtils.formatDateTime(device.lastSeen!),
              ),
            if (device.connectedAt != null)
              _InfoRow(
                label: 'Connected At',
                value: FormattingUtils.formatDateTime(device.connectedAt!),
              ),
            if (device.connectionDuration != null)
              _InfoRow(
                label: 'Duration',
                value: FormattingUtils.formatDuration(device.connectionDuration!),
              ),
            _InfoRow(
              label: 'Services',
              value: '${device.services.length}',
            ),
            if (device.services.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Services:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...device.services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${service.displayName}'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Widget displaying a label-value pair row.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Reusable info row widget for external use.
/// Same as _InfoRow but public for use in other widgets.
class InfoRowWidget extends StatelessWidget {
  const InfoRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 100,
  });

  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
