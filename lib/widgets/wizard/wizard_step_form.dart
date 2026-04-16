import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';
import '../../models/command/command_parameter.dart';
import '../../models/command/parameter_type.dart';
import '../command/parameters/dropdown_parameter_input.dart';
import '../command/parameters/host_port_parameter_input.dart';
import '../command/parameters/hour_picker_input.dart';

/// A single form step in the Quick Setup Wizard.
///
/// Displays the step title, the current device value (if known), and
/// the parameter input widget appropriate for the command type.
class WizardStepForm extends StatelessWidget {
  const WizardStepForm({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.title,
    required this.parameter,
    required this.onChanged,
    this.currentDeviceValue,
    this.initialValue,
    this.isFirst = false,
    this.isLast = false,
    this.onNext,
    this.onPrevious,
  });

  final int stepIndex;
  final int totalSteps;
  final String title;
  final CommandParameter parameter;
  final ValueChanged<String> onChanged;
  final String? currentDeviceValue;
  final String? initialValue;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Text(
            AppStrings.stepNOfTotal(stepIndex + 1, totalSteps),
            style: TextStyle(
              fontSize: DesignTokens.fontS,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),

          // Step title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: DesignTokens.spacingL),

          // Current device value
          if (currentDeviceValue != null) ...[
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingSM),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: DesignTokens.borderRadiusS,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: DesignTokens.iconS,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      '${AppStrings.currentValue}：$currentDeviceValue',
                      style: TextStyle(
                        fontSize: DesignTokens.fontS,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
          ],

          // Parameter input
          _buildInput(),

          const Spacer(),

          // Navigation buttons
          Row(
            children: [
              if (!isFirst)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    child: const Text(AppStrings.previousStep),
                  ),
                ),
              if (!isFirst) SizedBox(width: DesignTokens.spacingM),
              Expanded(
                flex: isFirst ? 1 : 1,
                child: FilledButton(
                  onPressed: onNext,
                  child: Text(
                    isLast ? AppStrings.confirmChanges : AppStrings.nextStep,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    switch (parameter.type) {
      case ParameterType.dropdown:
        return DropdownParameterInput(
          parameter: parameter,
          onChanged: onChanged,
          initialValue: initialValue,
        );
      case ParameterType.hostPort:
        return HostPortParameterInput(
          parameter: parameter,
          onChanged: onChanged,
          initialValue: initialValue,
        );
      case ParameterType.hourPicker:
        return HourPickerInput(
          parameter: parameter,
          onChanged: onChanged,
          initialValue: initialValue,
        );
      default:
        // Fallback for other types (shouldn't happen in the wizard)
        return Text('Unsupported parameter type: ${parameter.type}');
    }
  }
}
