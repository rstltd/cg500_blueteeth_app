import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';
import '../../models/ble_device.dart';

/// Status card for a connected device. Hosts the only action entry points
/// into the command interface and the device info dialog — previously these
/// lived on the scanner AppBar but field operators expected to find them on
/// the card that actually represents the device.
class ConnectedDeviceCardWidget extends StatelessWidget {
  final BleDeviceModel device;

  /// Called when the user taps the "open command interface" action.
  /// When null, the action is not rendered.
  final VoidCallback? onOpenCommandInterface;

  /// Called when the user taps the "device info" action.
  /// When null, the action is not rendered.
  final VoidCallback? onShowDeviceInfo;

  const ConnectedDeviceCardWidget({
    super.key,
    required this.device,
    this.onOpenCommandInterface,
    this.onShowDeviceInfo,
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
              if (onShowDeviceInfo != null)
                IconButton(
                  onPressed: onShowDeviceInfo,
                  icon: const Icon(Icons.info_outline),
                  tooltip: AppStrings.deviceInfo,
                  visualDensity: VisualDensity.compact,
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
          if (onOpenCommandInterface != null) ...[
            SizedBox(height: DesignTokens.spacingM),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenCommandInterface,
                icon: const Icon(Icons.chat),
                label: const Text(AppStrings.openCommandInterface),
              ),
            ),
          ],
        ],
      ),
    );
  }
}