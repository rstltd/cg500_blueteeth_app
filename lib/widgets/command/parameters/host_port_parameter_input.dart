import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../design/design_system.dart';
import '../../../models/command/command_parameter.dart';

/// A specialized input widget for Host:Port parameters.
///
/// Supports both IP addresses (e.g., 192.168.1.1) and domain names (e.g., rmdgnss.com).
/// Note: Domain names should NOT include http/https prefix (used for TCP, not HTTP).
class HostPortParameterInput extends StatefulWidget {
  /// The parameter definition.
  final CommandParameter parameter;

  /// Callback when the value changes.
  final ValueChanged<String> onChanged;

  /// Initial value for the input (format: "Host:Port").
  final String? initialValue;

  /// Whether the input is enabled.
  final bool enabled;

  const HostPortParameterInput({
    super.key,
    required this.parameter,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<HostPortParameterInput> createState() => _HostPortParameterInputState();
}

class _HostPortParameterInputState extends State<HostPortParameterInput> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final FocusNode _hostFocusNode;
  late final FocusNode _portFocusNode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _hostController = TextEditingController();
    _portController = TextEditingController();

    // Initialize focus nodes
    _hostFocusNode = FocusNode();
    _portFocusNode = FocusNode();

    // Parse initial value
    _parseInitialValue(
        widget.initialValue ?? widget.parameter.defaultValue ?? '');

    // Add listeners
    _hostController.addListener(_onValueChanged);
    _portController.addListener(_onValueChanged);
  }

  void _parseInitialValue(String value) {
    if (value.isEmpty) return;

    final colonIndex = value.lastIndexOf(':');
    if (colonIndex > 0) {
      _hostController.text = value.substring(0, colonIndex);
      _portController.text = value.substring(colonIndex + 1);
    }
  }

  @override
  void dispose() {
    _hostController.removeListener(_onValueChanged);
    _hostController.dispose();
    _portController.removeListener(_onValueChanged);
    _portController.dispose();

    _hostFocusNode.dispose();
    _portFocusNode.dispose();

    super.dispose();
  }

  void _onValueChanged() {
    final value = _buildValue();
    final error = widget.parameter.validate(value);

    if (error != _errorMessage) {
      setState(() {
        _errorMessage = error;
      });
    }

    widget.onChanged(value);
  }

  String _buildValue() {
    final host = _hostController.text.trim();
    final port = _portController.text.trim();

    // Only return value if we have some input
    if (host.isEmpty && port.isEmpty) {
      return '';
    }

    // Port is optional — omit the colon when no port is provided
    if (port.isEmpty) {
      return host;
    }

    return '$host:$port';
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

        // Host section (IP or Domain)
        Text(
          '主機位址 (IP 或網域)',
          style: TextStyle(
            fontSize: DesignTokens.fontS,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        _buildHostField(context, hasError),

        SizedBox(height: DesignTokens.spacingM),

        // Port section (optional)
        Text(
          'Port（選填）',
          style: TextStyle(
            fontSize: DesignTokens.fontS,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        SizedBox(
          width: 120,
          child: _buildPortField(context, hasError),
        ),

        // Error message
        if (hasError) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            _errorMessage!,
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

  Widget _buildHostField(BuildContext context, bool hasError) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _hostController,
      focusNode: _hostFocusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _portFocusNode.requestFocus(),
      inputFormatters: [
        // Prevent http:// or https:// prefix
        _HostInputFormatter(),
      ],
      decoration: InputDecoration(
        hintText: 'rmdgnss.com 或 192.168.1.1',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusS,
          borderSide: BorderSide(
            color: hasError ? colorScheme.error : colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusS,
          borderSide: BorderSide(
            color: hasError
                ? colorScheme.error
                : colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusS,
          borderSide: BorderSide(
            color: hasError ? colorScheme.error : colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSM,
          vertical: DesignTokens.spacingSM,
        ),
        isDense: true,
      ),
      style: TextStyle(
        fontSize: DesignTokens.fontM,
        color: colorScheme.onSurface,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildPortField(BuildContext context, bool hasError) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _portController,
      focusNode: _portFocusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _PortInputFormatter(),
      ],
      decoration: InputDecoration(
        hintText: '8080',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusS,
          borderSide: BorderSide(
            color: hasError ? colorScheme.error : colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusS,
          borderSide: BorderSide(
            color: hasError
                ? colorScheme.error
                : colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusS,
          borderSide: BorderSide(
            color: hasError ? colorScheme.error : colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingSM,
        ),
        isDense: true,
      ),
      style: TextStyle(
        fontSize: DesignTokens.fontM,
        color: colorScheme.onSurface,
        fontFamily: 'monospace',
      ),
    );
  }
}

/// Input formatter that prevents http:// or https:// prefix and spaces.
class _HostInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove http:// or https:// if user tries to paste it
    text = text.replaceAll(RegExp(r'^https?://', caseSensitive: false), '');

    // Remove spaces
    text = text.replaceAll(' ', '');

    if (text == newValue.text) {
      return newValue;
    }

    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Input formatter for ports (1-65535).
class _PortInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final num = int.tryParse(newValue.text);
    if (num == null) {
      return oldValue;
    }

    if (num > 65535) {
      return oldValue;
    }

    return newValue;
  }
}
