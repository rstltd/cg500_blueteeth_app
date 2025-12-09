import 'package:flutter/material.dart';
import '../../../design/design_system.dart';
import '../../../models/command/command_parameter.dart';

/// A wheel picker widget for selecting hours (0-23).
class HourPickerInput extends StatefulWidget {
  /// The parameter definition.
  final CommandParameter parameter;

  /// Callback when the value changes.
  final ValueChanged<String> onChanged;

  /// Initial value for the input.
  final String? initialValue;

  /// Whether the input is enabled.
  final bool enabled;

  const HourPickerInput({
    super.key,
    required this.parameter,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<HourPickerInput> createState() => _HourPickerInputState();
}

class _HourPickerInputState extends State<HourPickerInput> {
  late int _selectedHour;
  late final FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedHour = _parseInitialValue();
    _scrollController = FixedExtentScrollController(initialItem: _selectedHour);
  }

  int _parseInitialValue() {
    final value = widget.initialValue ?? widget.parameter.defaultValue;
    if (value != null) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed >= 0 && parsed <= 23) {
        return parsed;
      }
    }
    return 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onHourChanged(int hour) {
    setState(() {
      _selectedHour = hour;
    });
    widget.onChanged(hour.toString());
  }

  String _getTimeDescription(int hour) {
    if (hour >= 0 && hour < 6) return '凌晨';
    if (hour >= 6 && hour < 12) return '上午';
    if (hour >= 12 && hour < 18) return '下午';
    return '晚上';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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

        // Hour picker
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: DesignTokens.borderRadiusM,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            children: [
              // Selection indicator
              Center(
                child: Container(
                  height: 48,
                  margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: DesignTokens.borderRadiusS,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),

              // Wheel picker
              ListWheelScrollView.useDelegate(
                controller: _scrollController,
                itemExtent: 48,
                diameterRatio: 1.5,
                physics: widget.enabled
                    ? const FixedExtentScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                onSelectedItemChanged: widget.enabled ? _onHourChanged : null,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (context, index) {
                    final isSelected = index == _selectedHour;
                    return _HourItem(
                      hour: index,
                      isSelected: isSelected,
                      enabled: widget.enabled,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: DesignTokens.spacingS),

        // Selected value display
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: DesignTokens.iconS,
                color: colorScheme.primary,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                '${_selectedHour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: DesignTokens.fontL,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                _getTimeDescription(_selectedHour),
                style: TextStyle(
                  fontSize: DesignTokens.fontM,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

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
}

class _HourItem extends StatelessWidget {
  final int hour;
  final bool isSelected;
  final bool enabled;

  const _HourItem({
    required this.hour,
    required this.isSelected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        style: TextStyle(
          fontSize: isSelected ? DesignTokens.fontTitle : DesignTokens.fontL,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
          color: enabled
              ? (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)
              : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
        ),
        child: Text('${hour.toString().padLeft(2, '0')}:00'),
      ),
    );
  }
}

/// A compact hour picker with increment/decrement buttons.
class CompactHourPickerInput extends StatefulWidget {
  /// The parameter definition.
  final CommandParameter parameter;

  /// Callback when the value changes.
  final ValueChanged<String> onChanged;

  /// Initial value for the input.
  final String? initialValue;

  /// Whether the input is enabled.
  final bool enabled;

  const CompactHourPickerInput({
    super.key,
    required this.parameter,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<CompactHourPickerInput> createState() => _CompactHourPickerInputState();
}

class _CompactHourPickerInputState extends State<CompactHourPickerInput> {
  late int _selectedHour;

  @override
  void initState() {
    super.initState();
    _selectedHour = _parseInitialValue();
  }

  int _parseInitialValue() {
    final value = widget.initialValue ?? widget.parameter.defaultValue;
    if (value != null) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed >= 0 && parsed <= 23) {
        return parsed;
      }
    }
    return 0;
  }

  void _increment() {
    if (!widget.enabled) return;
    setState(() {
      _selectedHour = (_selectedHour + 1) % 24;
    });
    widget.onChanged(_selectedHour.toString());
  }

  void _decrement() {
    if (!widget.enabled) return;
    setState(() {
      _selectedHour = (_selectedHour - 1 + 24) % 24;
    });
    widget.onChanged(_selectedHour.toString());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.enabled ? _decrement : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: colorScheme.primary,
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: DesignTokens.borderRadiusS,
          ),
          child: Text(
            '${_selectedHour.toString().padLeft(2, '0')}:00',
            style: TextStyle(
              fontSize: DesignTokens.fontL,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: widget.enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.enabled ? _increment : null,
          icon: const Icon(Icons.add_circle_outline),
          color: colorScheme.primary,
        ),
      ],
    );
  }
}
