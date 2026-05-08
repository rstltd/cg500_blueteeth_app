import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';
import '../../models/ble_device.dart';
import '../../models/connection_state.dart' as model;
import '../../services/device_type_classifier.dart';
import '../common/animated_widgets.dart';

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
            AppStrings.noMatchingDevices(widget.searchQuery),
            style: AppTextStyles.titleMedium(context).copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            AppStrings.availableDevicesHint(totalDevices),
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
            AppStrings.noDevicesFound,
            style: AppTextStyles.titleMedium(context).copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            AppStrings.startScanningHint,
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
                        AppStrings.scanning,
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

  /// Build individual device card.
  ///
  /// Compact single-row layout: leading Bluetooth icon, device name with
  /// MAC (ID) subtitle, trailing signal bars + favorite + action area.
  /// The action area swaps between a connect/disconnect button and a
  /// "connecting..." status indicator based on [model.BleConnectionState].
  Widget _buildDeviceCard(BuildContext context, BleDeviceModel device) {
    final connectionState = device.connectionState;
    final bool isConnected = connectionState.isConnected;
    final bool isTransitioning = connectionState.isTransitioning;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        borderRadius: DesignTokens.borderRadiusM,
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: isConnected
              ? AppColors.successBorder(context)
              : AppColors.neutralBorder(context).withValues(alpha: 0.5),
          width: isConnected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingSM,
        ),
        child: Row(
          children: [
            // Leading device-type icon (per ADR-0008): GNSS / accelerometer /
            // inclinometer get a type-specific icon; non-RST devices keep the
            // historical bluetooth / bluetooth_connected swap.
            Icon(
              iconForDeviceType(device.deviceType, connected: isConnected),
              color: isConnected
                  ? AppColors.successColor(context)
                  : AppColors.infoColor(context),
              size: DesignTokens.iconM,
            ),
            SizedBox(width: DesignTokens.spacingSM),
            // Name + MAC subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    device.name.isNotEmpty
                        ? device.name
                        : AppStrings.unknownDevice,
                    style: AppTextStyles.titleSmall(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.id,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textSecondary(context),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
            // Signal bars
            _buildSignalStrengthIndicator(context, device),
            SizedBox(width: DesignTokens.spacingXS),
            // Favorite toggle
            IconButton(
              onPressed: () => widget.onDeviceFavorite?.call(device),
              icon: Icon(
                device.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: device.isFavorite
                    ? AppColors.errorColor(context)
                    : AppColors.neutralColor(context),
                size: DesignTokens.iconS,
              ),
              tooltip: device.isFavorite
                  ? AppStrings.removeFromFavorites
                  : AppStrings.addToFavorites,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              visualDensity: VisualDensity.compact,
            ),
            // Connect / disconnect button, or a transient status chip
            // while the link is still being established / torn down.
            if (isTransitioning)
              _buildConnectingIndicator(context, connectionState)
            else
              _buildConnectButton(context, device, isConnected),
          ],
        ),
      ),
    );
  }

  /// Small pill-style connect / disconnect button suitable for a row layout.
  Widget _buildConnectButton(
    BuildContext context,
    BleDeviceModel device,
    bool isConnected,
  ) {
    return TextButton(
      onPressed: () {
        if (isConnected) {
          widget.onDeviceDisconnect?.call(device);
        } else {
          widget.onDeviceConnect?.call(device);
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: isConnected
            ? AppColors.errorColor(context)
            : AppColors.infoColor(context),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSM,
          vertical: 6,
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusS,
        ),
      ),
      child: Text(
        isConnected ? AppStrings.disconnect : AppStrings.connect,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Non-interactive status chip shown while a device is transitioning
  /// between connected / disconnected states. Prevents the user from
  /// mashing the connect button during an in-flight handshake.
  Widget _buildConnectingIndicator(
    BuildContext context,
    model.BleConnectionState state,
  ) {
    final label = state == model.BleConnectionState.connecting
        ? AppStrings.connecting
        : AppStrings.disconnecting;
    final color = AppColors.infoColor(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSM,
        vertical: 6,
      ),
      constraints: const BoxConstraints(minHeight: 32),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: DesignTokens.borderRadiusS,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build signal strength indicator
  Widget _buildSignalStrengthIndicator(BuildContext context, BleDeviceModel device) {
    // Adjusted thresholds based on real-world BLE testing:
    // -60 dBm at ~10cm, -80 dBm at ~1m
    Color getSignalColor(BuildContext context, int rssi) {
      if (rssi >= -65) return AppColors.successColor(context);
      if (rssi >= -75) return AppColors.successColor(context).withValues(alpha: 0.7);
      if (rssi >= -85) return AppColors.warningColor(context);
      if (rssi >= -95) return AppColors.errorColor(context);
      return AppColors.errorColor(context);
    }

    int getSignalBars(int rssi) {
      if (rssi >= -65) return 4;
      if (rssi >= -75) return 3;
      if (rssi >= -85) return 2;
      if (rssi >= -95) return 1;
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

}