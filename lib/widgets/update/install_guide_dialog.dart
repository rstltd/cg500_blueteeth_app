import 'package:flutter/material.dart';
import '../../services/update_service.dart';
import '../../core/service_locator.dart' show getIt;
import '../../design/design_system.dart';
import '../../utils/logger.dart';
import '../../l10n/app_strings.dart';

/// Dialog that provides step-by-step installation guide for APK files
class InstallGuideDialog extends StatefulWidget {
  final VoidCallback? onComplete;
  final String? apkPath; // Add APK path parameter
  final bool autoInstall; // Flag to trigger auto installation

  const InstallGuideDialog({
    super.key,
    this.onComplete,
    this.apkPath,
    this.autoInstall = true,
  });

  @override
  State<InstallGuideDialog> createState() => _InstallGuideDialogState();
}

class _InstallGuideDialogState extends State<InstallGuideDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late final UpdateService _updateService;
  int _currentStep = 0;
  bool _hasTriggeredInstall = false;
  
  List<InstallStep> _getSteps(BuildContext context) => [
    InstallStep(
      title: AppStrings.startInstallation,
      description: AppStrings.startInstallationDesc,
      icon: Icons.download_done,
      color: AppColors.successColor(context),
      instructions: const [
        'APK 安裝已被觸發',
        'Android 系統安裝程式將會開啟',
        AppStrings.startInstallationInstruction,
      ],
    ),
    InstallStep(
      title: AppStrings.enableUnknownSources,
      description: AppStrings.enableUnknownSourcesDesc,
      icon: Icons.security,
      color: AppColors.warningColor(context),
      instructions: AppStrings.enableUnknownSourcesInstructions,
    ),
    InstallStep(
      title: AppStrings.installUpdate,
      description: AppStrings.installUpdateDesc,
      icon: Icons.system_update_alt,
      color: AppColors.infoColor(context),
      instructions: AppStrings.installUpdateInstructions,
    ),
    InstallStep(
      title: AppStrings.installationComplete,
      description: AppStrings.installationCompleteDesc,
      icon: Icons.check_circle,
      color: AppColors.successColor(context),
      instructions: AppStrings.installationCompleteInstructions,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateService = getIt<UpdateService>();

    _animationController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Trigger APK installation immediately if auto-install is enabled
    if (widget.autoInstall && widget.apkPath != null && !_hasTriggeredInstall) {
      _triggerApkInstallation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Trigger APK installation via platform channel
  Future<void> _triggerApkInstallation() async {
    if (_hasTriggeredInstall || widget.apkPath == null) return;
    
    _hasTriggeredInstall = true;
    Logger.info('Triggering APK installation: ${widget.apkPath}');
    
    try {
      // Wait a moment for the dialog to show
      await Future.delayed(const Duration(milliseconds: 500));
      
      final success = await _updateService.installUpdate(widget.apkPath!);
      
      if (success) {
        Logger.info('APK installation triggered successfully');
        // Move to step 2 (permissions)
        if (mounted) {
          setState(() {
            _currentStep = 1;
          });
        }
      } else {
        Logger.error('Failed to trigger APK installation');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.cannotStartInstallation),
              backgroundColor: AppColors.errorColor(context),
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Error during APK installation trigger', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.installationError(e.toString())),
            backgroundColor: AppColors.errorColor(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: AppColors.surfaceColor(context).withValues(alpha: 0),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : MediaQuery.of(context).size.width * 0.95,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: DesignTokens.borderRadiusXL,
                boxShadow: DesignTokens.elevatedShadow(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildContent(),
                  _buildActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: DesignTokens.paddingL,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.updateHeaderGradientStart(context),
            AppColors.updateHeaderGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusXL),
          topRight: Radius.circular(DesignTokens.radiusXL),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: DesignTokens.paddingSM,
            decoration: BoxDecoration(
              color: AppColors.whiteOverlay20(context),
              borderRadius: DesignTokens.borderRadiusM,
            ),
            child: Icon(
              Icons.help_outline,
              color: AppColors.textOnPrimary(context),
              size: DesignTokens.iconL - 4, // 28dp
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.installationGuide,
                  style: AppTextStyles.titleLarge(context).copyWith(
                    color: AppColors.textOnPrimary(context),
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  AppStrings.stepProgress(_currentStep + 1, _getSteps(context).length),
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.whiteOverlay90(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: DesignTokens.paddingL,
        child: Column(
          children: [
            _buildProgressIndicator(),
            SizedBox(height: DesignTokens.spacingXL),
            _buildCurrentStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = _getSteps(context);
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? steps[index].color
                        : AppColors.progressInactive(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < steps.length - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    final step = _getSteps(context)[_currentStep];
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: step.color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  step.icon,
                  size: 48,
                  color: step.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                step.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundGradientStart(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.instructions,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              ...step.instructions.asMap().entries.map((entry) {
                final index = entry.key;
                final instruction = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: step.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppColors.textOnPrimary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          instruction,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final steps = _getSteps(context);
    final isLastStep = _currentStep == steps.length - 1;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentStep > 0)
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text(AppStrings.previous),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // Next/Complete button
          Expanded(
            flex: _currentStep == 0 ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isLastStep) {
                  Navigator.of(context).pop();
                  widget.onComplete?.call();
                } else if (_currentStep == 0 && widget.apkPath != null) {
                  // On first step, manually trigger installation if not already done
                  if (!_hasTriggeredInstall) {
                    _triggerApkInstallation();
                  } else {
                    setState(() {
                      _currentStep++;
                    });
                  }
                } else {
                  setState(() {
                    _currentStep++;
                  });
                }
              },
              icon: Icon(isLastStep ? Icons.check : (_currentStep == 0 ? Icons.install_mobile : Icons.arrow_forward)),
              label: Text(isLastStep ? AppStrings.gotIt : (_currentStep == 0 ? AppStrings.installNow : AppStrings.next)),
              style: ElevatedButton.styleFrom(
                backgroundColor: steps[_currentStep].color,
                foregroundColor: AppColors.textOnPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Skip button (except on last step)
          if (!isLastStep) ...[
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onComplete?.call();
              },
              child: const Text(AppStrings.skipGuide),
            ),
          ],
        ],
      ),
    );
  }
}

/// Data model for installation steps
class InstallStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> instructions;

  const InstallStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.instructions,
  });
}