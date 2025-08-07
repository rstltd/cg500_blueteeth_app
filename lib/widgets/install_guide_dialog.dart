import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';
import '../services/update_service.dart';
import '../utils/logger.dart';

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
  int _currentStep = 0;
  final UpdateService _updateService = UpdateService();
  bool _hasTriggeredInstall = false;
  
  final List<InstallStep> _steps = [
    InstallStep(
      title: 'Starting Installation',
      description: 'The update is being prepared for installation.',
      icon: Icons.download_done,
      color: Colors.green,
      instructions: [
        'The APK installation has been triggered',
        'Android system installer should open shortly',
        'If nothing happens, tap "Install Manually" below',
      ],
    ),
    InstallStep(
      title: 'Enable Unknown Sources',
      description: 'Allow installation of apps from unknown sources.',
      icon: Icons.security,
      color: Colors.orange,
      instructions: [
        'If prompted, tap "Settings" in the security dialog',
        'Toggle "Allow from this source" or "Unknown sources"',
        'Return to the installation screen',
      ],
    ),
    InstallStep(
      title: 'Install Update',
      description: 'Proceed with the installation process.',
      icon: Icons.system_update_alt,
      color: Colors.blue,
      instructions: [
        'Review the app permissions if shown',
        'Tap "Install" to proceed',
        'Wait for installation to complete',
      ],
    ),
    InstallStep(
      title: 'Installation Complete',
      description: 'The update has been installed successfully.',
      icon: Icons.check_circle,
      color: Colors.green,
      instructions: [
        'The app will restart automatically',
        'You\'ll see the new version in the app',
        'All your data and settings are preserved',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
            const SnackBar(
              content: Text('Failed to start installation. Please install manually.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Error during APK installation trigger', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installation error: $e'),
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : MediaQuery.of(context).size.width * 0.95,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installation Guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 32),
            _buildCurrentStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_steps.length, (index) {
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
                        ? _steps[index].color
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < _steps.length - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    final step = _steps[_currentStep];
    
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
                'Instructions:',
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
                            style: const TextStyle(
                              color: Colors.white,
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
    final isLastStep = _currentStep == _steps.length - 1;
    
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
                label: const Text('Previous'),
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
              label: Text(isLastStep ? 'Got It!' : (_currentStep == 0 ? 'Install Now' : 'Next')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _steps[_currentStep].color,
                foregroundColor: Colors.white,
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
              child: const Text('Skip Guide'),
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