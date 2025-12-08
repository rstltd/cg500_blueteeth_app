import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../design/design_system.dart';
import '../models/ble_device.dart';
import 'animated_widgets.dart';

/// A reusable widget for displaying BLE device list
class DeviceListWidget extends StatelessWidget {
  final BleControllerInterface controller;
  final Function(BleDeviceModel)? onDeviceConnect;
  final Function(BleDeviceModel)? onDeviceDisconnect;
  final Function(BleDeviceModel)? onDeviceFavorite;

  const DeviceListWidget({
    super.key,
    required this.controller,
    this.onDeviceConnect,
    this.onDeviceDisconnect,
    this.onDeviceFavorite,
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

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) => AnimatedListItem(
            index: index,
            child: _buildDeviceCard(context, devices[index]),
          ),
        );
      },
    );
  }

  /// Build empty state when no devices are found
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: DesignTokens.paddingL,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: DesignTokens.borderRadiusXL,
            ),
            child: Icon(
              Icons.bluetooth_searching,
              size: DesignTokens.iconHero,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'No BLE devices found',
            style: AppTextStyles.titleMedium(context).copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Start scanning to discover nearby devices',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingL),
          StreamBuilder<bool>(
            stream: controller.scanningStream,
            initialData: false,
            builder: (context, snapshot) {
              bool isScanning = snapshot.data ?? false;
              if (isScanning) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingL - 4, // 20dp
                    vertical: DesignTokens.spacingM - 4, // 12dp
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: DesignTokens.iconXS,
                        height: DesignTokens.iconXS,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Scanning...',
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// Build individual device card
  Widget _buildDeviceCard(BuildContext context, BleDeviceModel device) {
    return StreamBuilder<BleDeviceModel?>(
      stream: controller.connectedDeviceStream,
      builder: (context, connectedSnapshot) {
        bool isConnected = connectedSnapshot.data?.id == device.id;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingXS + 2, // 6dp
          ),
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusL,
            gradient: isConnected
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.green.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: DesignTokens.cardShadow(context),
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusL,
              side: isConnected
                  ? BorderSide(color: Colors.green.shade300, width: 2)
                  : BorderSide.none,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: DesignTokens.borderRadiusL,
                color: Theme.of(context).cardColor,
              ),
              child: Padding(
                padding: DesignTokens.paddingM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeviceHeader(context, device, isConnected),
                    SizedBox(height: DesignTokens.spacingM - 4), // 12dp
                    _buildDeviceInfo(context, device),
                    SizedBox(height: DesignTokens.spacingM),
                    _buildDeviceActions(context, device, isConnected),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build device card header with name and signal strength
  Widget _buildDeviceHeader(BuildContext context, BleDeviceModel device, bool isConnected) {
    return Row(
      children: [
        Container(
          padding: DesignTokens.paddingS,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade100 : Colors.blue.shade100,
            borderRadius: DesignTokens.borderRadiusS,
          ),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isConnected ? Colors.green.shade600 : Colors.blue.shade600,
            size: DesignTokens.iconS,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM - 4), // 12dp
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name.isNotEmpty ? device.name : 'Unknown Device',
                style: AppTextStyles.titleSmall(context),
              ),
              SizedBox(height: DesignTokens.spacingXS / 2), // 2dp
              Text(
                device.id,
                style: AppTextStyles.monospace(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        _buildSignalStrengthIndicator(context, device),
      ],
    );
  }

  /// Build device information section
  Widget _buildDeviceInfo(BuildContext context, BleDeviceModel device) {
    return Column(
      children: [
        _buildInfoRow(context, 'RSSI', '${device.rssi} dBm'),
        if (device.services.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spacingXS),
          _buildInfoRow(context, 'Services', '${device.services.length} available'),
        ],
        if (device.lastSeen != null) ...[
          SizedBox(height: DesignTokens.spacingXS),
          _buildInfoRow(context, 'Last Seen', _formatLastSeen(device.lastSeen!)),
        ],
      ],
    );
  }

  /// Build info row helper
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(context),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium(context),
        ),
      ],
    );
  }

  /// Build signal strength indicator
  Widget _buildSignalStrengthIndicator(BuildContext context, BleDeviceModel device) {
    Color getSignalColor(int rssi) {
      if (rssi >= -40) return Colors.green;
      if (rssi >= -55) return Colors.lightGreen;
      if (rssi >= -70) return Colors.orange;
      if (rssi >= -85) return Colors.red;
      return Colors.red.shade700;
    }
    
    int getSignalBars(int rssi) {
      if (rssi >= -40) return 4;
      if (rssi >= -55) return 3;
      if (rssi >= -70) return 2;
      if (rssi >= -85) return 1;
      return 0;
    }

    final color = getSignalColor(device.rssi);
    final bars = getSignalBars(device.rssi);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: 8 + (index * 3),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index < bars ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  /// Build device action buttons
  Widget _buildDeviceActions(BuildContext context, BleDeviceModel device, bool isConnected) {
    return Row(
      children: [
        // Favorite button
        IconButton(
          onPressed: () => onDeviceFavorite?.call(device),
          icon: Icon(
            device.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: device.isFavorite ? Colors.red : Colors.grey,
            size: DesignTokens.iconS,
          ),
          tooltip: device.isFavorite ? 'Remove from favorites' : 'Add to favorites',
        ),

        const Spacer(),

        // Connect/Disconnect button
        ElevatedButton.icon(
          onPressed: () {
            if (isConnected) {
              onDeviceDisconnect?.call(device);
            } else {
              onDeviceConnect?.call(device);
            }
          },
          icon: Icon(
            isConnected ? Icons.link_off : Icons.link,
            size: DesignTokens.iconXS,
          ),
          label: Text(
            isConnected ? 'Disconnect' : 'Connect',
            style: AppTextStyles.buttonSmall(context).copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isConnected ? Colors.red.shade600 : Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM - 4, // 12dp
              vertical: DesignTokens.spacingS,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusS,
            ),
          ),
        ),
      ],
    );
  }

  /// Format last seen time
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}