import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

/// Service for monitoring network connectivity and type
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final StreamController<NetworkStatus> _networkController = 
      StreamController<NetworkStatus>.broadcast();
  final Connectivity _connectivity = Connectivity();
  
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectivityTimer;

  Stream<NetworkStatus> get networkStream => _networkController.stream;
  NetworkStatus get currentStatus => _currentStatus;

  /// Initialize network monitoring
  Future<bool> initialize() async {
    try {
      await _checkConnectivity();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _handleConnectivityChange(results);
        },
      );
      
      // Fallback periodic check every 30 seconds
      _connectivityTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkConnectivity(),
      );
      
      Logger.info('Network Service initialized');
      return true;
    } catch (e) {
      Logger.error('Failed to initialize Network Service', error: e);
      return false;
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      NetworkStatus newStatus = await _getCurrentNetworkStatus();
      
      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _networkController.add(_currentStatus);
        Logger.debug('Network status changed: ${_currentStatus.name}');
      }
    } catch (e) {
      Logger.error('Error checking connectivity', error: e);
      _currentStatus = NetworkStatus.unknown;
      _networkController.add(_currentStatus);
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    final newStatus = await _getCurrentNetworkStatus(results);
    
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _networkController.add(_currentStatus);
      Logger.debug('Network status changed: ${_currentStatus.name}');
    }
  }

  /// Get current network status
  Future<NetworkStatus> _getCurrentNetworkStatus([List<ConnectivityResult>? connectivityResults]) async {
    try {
      List<ConnectivityResult> results = connectivityResults ?? await _connectivity.checkConnectivity();
      
      // Check if we have any connectivity
      if (results.contains(ConnectivityResult.none)) {
        return NetworkStatus.none;
      }
      
      // Check for WiFi first (preferred)
      if (results.contains(ConnectivityResult.wifi)) {
        // Verify internet connectivity
        final hasInternet = await _hasInternetConnection();
        return hasInternet ? NetworkStatus.wifi : NetworkStatus.none;
      }
      
      // Check for mobile data
      if (results.contains(ConnectivityResult.mobile)) {
        // Verify internet connectivity
        final hasInternet = await _hasInternetConnection();
        return hasInternet ? NetworkStatus.mobile : NetworkStatus.none;
      }
      
      // Check for ethernet (treat as WiFi)
      if (results.contains(ConnectivityResult.ethernet)) {
        final hasInternet = await _hasInternetConnection();
        return hasInternet ? NetworkStatus.wifi : NetworkStatus.none;
      }
      
      // Other connections (VPN, Bluetooth, etc.) - treat as unknown but verify
      final hasInternet = await _hasInternetConnection();
      return hasInternet ? NetworkStatus.wifi : NetworkStatus.unknown;
    } catch (e) {
      Logger.error('Error getting network status', error: e);
      return NetworkStatus.unknown;
    }
  }

  /// Check if device has internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }


  /// Check if current network is suitable for large downloads
  bool isSuitableForDownload({required bool wifiOnly}) {
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        return true;
      case NetworkStatus.mobile:
        return !wifiOnly;
      case NetworkStatus.none:
      case NetworkStatus.unknown:
        return false;
    }
  }

  /// Get user-friendly network status description
  String getStatusDescription() {
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        return 'Connected via WiFi';
      case NetworkStatus.mobile:
        return 'Connected via mobile data';
      case NetworkStatus.none:
        return 'No internet connection';
      case NetworkStatus.unknown:
        return 'Network status unknown';
    }
  }

  /// Get network type for display
  String getNetworkTypeDisplayName() {
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        return 'WiFi';
      case NetworkStatus.mobile:
        return 'Mobile Data';
      case NetworkStatus.none:
        return 'No Connection';
      case NetworkStatus.unknown:
        return 'Unknown';
    }
  }

  /// Estimate download time based on network type and file size
  String estimateDownloadTime(int fileSizeBytes) {
    if (_currentStatus == NetworkStatus.none) {
      return 'Cannot download - no connection';
    }

    // Rough estimates based on typical speeds
    double speedMbps;
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        speedMbps = 50.0; // 50 Mbps typical WiFi
        break;
      case NetworkStatus.mobile:
        speedMbps = 20.0; // 20 Mbps typical 4G
        break;
      default:
        speedMbps = 10.0; // Conservative estimate
    }

    final fileSizeMb = fileSizeBytes / (1024 * 1024);
    final estimatedSeconds = (fileSizeMb * 8) / speedMbps; // Convert to bits and calculate

    if (estimatedSeconds < 60) {
      return '~${estimatedSeconds.round()}s';
    } else if (estimatedSeconds < 3600) {
      return '~${(estimatedSeconds / 60).round()}m';
    } else {
      return '~${(estimatedSeconds / 3600).round()}h';
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();
    _networkController.close();
  }
}

/// Network connectivity status
enum NetworkStatus {
  none('No Connection'),
  mobile('Mobile Data'),
  wifi('WiFi'),
  unknown('Unknown');

  const NetworkStatus(this.displayName);
  final String displayName;
}