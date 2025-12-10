import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';
import '../../models/ble_device.dart';
import '../../models/connection_state.dart';

/// Widget for displaying quick statistics about BLE devices
class QuickStatsWidget extends StatelessWidget {
  final BleControllerInterface controller;

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
                AppStrings.quickStats,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
              SizedBox(height: DesignTokens.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, AppStrings.found, deviceCount.toString(), Icons.devices),
                  _buildStatItem(context, AppStrings.connected, connectedCount.toString(), Icons.link),
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
        SizedBox(height: DesignTokens.spacingS),
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