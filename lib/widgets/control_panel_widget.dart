import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../design/design_system.dart';
import '../models/ble_device.dart';
import '../widgets/animated_widgets.dart';

/// Widget for BLE scanning control panel with device count display
class ControlPanelWidget extends StatelessWidget {
  final BleControllerInterface controller;

  const ControlPanelWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: DesignTokens.paddingM,
      padding: EdgeInsets.all(DesignTokens.spacingL - 4), // 20dp
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundGradientStart(context),
            AppColors.backgroundGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DesignTokens.borderRadiusL,
        boxShadow: DesignTokens.cardShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StreamBuilder<bool>(
                  stream: controller.scanningStream,
                  initialData: false,
                  builder: (context, snapshot) {
                    bool isScanning = snapshot.data ?? false;
                    return AnimatedScanButton(
                      isScanning: isScanning,
                      onPressed: isScanning 
                          ? controller.stopScanning 
                          : controller.startScanning,
                      text: 'Start Scanning',
                      scanningText: 'Stop Scanning',
                    );
                  },
                ),
              ),
              SizedBox(width: DesignTokens.spacingM - 4), // 12dp
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: DesignTokens.borderRadiusM,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  onPressed: controller.clearDevices,
                  icon: Icon(Icons.clear_all, color: Colors.grey.shade700),
                  tooltip: 'Clear Devices',
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM - 4), // 12dp
          _buildDeviceCount(),
        ],
      ),
    );
  }

  Widget _buildDeviceCount() {
    return StreamBuilder<List<BleDeviceModel>>(
      stream: controller.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        int deviceCount = snapshot.data?.length ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, color: Colors.grey.shade600, size: DesignTokens.iconXS),
            SizedBox(width: DesignTokens.spacingXS + 2), // 6dp
            Text(
              '$deviceCount devices found',
              style: AppTextStyles.labelLarge(context).copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      },
    );
  }
}