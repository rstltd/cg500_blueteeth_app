import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../design/design_system.dart';

/// Widget for displaying scanning status with animated progress indicator
class ScanningIndicatorWidget extends StatelessWidget {
  final BleControllerInterface controller;

  const ScanningIndicatorWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: controller.scanningStream,
      initialData: false,
      builder: (context, snapshot) {
        bool isScanning = snapshot.data ?? false;
        if (!isScanning) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: DesignTokens.durationNormal,
          margin: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          padding: DesignTokens.paddingM,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.scanningGradientStart(context),
                AppColors.scanningGradientEnd(context),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: DesignTokens.borderRadiusM,
            border: Border.all(color: AppColors.infoBorder(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: DesignTokens.iconS,
                height: DesignTokens.iconS,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.infoColor(context)),
                ),
              ),
              SizedBox(width: DesignTokens.spacingSM),
              Text(
                'Scanning for BLE devices...',
                style: AppTextStyles.labelLarge(context).copyWith(
                  color: AppColors.onInfoContainer(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}