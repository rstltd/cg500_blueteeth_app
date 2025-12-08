import 'package:flutter/material.dart';
import '../design/design_system.dart';
import '../models/ble_device.dart';
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
              SizedBox(width: DesignTokens.spacingSM),
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
          SizedBox(height: DesignTokens.spacingSM),
          ResponsiveText(
            device.displayName,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          SizedBox(height: DesignTokens.spacingS),
          ResponsiveText(
            'RSSI: ${device.rssi} dBm',
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
          if (device.services.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingS),
            ResponsiveText(
              'Services: ${device.services.length}',
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ],
          SizedBox(height: DesignTokens.spacingM),
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