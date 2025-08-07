import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../models/ble_device.dart';
import '../services/theme_service.dart';
import 'animated_widgets.dart';

/// A reusable widget for displaying BLE device list
class DeviceListWidget extends StatelessWidget {
  final SimpleBleController controller;
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.bluetooth_searching,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No BLE devices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to discover nearby devices',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          StreamBuilder<bool>(
            stream: controller.scanningStream,
            initialData: false,
            builder: (context, snapshot) {
              bool isScanning = snapshot.data ?? false;
              if (isScanning) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scanning...',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isConnected 
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.green.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isConnected 
                  ? BorderSide(color: Colors.green.shade300, width: 2)
                  : BorderSide.none,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).cardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeviceHeader(context, device, isConnected),
                    const SizedBox(height: 12),
                    _buildDeviceInfo(context, device),
                    const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isConnected ? Colors.green.shade600 : Colors.blue.shade600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name.isNotEmpty ? device.name : 'Unknown Device',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                device.id,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                  fontFamily: 'monospace',
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
          const SizedBox(height: 4),
          _buildInfoRow(context, 'Services', '${device.services.length} available'),
        ],
        if (device.lastSeen != null) ...[
          const SizedBox(height: 4),
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
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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
            size: 20,
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
            size: 16,
          ),
          label: Text(
            isConnected ? 'Disconnect' : 'Connect',
            style: const TextStyle(fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isConnected ? Colors.red.shade600 : Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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