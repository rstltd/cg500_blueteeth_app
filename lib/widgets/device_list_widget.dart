import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../design/design_system.dart';
import '../models/ble_device.dart';
import 'animated_widgets.dart';

/// A reusable widget for displaying BLE device list with animations.
///
/// Features:
/// - Animated entrance for list items
/// - Pulse animation for newly discovered devices
/// - Animated signal strength indicators
/// - Search filtering support
class DeviceListWidget extends StatefulWidget {
  final BleControllerInterface controller;
  final Function(BleDeviceModel)? onDeviceConnect;
  final Function(BleDeviceModel)? onDeviceDisconnect;
  final Function(BleDeviceModel)? onDeviceFavorite;
  final String searchQuery;

  /// Duration to consider a device as "new" (for pulse animation)
  final Duration newDeviceThreshold;

  const DeviceListWidget({
    super.key,
    required this.controller,
    this.onDeviceConnect,
    this.onDeviceDisconnect,
    this.onDeviceFavorite,
    this.searchQuery = '',
    this.newDeviceThreshold = const Duration(seconds: 3),
  });

  @override
  State<DeviceListWidget> createState() => _DeviceListWidgetState();
}

class _DeviceListWidgetState extends State<DeviceListWidget> {
  /// Set of device IDs that have been seen before (to track "new" devices)
  final Set<String> _seenDeviceIds = {};

  /// Map of device IDs to their first seen time
  final Map<String, DateTime> _deviceFirstSeenTime = {};

  /// Check if a device is considered "new" for animation purposes
  bool _isNewDevice(BleDeviceModel device) {
    final firstSeen = _deviceFirstSeenTime[device.id];
    if (firstSeen == null) return false;

    final now = DateTime.now();
    return now.difference(firstSeen) < widget.newDeviceThreshold;
  }

  /// Track a device as seen
  void _trackDevice(BleDeviceModel device) {
    if (!_seenDeviceIds.contains(device.id)) {
      _seenDeviceIds.add(device.id);
      _deviceFirstSeenTime[device.id] = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BleDeviceModel>>(
      stream: widget.controller.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        List<BleDeviceModel> allDevices = snapshot.data ?? [];

        // Track all devices for "new" detection
        for (final device in allDevices) {
          _trackDevice(device);
        }

        // Apply search filter
        List<BleDeviceModel> devices = _filterDevices(allDevices);

        if (allDevices.isEmpty) {
          return _buildEmptyState(context);
        }

        if (devices.isEmpty && widget.searchQuery.isNotEmpty) {
          return _buildNoSearchResultsState(context, allDevices.length);
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            final isNew = _isNewDevice(device);

            return AnimatedListItem(
              index: index,
              child: NewDevicePulseAnimation(
                isNew: isNew,
                child: _buildDeviceCard(context, device),
              ),
            );
          },
        );
      },
    );
  }

  /// Filter devices based on search query.
  List<BleDeviceModel> _filterDevices(List<BleDeviceModel> devices) {
    if (widget.searchQuery.isEmpty) return devices;

    final lowerQuery = widget.searchQuery.toLowerCase();
    return devices.where((device) {
      final name = device.displayName.toLowerCase();
      final id = device.id.toLowerCase();
      return name.contains(lowerQuery) || id.contains(lowerQuery);
    }).toList();
  }

  /// Build state when search has no results.
  Widget _buildNoSearchResultsState(BuildContext context, int totalDevices) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: DesignTokens.paddingL,
            decoration: BoxDecoration(
              color: AppColors.neutralContainer(context),
              borderRadius: DesignTokens.borderRadiusXL,
            ),
            child: Icon(
              Icons.search_off,
              size: DesignTokens.iconHero,
              color: AppColors.textTertiary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'No devices match "${widget.searchQuery}"',
            style: AppTextStyles.titleMedium(context).copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            '$totalDevices device${totalDevices == 1 ? '' : 's'} available, try a different search',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
              color: AppColors.neutralContainer(context),
              borderRadius: DesignTokens.borderRadiusXL,
            ),
            child: Icon(
              Icons.bluetooth_searching,
              size: DesignTokens.iconHero,
              color: AppColors.textTertiary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'No BLE devices found',
            style: AppTextStyles.titleMedium(context).copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Start scanning to discover nearby devices',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingL),
          StreamBuilder<bool>(
            stream: widget.controller.scanningStream,
            initialData: false,
            builder: (context, snapshot) {
              bool isScanning = snapshot.data ?? false;
              if (isScanning) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingML,
                    vertical: DesignTokens.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer(context),
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
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.infoColor(context)),
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Scanning...',
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: AppColors.onInfoContainer(context),
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
      stream: widget.controller.connectedDeviceStream,
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
                    colors: [
                      AppColors.infoContainer(context),
                      AppColors.successContainer(context),
                    ],
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
                  ? BorderSide(color: AppColors.successBorder(context), width: 2)
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
                    SizedBox(height: DesignTokens.spacingSM),
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
            color: isConnected
                ? AppColors.successContainer(context)
                : AppColors.infoContainer(context),
            borderRadius: DesignTokens.borderRadiusS,
          ),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isConnected
                ? AppColors.successColor(context)
                : AppColors.infoColor(context),
            size: DesignTokens.iconS,
          ),
        ),
        SizedBox(width: DesignTokens.spacingSM),
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
    Color getSignalColor(BuildContext context, int rssi) {
      if (rssi >= -40) return AppColors.successColor(context);
      if (rssi >= -55) return AppColors.successColor(context).withValues(alpha: 0.7);
      if (rssi >= -70) return AppColors.warningColor(context);
      if (rssi >= -85) return AppColors.errorColor(context);
      return AppColors.errorColor(context);
    }

    int getSignalBars(int rssi) {
      if (rssi >= -40) return 4;
      if (rssi >= -55) return 3;
      if (rssi >= -70) return 2;
      if (rssi >= -85) return 1;
      return 0;
    }

    final color = getSignalColor(context, device.rssi);
    final bars = getSignalBars(device.rssi);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: 8 + (index * 3),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index < bars ? color : AppColors.neutralBorder(context),
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
          onPressed: () => widget.onDeviceFavorite?.call(device),
          icon: Icon(
            device.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: device.isFavorite
                ? AppColors.errorColor(context)
                : AppColors.neutralColor(context),
            size: DesignTokens.iconS,
          ),
          tooltip: device.isFavorite ? 'Remove from favorites' : 'Add to favorites',
        ),

        const Spacer(),

        // Connect/Disconnect button
        ElevatedButton.icon(
          onPressed: () {
            if (isConnected) {
              widget.onDeviceDisconnect?.call(device);
            } else {
              widget.onDeviceConnect?.call(device);
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
            backgroundColor: isConnected
                ? AppColors.errorColor(context)
                : AppColors.infoColor(context),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingSM,
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