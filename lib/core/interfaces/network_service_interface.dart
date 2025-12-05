import 'dart:async';

/// Network connectivity status enumeration.
///
/// This is defined in the interface to ensure consistency between
/// implementations and avoid coupling to a specific service implementation.
enum NetworkStatus {
  none('No Connection'),
  mobile('Mobile Data'),
  wifi('WiFi'),
  unknown('Unknown');

  const NetworkStatus(this.displayName);
  final String displayName;
}

/// Interface for network connectivity monitoring services.
///
/// Implementations of this interface provide network status monitoring,
/// download suitability checking, and network-related utility functions.
abstract class NetworkServiceInterface {
  /// Stream of network status changes.
  ///
  /// Emits a new [NetworkStatus] whenever the network connectivity changes.
  Stream<NetworkStatus> get networkStream;

  /// Current network connectivity status.
  NetworkStatus get currentStatus;

  /// Initialize the network monitoring service.
  ///
  /// Returns `true` if initialization was successful, `false` otherwise.
  Future<bool> initialize();

  /// Check if the current network is suitable for large downloads.
  ///
  /// When [wifiOnly] is true, only WiFi connections are considered suitable.
  /// When false, both WiFi and mobile data are acceptable.
  bool isSuitableForDownload({required bool wifiOnly});

  /// Get a user-friendly description of the current network status.
  String getStatusDescription();

  /// Get the display name for the current network type.
  String getNetworkTypeDisplayName();

  /// Estimate download time based on file size and current network.
  ///
  /// Returns a human-readable string like "~5s", "~2m", or "~1h".
  String estimateDownloadTime(int fileSizeBytes);

  /// Release all resources held by this service.
  void dispose();
}
