import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../design/design_system.dart';
import '../../models/ble_device.dart';

/// Widget for displaying BLE devices in a responsive grid layout
class DeviceGridWidget extends StatelessWidget {
  final BleControllerInterface controller;
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
            crossAxisSpacing: DesignTokens.spacingM,
            mainAxisSpacing: DesignTokens.spacingM,
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
            borderRadius: DesignTokens.borderRadiusL,
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
                SizedBox(height: DesignTokens.spacingSM),
                ResponsiveText(
                  device.displayName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: DesignTokens.spacingS),
                ResponsiveText(
                  '${device.rssi} dBm',
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
                SizedBox(height: DesignTokens.spacingSM),
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
                      foregroundColor: AppColors.onPrimaryColor(context),
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
            padding: DesignTokens.paddingL,
            decoration: BoxDecoration(
              color: AppColors.backgroundGradientStart(context),
              borderRadius: DesignTokens.borderRadiusXL,
            ),
            child: ResponsiveIcon(
              Icons.bluetooth_searching,
              size: 64,
              color: AppColors.textSecondary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),
          ResponsiveText(
            'No BLE devices found',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          SizedBox(height: DesignTokens.spacingS),
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