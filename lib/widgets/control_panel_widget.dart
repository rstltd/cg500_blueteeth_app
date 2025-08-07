import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../models/ble_device.dart';
import '../services/theme_service.dart';
import '../widgets/animated_widgets.dart';

/// Widget for BLE scanning control panel with device count display
class ControlPanelWidget extends StatelessWidget {
  final SimpleBleController controller;

  const ControlPanelWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundGradientStart(context),
            AppColors.backgroundGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 12),
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
            Icon(Icons.devices, color: Colors.grey.shade600, size: 16),
            const SizedBox(width: 6),
            Text(
              '$deviceCount devices found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}