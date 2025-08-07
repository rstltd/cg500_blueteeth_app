import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/update_service.dart';
import '../services/theme_service.dart';

/// Widget for displaying network status and download suitability
class NetworkInfoWidget extends StatelessWidget {
  final NetworkService networkService;
  final UpdateService updateService;
  final int downloadSize;
  final NetworkStatus networkStatus;

  const NetworkInfoWidget({
    super.key,
    required this.networkService,
    required this.updateService,
    required this.downloadSize,
    required this.networkStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Only check WiFi requirement if preferences are loaded
    // If preferences are not loaded, don't make assumptions about user's choice
    final preferences = updateService.preferences;
    final bool isWifiRequired;
    
    if (preferences != null) {
      isWifiRequired = preferences.wifiOnlyDownload;
    } else {
      // If preferences not loaded, assume non-restrictive (allow mobile data)
      // This prevents blocking downloads when settings are still loading
      isWifiRequired = false;
    }
    
    final networkSuitable = networkService.isSuitableForDownload(wifiOnly: isWifiRequired);
    final estimatedTime = networkService.estimateDownloadTime(downloadSize);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Network:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  _getNetworkIcon(),
                  size: 16,
                  color: networkSuitable ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        networkService.getNetworkTypeDisplayName(),
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!networkSuitable)
                        Text(
                          'WiFi recommended',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        'Est. $estimatedTime',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNetworkIcon() {
    switch (networkStatus) {
      case NetworkStatus.wifi:
        return Icons.wifi;
      case NetworkStatus.mobile:
        return Icons.signal_cellular_4_bar;
      case NetworkStatus.none:
        return Icons.wifi_off;
      case NetworkStatus.unknown:
        return Icons.help_outline;
    }
  }
}