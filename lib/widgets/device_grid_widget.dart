import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../models/ble_device.dart';
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';

/// Widget for displaying BLE devices in a responsive grid layout
class DeviceGridWidget extends StatelessWidget {
  final SimpleBleController controller;
  final Function(BleDeviceModel)? onDeviceDetails;

  const DeviceGridWidget({
    super.key,
    required this.controller,
    this.onDeviceDetails,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BleDeviceModel>>(
      stream: controller.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        List<BleDeviceModel> devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return _buildEmptyState(context);
        }

        final crossAxisCount = ResponsiveUtils.getGridColumns(context);
        
        return GridView.builder(
          padding: ResponsiveUtils.getResponsivePadding(context),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: devices.length,
          itemBuilder: (context, index) => _buildDeviceGridCard(context, devices[index]),
        );
      },
    );
  }

  Widget _buildDeviceGridCard(BuildContext context, BleDeviceModel device) {
    return StreamBuilder<BleDeviceModel?>(
      stream: controller.connectedDeviceStream,
      builder: (context, connectedSnapshot) {
        bool isConnected = connectedSnapshot.data?.id == device.id;
        
        return ResponsiveCard(
          child: InkWell(
            onTap: () => onDeviceDetails?.call(device),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveIcon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  size: 32,
                  color: isConnected 
                      ? AppColors.successColor(context)
                      : AppColors.infoColor(context),
                ),
                const SizedBox(height: 12),
                ResponsiveText(
                  device.displayName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                ResponsiveText(
                  '${device.rssi} dBm',
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isConnected 
                        ? controller.disconnectDevice
                        : () => controller.connectToDevice(device.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected 
                          ? AppColors.errorColor(context)
                          : AppColors.infoColor(context),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isConnected ? 'Disconnect' : 'Connect'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundGradientStart(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ResponsiveIcon(
              Icons.bluetooth_searching,
              size: 64,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
          ResponsiveText(
            'No BLE devices found',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            'Start scanning to discover nearby devices',
            fontSize: 14,
            color: AppColors.textSecondary(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}