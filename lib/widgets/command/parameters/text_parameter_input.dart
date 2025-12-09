import 'package:flutter/material.dart';
import '../../../design/design_system.dart';
import '../../../models/command/command_parameter.dart';

/// A text input widget for text parameters.
class TextParameterInput extends StatefulWidget {
  /// The parameter definition.
  final CommandParameter parameter;

  /// Callback when the value changes.
  final ValueChanged<String> onChanged;

  /// Initial value for the input.
  final String? initialValue;

  /// Whether the input is enabled.
  final bool enabled;

  const TextParameterInput({
    super.key,
    required this.parameter,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<TextParameterInput> createState() => _TextParameterInputState();
}

class _TextParameterInputState extends State<TextParameterInput> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue ?? widget.parameter.defaultValue ?? '',
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final value = _controller.text;
    final error = widget.parameter.validate(value);

    if (error != _errorMessage) {
      setState(() {
        _errorMessage = error;
      });
    }

    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = _errorMessage != null;

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

        // Input field
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.parameter.hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: DesignTokens.borderRadiusM,
              borderSide: BorderSide(
                color: hasError ? colorScheme.error : colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DesignTokens.borderRadiusM,
              borderSide: BorderSide(
                color: hasError
                    ? colorScheme.error
                    : colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DesignTokens.borderRadiusM,
              borderSide: BorderSide(
                color: hasError ? colorScheme.error : colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingSM,
            ),
          ),
          style: TextStyle(
            fontSize: DesignTokens.fontM,
            color: colorScheme.onSurface,
          ),
        ),

        // Error message
        if (hasError) ...[
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: DesignTokens.fontS,
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
