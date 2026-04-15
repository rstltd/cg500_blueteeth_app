import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';
import '../../models/ble_device.dart';

/// Status card for a connected device. Pure information — the entry point
/// to the command interface lives on the scanner AppBar (filled chat icon)
/// to avoid offering two different paths for the same action.
class ConnectedDeviceCardWidget extends StatelessWidget {
  final BleDeviceModel device;

  const ConnectedDeviceCardWidget({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ResponsiveIcon(
                Icons.bluetooth_connected,
                size: 24,
                color: AppColors.successColor(context),
              ),
              SizedBox(width: DesignTokens.spacingSM),
              Expanded(
                child: ResponsiveText(
                  AppStrings.connected,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.successColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingSM),
          ResponsiveText(
            device.displayName,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          ResponsiveText(
            device.id,
            fontSize: 12,
            color: AppColors.textSecondary(context),
          ),
        ],
      ),
    );
  }
}