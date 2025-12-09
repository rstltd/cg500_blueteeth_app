import 'package:flutter/material.dart';

/// A semantic wrapper for BLE device cards.
///
/// Provides accessibility labels and hints for screen readers.
///
/// Example:
/// ```dart
/// SemanticDeviceCard(
///   deviceName: 'CG500',
///   deviceId: 'AA:BB:CC:DD:EE:FF',
///   isConnected: true,
///   rssi: -65,
///   child: DeviceCardContent(),
/// )
/// ```
class SemanticDeviceCard extends StatelessWidget {
  /// The device display name
  final String deviceName;

  /// The device ID/MAC address
  final String deviceId;

  /// Whether the device is currently connected
  final bool isConnected;

  /// Signal strength in dBm
  final int rssi;

  /// Whether the device is favorited
  final bool isFavorite;

  /// The card content widget
  final Widget child;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Callback when long pressed
  final VoidCallback? onLongPress;

  const SemanticDeviceCard({
    super.key,
    required this.deviceName,
    required this.deviceId,
    required this.child,
    this.isConnected = false,
    this.rssi = 0,
    this.isFavorite = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final signalStrength = _getSignalStrengthLabel(rssi);
    final connectionStatus = isConnected ? 'Connected' : 'Not connected';
    final favoriteStatus = isFavorite ? ', Favorite' : '';

    return Semantics(
      label: '$deviceName, $connectionStatus, Signal $signalStrength$favoriteStatus',
      hint: isConnected
          ? 'Double tap to view device details'
          : 'Double tap to connect',
      button: true,
      enabled: true,
      child: MergeSemantics(
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: child,
        ),
      ),
    );
  }

  String _getSignalStrengthLabel(int rssi) {
    if (rssi >= -40) return 'Excellent';
    if (rssi >= -55) return 'Very Good';
    if (rssi >= -70) return 'Good';
    if (rssi >= -85) return 'Fair';
    return 'Weak';
  }
}

/// A semantic wrapper for connection status indicators.
///
/// Example:
/// ```dart
/// SemanticConnectionStatus(
///   isConnected: true,
///   deviceName: 'CG500',
///   connectionDuration: Duration(minutes: 5),
///   child: ConnectionIndicator(),
/// )
/// ```
class SemanticConnectionStatus extends StatelessWidget {
  /// Whether connected
  final bool isConnected;

  /// Optional device name
  final String? deviceName;

  /// Connection duration if connected
  final Duration? connectionDuration;

  /// The indicator widget
  final Widget child;

  const SemanticConnectionStatus({
    super.key,
    required this.isConnected,
    required this.child,
    this.deviceName,
    this.connectionDuration,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    if (isConnected) {
      final device = deviceName != null ? ' to $deviceName' : '';
      final duration = connectionDuration != null
          ? ', ${_formatDuration(connectionDuration!)}'
          : '';
      label = 'Connected$device$duration';
    } else {
      label = 'Not connected';
    }

    return Semantics(
      label: label,
      liveRegion: true, // Announces changes to screen readers
      child: child,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} '
          '${duration.inMinutes.remainder(60)} minutes';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${duration.inSeconds} seconds';
    }
  }
}

/// A semantic wrapper for action buttons.
///
/// Example:
/// ```dart
/// SemanticActionButton(
///   label: 'Connect to device',
///   hint: 'Establishes a Bluetooth connection',
///   isDestructive: false,
///   child: ElevatedButton(...),
/// )
/// ```
class SemanticActionButton extends StatelessWidget {
  /// The accessibility label
  final String label;

  /// Optional hint for additional context
  final String? hint;

  /// Whether this is a destructive action (e.g., disconnect, delete)
  final bool isDestructive;

  /// Whether the button is currently enabled
  final bool enabled;

  /// Whether this action is currently in progress
  final bool isLoading;

  /// The button widget
  final Widget child;

  const SemanticActionButton({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.isDestructive = false,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    String effectiveLabel = label;
    if (isLoading) {
      effectiveLabel = '$label, Loading';
    } else if (!enabled) {
      effectiveLabel = '$label, Disabled';
    }

    return Semantics(
      label: effectiveLabel,
      hint: hint,
      button: true,
      enabled: enabled && !isLoading,
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }
}

/// A semantic wrapper for scanning state indicators.
///
/// Example:
/// ```dart
/// SemanticScanningIndicator(
///   isScanning: true,
///   devicesFound: 5,
///   child: ScanningAnimation(),
/// )
/// ```
class SemanticScanningIndicator extends StatelessWidget {
  /// Whether currently scanning
  final bool isScanning;

  /// Number of devices found
  final int devicesFound;

  /// The indicator widget
  final Widget child;

  const SemanticScanningIndicator({
    super.key,
    required this.isScanning,
    required this.child,
    this.devicesFound = 0,
  });

  @override
  Widget build(BuildContext context) {
    final label = isScanning
        ? 'Scanning for Bluetooth devices, $devicesFound device${devicesFound == 1 ? '' : 's'} found'
        : 'Scan stopped, $devicesFound device${devicesFound == 1 ? '' : 's'} found';

    return Semantics(
      label: label,
      liveRegion: true,
      child: child,
    );
  }
}

/// A semantic wrapper for message bubbles in the command interface.
///
/// Example:
/// ```dart
/// SemanticMessageBubble(
///   isCommand: true,
///   message: 'AT+VERSION',
///   timestamp: DateTime.now(),
///   isError: false,
///   child: MessageBubble(...),
/// )
/// ```
class SemanticMessageBubble extends StatelessWidget {
  /// Whether this is a sent command (vs received response)
  final bool isCommand;

  /// The message content
  final String message;

  /// Message timestamp
  final DateTime? timestamp;

  /// Whether this is an error message
  final bool isError;

  /// The bubble widget
  final Widget child;

  const SemanticMessageBubble({
    super.key,
    required this.isCommand,
    required this.message,
    required this.child,
    this.timestamp,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = isCommand ? 'Command sent' : 'Response received';
    final errorIndicator = isError ? ', Error' : '';
    final time = timestamp != null ? ', at ${_formatTime(timestamp!)}' : '';

    return Semantics(
      label: '$type$errorIndicator: $message$time',
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

/// A semantic wrapper for signal strength indicators.
///
/// Example:
/// ```dart
/// SemanticSignalStrength(
///   rssi: -65,
///   child: SignalBars(),
/// )
/// ```
class SemanticSignalStrength extends StatelessWidget {
  /// RSSI value in dBm
  final int rssi;

  /// The signal indicator widget
  final Widget child;

  const SemanticSignalStrength({
    super.key,
    required this.rssi,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final strength = _getStrengthDescription(rssi);

    return Semantics(
      label: 'Signal strength: $strength, $rssi decibels',
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }

  String _getStrengthDescription(int rssi) {
    if (rssi >= -40) return 'Excellent';
    if (rssi >= -55) return 'Very good';
    if (rssi >= -70) return 'Good';
    if (rssi >= -85) return 'Fair';
    return 'Weak';
  }
}

/// A semantic wrapper for favorite/unfavorite buttons.
///
/// Example:
/// ```dart
/// SemanticFavoriteButton(
///   isFavorite: true,
///   deviceName: 'CG500',
///   onTap: () => toggleFavorite(),
///   child: FavoriteIcon(),
/// )
/// ```
class SemanticFavoriteButton extends StatelessWidget {
  /// Whether the item is currently favorited
  final bool isFavorite;

  /// Optional item name for context
  final String? deviceName;

  /// Tap callback
  final VoidCallback? onTap;

  /// The button widget
  final Widget child;

  const SemanticFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.child,
    this.deviceName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final device = deviceName != null ? deviceName! : 'device';
    final label = isFavorite
        ? 'Remove $device from favorites'
        : 'Add $device to favorites';

    return Semantics(
      label: label,
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// A semantic wrapper for filter chips/tabs.
///
/// Example:
/// ```dart
/// SemanticFilterChip(
///   label: 'Commands',
///   isSelected: true,
///   count: 5,
///   onTap: () => selectFilter(),
///   child: FilterChip(...),
/// )
/// ```
class SemanticFilterChip extends StatelessWidget {
  /// The filter label
  final String label;

  /// Whether this filter is currently selected
  final bool isSelected;

  /// Optional count of items matching this filter
  final int? count;

  /// Tap callback
  final VoidCallback? onTap;

  /// The chip widget
  final Widget child;

  const SemanticFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.child,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel = count != null ? ', $count items' : '';
    final selectedLabel = isSelected ? ', Selected' : '';

    return Semantics(
      label: '$label filter$countLabel$selectedLabel',
      button: true,
      selected: isSelected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// A semantic wrapper for progress indicators.
///
/// Example:
/// ```dart
/// SemanticProgressIndicator(
///   label: 'Downloading update',
///   progress: 0.75,
///   child: LinearProgressIndicator(value: 0.75),
/// )
/// ```
class SemanticProgressIndicator extends StatelessWidget {
  /// Label describing what is in progress
  final String label;

  /// Progress value from 0.0 to 1.0, or null for indeterminate
  final double? progress;

  /// The progress indicator widget
  final Widget child;

  const SemanticProgressIndicator({
    super.key,
    required this.label,
    required this.child,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final progressLabel = progress != null
        ? ', ${(progress! * 100).toInt()} percent complete'
        : ', In progress';

    return Semantics(
      label: '$label$progressLabel',
      value: progress != null ? '${(progress! * 100).toInt()}%' : null,
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }
}

/// A semantic wrapper for loading/skeleton placeholders.
///
/// Example:
/// ```dart
/// SemanticLoadingPlaceholder(
///   label: 'Loading device list',
///   child: SkeletonDeviceList(),
/// )
/// ```
class SemanticLoadingPlaceholder extends StatelessWidget {
  /// Description of what is loading
  final String label;

  /// The placeholder widget
  final Widget child;

  const SemanticLoadingPlaceholder({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, Please wait',
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }
}

/// A semantic wrapper for empty state messages.
///
/// Example:
/// ```dart
/// SemanticEmptyState(
///   label: 'No devices found',
///   hint: 'Start scanning to discover nearby Bluetooth devices',
///   child: EmptyStateWidget(),
/// )
/// ```
class SemanticEmptyState extends StatelessWidget {
  /// The empty state message
  final String label;

  /// Optional hint for what to do next
  final String? hint;

  /// The empty state widget
  final Widget child;

  const SemanticEmptyState({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      child: MergeSemantics(
        child: child,
      ),
    );
  }
}

/// A semantic wrapper for error messages.
///
/// Example:
/// ```dart
/// SemanticError(
///   errorMessage: 'Connection failed',
///   retryHint: 'Double tap to retry',
///   onRetry: () => retryConnection(),
///   child: ErrorWidget(),
/// )
/// ```
class SemanticError extends StatelessWidget {
  /// The error message
  final String errorMessage;

  /// Optional hint for retry action
  final String? retryHint;

  /// Optional retry callback
  final VoidCallback? onRetry;

  /// The error widget
  final Widget child;

  const SemanticError({
    super.key,
    required this.errorMessage,
    required this.child,
    this.retryHint,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Error: $errorMessage',
      hint: retryHint ?? (onRetry != null ? 'Double tap to retry' : null),
      button: onRetry != null,
      onTap: onRetry,
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }
}

/// A semantic header for sections.
///
/// Example:
/// ```dart
/// SemanticSectionHeader(
///   title: 'Connected Device',
///   child: HeaderWidget(),
/// )
/// ```
class SemanticSectionHeader extends StatelessWidget {
  /// Section title
  final String title;

  /// Optional count of items in section
  final int? itemCount;

  /// The header widget
  final Widget child;

  const SemanticSectionHeader({
    super.key,
    required this.title,
    required this.child,
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel =
        itemCount != null ? ', $itemCount item${itemCount == 1 ? '' : 's'}' : '';

    return Semantics(
      header: true,
      label: '$title$countLabel',
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }
}

/// A semantic wrapper for text input fields.
///
/// Example:
/// ```dart
/// SemanticTextField(
///   label: 'Command input',
///   hint: 'Enter command to send to device',
///   currentValue: 'AT+VERSION',
///   child: TextField(),
/// )
/// ```
class SemanticTextField extends StatelessWidget {
  /// Field label
  final String label;

  /// Optional hint text
  final String? hint;

  /// Current field value
  final String? currentValue;

  /// Whether the field is required
  final bool isRequired;

  /// Whether the field has an error
  final bool hasError;

  /// Error message if hasError is true
  final String? errorMessage;

  /// The text field widget
  final Widget child;

  const SemanticTextField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.currentValue,
    this.isRequired = false,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    String effectiveLabel = label;
    if (isRequired) {
      effectiveLabel = '$effectiveLabel, Required';
    }
    if (hasError && errorMessage != null) {
      effectiveLabel = '$effectiveLabel, Error: $errorMessage';
    }

    return Semantics(
      label: effectiveLabel,
      hint: hint,
      textField: true,
      value: currentValue,
      child: child,
    );
  }
}

/// Extension to add semantic labels to existing widgets easily.
extension SemanticExtensions on Widget {
  /// Wrap with semantic label
  Widget withSemantics({
    required String label,
    String? hint,
    bool button = false,
    bool header = false,
    bool enabled = true,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      enabled: enabled,
      selected: selected,
      onTap: onTap,
      child: this,
    );
  }

  /// Exclude from semantics tree
  Widget excludeSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Merge semantics with children
  Widget mergeSemantics() {
    return MergeSemantics(child: this);
  }
}
