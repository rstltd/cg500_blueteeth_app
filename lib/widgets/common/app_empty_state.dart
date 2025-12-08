import 'package:flutter/material.dart';
import '../../design/design_system.dart';

/// A consistent empty state widget used throughout the app.
///
/// Displays an icon, title, optional message, and optional action button
/// when there's no content to show.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  /// The icon to display.
  final IconData icon;

  /// The main title text.
  final String title;

  /// Optional descriptive message.
  final String? message;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional callback when action button is pressed.
  final VoidCallback? onAction;

  /// Optional custom icon color.
  final Color? iconColor;

  /// Whether to use compact layout (less padding).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? DesignTokens.iconXL : DesignTokens.iconHero;
    final spacing = compact ? DesignTokens.spacingS : DesignTokens.spacingM;

    return Center(
      child: Padding(
        padding: compact ? DesignTokens.paddingM : DesignTokens.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textSecondary(context),
            ),
            SizedBox(height: spacing),
            Text(
              title,
              style: compact
                  ? AppTextStyles.titleSmall(context)
                  : AppTextStyles.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: DesignTokens.spacingS),
              Text(
                message!,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: DesignTokens.spacingL),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A consistent error state widget.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.compact = false,
  });

  /// The error message to display.
  final String message;

  /// Optional custom title (defaults to "Error").
  final String? title;

  /// Optional callback for retry action.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  /// Whether to use compact layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline,
      iconColor: AppColors.errorColor(context),
      title: title ?? 'Error',
      message: message,
      actionLabel: onRetry != null ? retryLabel : null,
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// A no data found state widget.
class AppNoDataState extends StatelessWidget {
  const AppNoDataState({
    super.key,
    this.title = 'No Data',
    this.message,
    this.onRefresh,
    this.compact = false,
  });

  final String title;
  final String? message;
  final VoidCallback? onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      message: message ?? 'No items to display',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
      compact: compact,
    );
  }
}

/// A search empty state widget.
class AppSearchEmptyState extends StatelessWidget {
  const AppSearchEmptyState({
    super.key,
    this.searchTerm,
    this.onClearSearch,
    this.compact = false,
  });

  final String? searchTerm;
  final VoidCallback? onClearSearch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: searchTerm != null
          ? 'No results found for "$searchTerm"'
          : 'Try adjusting your search criteria',
      actionLabel: onClearSearch != null ? 'Clear Search' : null,
      onAction: onClearSearch,
      compact: compact,
    );
  }
}

/// BLE scanning states for different scenarios.
enum BleScanState {
  /// Not scanning yet, user needs to start
  notStarted,

  /// Currently scanning for devices
  scanning,

  /// Scan complete but no devices found
  noDevicesFound,

  /// Bluetooth is disabled
  bluetoothDisabled,

  /// Location permission denied
  locationDenied,

  /// Bluetooth permission denied
  bluetoothDenied,
}

/// A BLE-specific empty state widget with contextual messages.
class BleEmptyState extends StatelessWidget {
  const BleEmptyState({
    super.key,
    required this.state,
    this.onStartScan,
    this.onEnableBluetooth,
    this.onRequestPermission,
    this.compact = false,
  });

  final BleScanState state;
  final VoidCallback? onStartScan;
  final VoidCallback? onEnableBluetooth;
  final VoidCallback? onRequestPermission;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = _getConfigForState(context);

    return AppEmptyState(
      icon: config.icon,
      iconColor: config.iconColor,
      title: config.title,
      message: config.message,
      actionLabel: config.actionLabel,
      onAction: config.onAction,
      compact: compact,
    );
  }

  _EmptyStateConfig _getConfigForState(BuildContext context) {
    switch (state) {
      case BleScanState.notStarted:
        return _EmptyStateConfig(
          icon: Icons.bluetooth_searching,
          iconColor: AppColors.infoColor(context),
          title: 'Ready to Scan',
          message: 'Tap the scan button to discover nearby BLE devices',
          actionLabel: onStartScan != null ? 'Start Scanning' : null,
          onAction: onStartScan,
        );

      case BleScanState.scanning:
        return _EmptyStateConfig(
          icon: Icons.radar,
          iconColor: AppColors.infoColor(context),
          title: 'Scanning...',
          message: 'Looking for nearby Bluetooth Low Energy devices',
          actionLabel: null,
          onAction: null,
        );

      case BleScanState.noDevicesFound:
        return _EmptyStateConfig(
          icon: Icons.bluetooth_disabled,
          iconColor: AppColors.warningColor(context),
          title: 'No Devices Found',
          message: 'Make sure your BLE device is powered on and in pairing mode',
          actionLabel: onStartScan != null ? 'Scan Again' : null,
          onAction: onStartScan,
        );

      case BleScanState.bluetoothDisabled:
        return _EmptyStateConfig(
          icon: Icons.bluetooth_disabled,
          iconColor: AppColors.errorColor(context),
          title: 'Bluetooth is Off',
          message: 'Please enable Bluetooth to scan for devices',
          actionLabel: onEnableBluetooth != null ? 'Enable Bluetooth' : null,
          onAction: onEnableBluetooth,
        );

      case BleScanState.locationDenied:
        return _EmptyStateConfig(
          icon: Icons.location_off,
          iconColor: AppColors.errorColor(context),
          title: 'Location Permission Required',
          message: 'BLE scanning requires location permission on Android',
          actionLabel: onRequestPermission != null ? 'Grant Permission' : null,
          onAction: onRequestPermission,
        );

      case BleScanState.bluetoothDenied:
        return _EmptyStateConfig(
          icon: Icons.bluetooth_disabled,
          iconColor: AppColors.errorColor(context),
          title: 'Bluetooth Permission Required',
          message: 'Please grant Bluetooth permission to scan for devices',
          actionLabel: onRequestPermission != null ? 'Grant Permission' : null,
          onAction: onRequestPermission,
        );
    }
  }
}

/// Configuration for empty state appearance.
class _EmptyStateConfig {
  const _EmptyStateConfig({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// A command interface empty state widget.
class CommandEmptyState extends StatelessWidget {
  const CommandEmptyState({
    super.key,
    required this.isConnected,
    this.deviceName,
    this.onConnect,
    this.compact = false,
  });

  final bool isConnected;
  final String? deviceName;
  final VoidCallback? onConnect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      return AppEmptyState(
        icon: Icons.chat_bubble_outline,
        iconColor: AppColors.infoColor(context),
        title: 'No Messages Yet',
        message: deviceName != null
            ? 'Connected to $deviceName. Send a command to get started.'
            : 'Send a command to start communicating with the device.',
        compact: compact,
      );
    } else {
      return AppEmptyState(
        icon: Icons.link_off,
        iconColor: AppColors.warningColor(context),
        title: 'Not Connected',
        message: 'Connect to a BLE device to send commands',
        actionLabel: onConnect != null ? 'Connect Device' : null,
        onAction: onConnect,
        compact: compact,
      );
    }
  }
}
