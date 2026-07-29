import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import '../l10n/app_strings.dart';

/// Service responsible for installing APK updates on Android devices.
///
/// This service handles:
/// - APK installation via platform channel
/// - Permission checking and requesting for unknown sources
/// - Permission diagnostics
/// - Error handling with specific error messages
///
/// Use [InstallManager.withDependencies()] constructor for dependency injection.
class InstallManager {
  /// Named constructor for dependency injection.
  InstallManager.withDependencies({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  final NotificationService _notificationService;

  // Platform channel for Android native communication
  static const _platform = MethodChannel('com.cg500.ble_app/update');

  /// Install APK update (Android only)
  ///
  /// Returns true if installation was successfully initiated, false otherwise.
  /// Note: This initiates the installation process, the actual installation
  /// is handled by the Android system's package installer.
  Future<bool> installUpdate(String apkPath) async {
    if (!Platform.isAndroid) {
      Logger.warning('APK installation only supported on Android');
      _notificationService.showError(
        title: AppStrings.installPlatformNotSupportedTitle,
        message: AppStrings.installAndroidOnlyMessage,
      );
      return false;
    }

    try {
      Logger.info('Starting APK installation process...');
      Logger.info('APK path: $apkPath');

      // Check if file exists
      final file = File(apkPath);
      if (!await file.exists()) {
        Logger.error('APK file does not exist at path: $apkPath');
        _notificationService.showError(
          title: AppStrings.installFailedTitle,
          message: AppStrings.installApkNotFoundMessage,
        );
        return false;
      }

      Logger.info('APK file exists, size: ${await file.length()} bytes');

      // Check if we can install APKs
      final canInstall = await _platform.invokeMethod('canInstallApks');
      Logger.info('Can install APKs: $canInstall');

      if (!canInstall) {
        Logger.warning('Unknown sources permission not granted');
        _notificationService.showError(
          title: AppStrings.installPermissionRequiredTitle,
          message:
              AppStrings.installUnknownSourcesMessage,
        );

        // Request permission
        await _platform.invokeMethod('requestInstallPermission');
        return false;
      }

      Logger.info('Calling platform method installApk...');
      final result =
          await _platform.invokeMethod('installApk', {'filePath': apkPath});

      Logger.info('Install APK platform channel result: $result');

      // Handle detailed result from Android
      if (result is Map) {
        final installResult = Map<String, dynamic>.from(result);
        final success = installResult['success'] ?? false;

        Logger.info('Installation result details: $installResult');

        if (success) {
          Logger.info('✅ APK installation started successfully');
          _notificationService.showSuccess(
            title: AppStrings.installStartedTitle,
            message: AppStrings.installFollowPromptsMessage,
          );
          return true;
        } else {
          final error = installResult['error'] ?? 'Unknown error';
          final errorType = installResult['errorType'] ?? 'UNKNOWN';

          Logger.error(
              '❌ APK installation failed', error: '$errorType: $error');

          // Show specific error messages based on error type
          await _handleInstallError(errorType, error);
          return false;
        }
      } else if (result == true) {
        // Legacy boolean result handling
        Logger.info('✅ APK installation triggered successfully (legacy result)');
        _notificationService.showSuccess(
          title: AppStrings.installStartedTitle,
          message: AppStrings.installFollowPromptsToCompleteMessage,
        );
        return true;
      } else {
        Logger.warning('❌ APK installation trigger returned: $result');
        _notificationService.showError(
          title: AppStrings.installFailedTitle,
          message: AppStrings.installCouldNotStartMessage,
        );
        return false;
      }
    } catch (e) {
      Logger.error('❌ Failed to install APK via platform channel', error: e);
      _notificationService.showError(
        title: AppStrings.installErrorTitle,
        message: AppStrings.installErrorMessage(e.toString()),
      );
      return false;
    }
  }

  /// Handle installation errors with specific messages
  Future<void> _handleInstallError(String errorType, String error) async {
    switch (errorType) {
      case 'PERMISSION_DENIED':
        Logger.warning('Permission denied - requesting install permission');
        _notificationService.showError(
          title: AppStrings.installPermissionRequiredTitle,
          message:
              AppStrings.installUnknownSourcesRetryMessage,
        );
        // Automatically request permission
        await _platform.invokeMethod('requestInstallPermission');
        break;
      case 'FILE_NOT_FOUND':
        _notificationService.showError(
          title: AppStrings.installFileNotFoundTitle,
          message:
              AppStrings.installApkNotFoundMessage,
        );
        break;
      case 'FILEPROVIDER_ERROR':
        _notificationService.showError(
          title: AppStrings.installFileAccessErrorTitle,
          message:
              AppStrings.installFileAccessErrorMessage,
        );
        break;
      case 'NO_RESOLVER':
        _notificationService.showError(
          title: AppStrings.installNotSupportedTitle,
          message:
              AppStrings.installNoResolverMessage,
        );
        break;
      default:
        _notificationService.showError(
          title: AppStrings.installFailedTitle,
          message: AppStrings.installGenericErrorMessage(error),
        );
    }
  }

  /// Check if device can install APK files
  Future<bool> canInstallApks() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final canInstall = await _platform.invokeMethod('canInstallApks');
      return canInstall ?? false;
    } catch (e) {
      Logger.error('Failed to check APK installation permission', error: e);
      return false;
    }
  }

  /// Request APK installation permission
  Future<void> requestInstallPermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _platform.invokeMethod('requestInstallPermission');
    } catch (e) {
      Logger.error('Failed to request APK installation permission', error: e);
    }
  }

  /// Diagnose APK installation permissions and configuration
  Future<Map<String, dynamic>> diagnosePermissions() async {
    if (!Platform.isAndroid) {
      return {'platform': 'non-android', 'supported': false};
    }

    try {
      final result = await _platform.invokeMethod('diagnosePermissions');

      if (result is Map) {
        final diagnosis = Map<String, dynamic>.from(result);
        Logger.info('Permission diagnosis completed: $diagnosis');
        return diagnosis;
      } else {
        Logger.warning(
            'Unexpected diagnosis result type: ${result.runtimeType}');
        return {
          'error': 'Unexpected result type',
          'raw_result': result.toString()
        };
      }
    } catch (e) {
      Logger.error('Failed to diagnose permissions', error: e);
      return {'error': 'Diagnosis failed', 'exception': e.toString()};
    }
  }

  /// Open system settings for installing unknown apps
  Future<void> openInstallSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _platform.invokeMethod('requestInstallPermission');
    } catch (e) {
      Logger.error('Failed to open install settings', error: e);
    }
  }
}
