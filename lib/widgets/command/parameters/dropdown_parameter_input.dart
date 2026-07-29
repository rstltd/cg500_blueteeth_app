import 'package:flutter/material.dart';
import '../../../design/design_system.dart';
import '../../../l10n/app_strings.dart';
import '../../../models/command/command_parameter.dart';

/// A dropdown widget for selecting from predefined options.
class DropdownParameterInput extends StatefulWidget {
  /// The parameter definition.
  final CommandParameter parameter;

  /// Callback when the value changes.
  final ValueChanged<String> onChanged;

  /// Initial value for the input.
  final String? initialValue;

  /// Whether the input is enabled.
  final bool enabled;

  /// When [initialValue] is non-empty but doesn't match any option, whether
  /// to leave the selection empty (with a warning hint) instead of silently
  /// falling back to the first option.
  ///
  /// Defaults to false so existing callers (e.g. `command_form_sheet.dart`,
  /// where `initialValue` may just be an unset saved/default value) keep
  /// their current "select the first option" behavior. Callers that prefill
  /// from a real device-reported value — where highlighting an option the
  /// device did not actually report would mislead the user — should pass
  /// true.
  final bool warnOnUnmatchedInitialValue;

  const DropdownParameterInput({
    super.key,
    required this.parameter,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
    this.warnOnUnmatchedInitialValue = false,
  });

  @override
  State<DropdownParameterInput> createState() => _DropdownParameterInputState();
}

class _DropdownParameterInputState extends State<DropdownParameterInput> {
  late String? _selectedValue;

  /// True when [widget.warnOnUnmatchedInitialValue] is set and the
  /// device-reported [widget.initialValue] didn't match any option — used to
  /// render the "value not in list" hint instead of highlighting a guess.
  bool _initialValueUnmatched = false;

  List<DropdownOption> get _options => widget.parameter.dropdownOptions ?? [];

  @override
  void initState() {
    super.initState();
    _selectedValue = _parseInitialValue();
  }

  String? _parseInitialValue() {
    final value = widget.initialValue ?? widget.parameter.defaultValue;
    if (value != null && _options.any((o) => o.value == value)) {
      return value;
    }

    if (widget.warnOnUnmatchedInitialValue && value != null && value.isNotEmpty) {
      _initialValueUnmatched = true;
      return null;
    }

    // Default to first option if available
    return _options.isNotEmpty ? _options.first.value : null;
  }

  void _onChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedValue = value;
    });
    widget.onChanged(value);
  }

  DropdownOption? _getSelectedOption() {
    if (_selectedValue == null) return null;
    try {
      return _options.firstWhere((o) => o.value == _selectedValue);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedOption = _getSelectedOption();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.parameter.label,
              style: TextStyle(
                fontSize: DesignTokens.fontM,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            if (widget.parameter.required) ...[
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '*',
                style: TextStyle(
                  fontSize: DesignTokens.fontM,
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),

        // Dropdown options as selectable cards
        ..._options.map((option) => _buildOptionCard(
              context,
              option,
              isSelected: option.value == _selectedValue,
            )),

        // Selected value description
        if (selectedOption?.description != null) ...[
          SizedBox(height: DesignTokens.spacingS),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingSM,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: DesignTokens.borderRadiusS,
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
                    selectedOption!.description!,
                    style: TextStyle(
                      fontSize: DesignTokens.fontS,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Warning: device-reported value doesn't match any option
        if (_initialValueUnmatched) ...[
          SizedBox(height: DesignTokens.spacingS),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingSM,
            ),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: DesignTokens.borderRadiusS,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: DesignTokens.iconS,
                  color: colorScheme.error,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    AppStrings.dropdownUnmatchedValueWarning(
                      widget.initialValue ?? '',
                    ),
                    style: TextStyle(
                      fontSize: DesignTokens.fontS,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Hint
        if (widget.parameter.hint != null) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            widget.parameter.hint!,
            style: TextStyle(
              fontSize: DesignTokens.fontS,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    DropdownOption option, {
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? () => _onChanged(option.value) : null,
          borderRadius: DesignTokens.borderRadiusS,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: DesignTokens.borderRadiusS,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
                SizedBox(width: DesignTokens.spacingM),

                // Option content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: DesignTokens.fontM,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: widget.enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(
                                  alpha: DesignTokens.opacityDisabled),
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        option.value,
                        style: TextStyle(
                          fontSize: DesignTokens.fontS,
                          fontFamily: 'monospace',
                          color: widget.enabled
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: DesignTokens.opacityDisabled),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
