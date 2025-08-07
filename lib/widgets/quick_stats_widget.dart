import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../models/ble_device.dart';
import '../models/connection_state.dart';
import '../services/theme_service.dart';
import '../widgets/responsive_layout.dart';

/// Widget for displaying quick statistics about BLE devices
class QuickStatsWidget extends StatelessWidget {
  final SimpleBleController controller;

  const QuickStatsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BleDeviceModel>>(
      stream: controller.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        int deviceCount = snapshot.data?.length ?? 0;
        int connectedCount = snapshot.data?.where((d) => d.connectionState == BleConnectionState.connected).length ?? 0;
        
        return ResponsiveCard(
          child: Column(
            children: [
              ResponsiveText(
                'Quick Stats',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, 'Found', deviceCount.toString(), Icons.devices),
                  _buildStatItem(context, 'Connected', connectedCount.toString(), Icons.link),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        ResponsiveIcon(
          icon,
          size: 24,
          color: AppColors.infoColor(context),
        ),
        const SizedBox(height: 8),
        ResponsiveText(
          value,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
        ),
        ResponsiveText(
          label,
          fontSize: 12,
          color: AppColors.textSecondary(context),
        ),
      ],
    );
  }
}