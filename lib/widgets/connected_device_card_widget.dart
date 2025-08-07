import 'package:flutter/material.dart';
import '../models/ble_device.dart';
import '../services/theme_service.dart';
import '../widgets/responsive_layout.dart';
import '../views/command_interface_view.dart';

/// Widget for displaying connected device information in a card format
class ConnectedDeviceCardWidget extends StatelessWidget {
  final BleDeviceModel device;

  const ConnectedDeviceCardWidget({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ResponsiveIcon(
                Icons.bluetooth_connected,
                size: 24,
                color: AppColors.successColor(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResponsiveText(
                  'Connected',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.successColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResponsiveText(
            device.displayName,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            'RSSI: ${device.rssi} dBm',
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
          if (device.services.isNotEmpty) ...[
            const SizedBox(height: 8),
            ResponsiveText(
              'Services: ${device.services.length}',
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CommandInterfaceView(),
                ),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Open Command Interface'),
            ),
          ),
        ],
      ),
    );
  }
}