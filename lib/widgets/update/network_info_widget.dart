import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/network_service.dart';
import '../../services/update_preferences_store.dart';
import '../../services/theme_service.dart';

/// Widget for displaying network status and download suitability
class NetworkInfoWidget extends StatelessWidget {
  final NetworkService networkService;
  final UpdatePreferencesStore preferencesStore;
  final int downloadSize;
  final NetworkStatus networkStatus;

  const NetworkInfoWidget({
    super.key,
    required this.networkService,
    required this.preferencesStore,
    required this.downloadSize,
    required this.networkStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Only check WiFi requirement if preferences are loaded
    final preferences = preferencesStore.current;
    final bool preferencesLoaded = preferences != null;
    final bool isWifiRequired;

    if (preferencesLoaded) {
      isWifiRequired = preferences.wifiOnlyDownload;
    } else {
      // If preferences not loaded, default to WiFi-only (safer default)
      // This prevents accidentally using mobile data before settings are loaded
      isWifiRequired = true;
    }

    final networkSuitable = networkService.isSuitableForDownload(wifiOnly: isWifiRequired);
    final estimatedTime = networkService.estimateDownloadTime(downloadSize);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  AppStrings.networkLabel,
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
                          if (!preferencesLoaded)
                            Text(
                              AppStrings.loadingPreferences,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else if (!networkSuitable)
                            Text(
                              AppStrings.wifiRecommended,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            AppStrings.estimatedDownloadTime(estimatedTime),
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
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bluetooth,
                  size: 12,
                  color: AppColors.textSecondary(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    AppStrings.bleCommandsWorkOffline,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                      fontStyle: FontStyle.italic,
                    ),
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