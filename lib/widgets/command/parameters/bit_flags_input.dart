import 'package:flutter/material.dart';
import '../../../design/design_system.dart';
import '../../../models/command/command_parameter.dart';

/// A multi-select checkbox widget for bit flag parameters.
class BitFlagsInput extends StatefulWidget {
  /// The parameter definition (must be bitFlags type).
  final CommandParameter parameter;

  /// Callback when the value changes.
  final ValueChanged<String> onChanged;

  /// Initial value for the input (as integer string).
  final String? initialValue;

  /// Whether the input is enabled.
  final bool enabled;

  const BitFlagsInput({
    super.key,
    required this.parameter,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<BitFlagsInput> createState() => _BitFlagsInputState();
}

class _BitFlagsInputState extends State<BitFlagsInput> {
  late int _selectedValue;
  late final List<BitFlagOption> _flags;

  @override
  void initState() {
    super.initState();
    _flags = widget.parameter.bitFlagOptions ?? [];
    _selectedValue = _parseInitialValue();
  }

  int _parseInitialValue() {
    final value = widget.initialValue ?? widget.parameter.defaultValue;
    if (value != null) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed >= 0) {
        return parsed;
      }
    }
    return 0;
  }

  bool _isFlagSelected(BitFlagOption flag) {
    return (_selectedValue & flag.value) == flag.value;
  }

  void _toggleFlag(BitFlagOption flag) {
    if (!widget.enabled) return;

    setState(() {
      if (_isFlagSelected(flag)) {
        _selectedValue &= ~flag.value;
      } else {
        _selectedValue |= flag.value;
      }
    });

    widget.onChanged(_selectedValue.toString());
  }

  List<String> _getSelectedFlagLabels() {
    return _flags
        .where((flag) => _isFlagSelected(flag))
        .map((flag) => flag.label)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final error = widget.parameter.validate(_selectedValue.toString());
    final hasError = error != null;

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

        // Flag checkboxes
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: DesignTokens.borderRadiusM,
            border: Border.all(
              color: hasError
                  ? colorScheme.error
                  : colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _flags.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                _FlagCheckboxTile(
                  flag: _flags[i],
                  isSelected: _isFlagSelected(_flags[i]),
                  enabled: widget.enabled,
                  onToggle: () => _toggleFlag(_flags[i]),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: DesignTokens.spacingS),

        // Calculated value display
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: DesignTokens.borderRadiusS,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: DesignTokens.iconS,
                color: colorScheme.primary,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '計算值: $_selectedValue',
                      style: TextStyle(
                        fontSize: DesignTokens.fontM,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: colorScheme.primary,
                      ),
                    ),
                    if (_selectedValue > 0) ...[
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        _buildCalculationString(),
                        style: TextStyle(
                          fontSize: DesignTokens.fontS,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Selected flags summary
        if (_selectedValue > 0) ...[
          SizedBox(height: DesignTokens.spacingS),
          Wrap(
            spacing: DesignTokens.spacingXS,
            runSpacing: DesignTokens.spacingXS,
            children: [
              for (final label in _getSelectedFlagLabels())
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: DesignTokens.borderRadiusS,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: DesignTokens.fontS,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ],

        // Error message
        if (hasError) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            error,
            style: TextStyle(
              fontSize: DesignTokens.fontS,
              color: colorScheme.error,
            ),
          ),
        ],

        // Hint
        if (widget.parameter.hint != null && !hasError) ...[
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

  String _buildCalculationString() {
    final selectedFlags = _flags.where((flag) => _isFlagSelected(flag)).toList();
    if (selectedFlags.isEmpty) return '';

    return '${selectedFlags.map((flag) => flag.value.toString()).join(' + ')} = $_selectedValue';
  }
}

class _FlagCheckboxTile extends StatelessWidget {
  final BitFlagOption flag;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onToggle;

  const _FlagCheckboxTile({
    required this.flag,
    required this.isSelected,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onToggle : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingS,
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: DesignTokens.durationFast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                  border: Border.all(
                    color: enabled
                        ? (isSelected
                            ? colorScheme.primary
                            : colorScheme.outline)
                        : colorScheme.outline.withValues(alpha: DesignTokens.opacityDisabled),
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
              SizedBox(width: DesignTokens.spacingSM),

              // Label and value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flag.label,
                      style: TextStyle(
                        fontSize: DesignTokens.fontM,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
                      ),
                    ),
                    if (flag.description != null) ...[
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        flag.description!,
                        style: TextStyle(
                          fontSize: DesignTokens.fontS,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Value badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: DesignTokens.borderRadiusS,
                ),
                child: Text(
                  flag.value.toString(),
                  style: TextStyle(
                    fontSize: DesignTokens.fontS,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
