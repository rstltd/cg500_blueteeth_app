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
class WizardStepForm extends StatefulWidget {
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
  State<WizardStepForm> createState() => _WizardStepFormState();
}

class _WizardStepFormState extends State<WizardStepForm> {
  /// Mirrors the value `QuickSetupViewModel` holds for this step: seeded from
  /// the pre-filled value and updated on every change we forward to the VM.
  String? _userValue;

  @override
  void initState() {
    super.initState();
    _userValue = widget.initialValue;
  }

  void _handleChanged(String value) {
    widget.onChanged(value);
    if (value != _userValue) {
      setState(() => _userValue = value);
    }
  }

  /// Whether this step would actually produce a command.
  ///
  /// Mirrors `QuickSetupViewModel.stepHasChange`: unchanged steps send nothing
  /// (ADR-0006), so an untouched value must never block navigation — the device
  /// may report values the app's own inputs would reject (e.g. an APN that is
  /// not in the dropdown, or an address with no port).
  bool get _willSendCommand {
    final original = widget.currentDeviceValue;
    if (original == null) return _userValue != null;
    return _userValue != null && _userValue != original;
  }

  /// Validation error for the value that would be sent, or null when the step
  /// is safe to leave.
  String? get _validationError {
    if (!_willSendCommand) return null;
    return widget.parameter.validate(_userValue);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canProceed = _validationError == null;

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Text(
            AppStrings.stepNOfTotal(widget.stepIndex + 1, widget.totalSteps),
            style: TextStyle(
              fontSize: DesignTokens.fontS,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),

          // Step title
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: DesignTokens.spacingL),

          // Current device value
          if (widget.currentDeviceValue != null) ...[
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
                      '${AppStrings.currentValue}：${widget.currentDeviceValue}',
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
              if (!widget.isFirst)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onPrevious,
                    child: const Text(AppStrings.previousStep),
                  ),
                ),
              if (!widget.isFirst) SizedBox(width: DesignTokens.spacingM),
              Expanded(
                flex: widget.isFirst ? 1 : 1,
                child: FilledButton(
                  // An invalid value must never reach a deployed device: a
                  // mistyped address costs another site visit to undo.
                  onPressed: canProceed ? widget.onNext : null,
                  child: Text(
                    widget.isLast
                        ? AppStrings.confirmChanges
                        : AppStrings.nextStep,
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
    switch (widget.parameter.type) {
      case ParameterType.dropdown:
        return DropdownParameterInput(
          parameter: widget.parameter,
          onChanged: _handleChanged,
          initialValue: widget.initialValue,
          // The wizard pre-fills from what the device actually reported, so
          // a value outside the option list is real information rather than
          // stale form state — surface it instead of silently selecting the
          // first option.
          warnOnUnmatchedInitialValue: true,
        );
      case ParameterType.hostPort:
        return HostPortParameterInput(
          parameter: widget.parameter,
          onChanged: _handleChanged,
          initialValue: widget.initialValue,
        );
      case ParameterType.hourPicker:
        return HourPickerInput(
          parameter: widget.parameter,
          onChanged: _handleChanged,
          initialValue: widget.initialValue,
        );
      default:
        // Fallback for other types (shouldn't happen in the wizard)
        return Text('Unsupported parameter type: ${widget.parameter.type}');
    }
  }
}
