import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../design/design_system.dart';
import '../../../models/command/command_parameter.dart';

/// A specialized input widget for IP:Port parameters.
///
/// Provides separate fields for IP octets and port number with validation.
class IpPortParameterInput extends StatefulWidget {
  /// The parameter definition.
  final CommandParameter parameter;

  /// Callback when the value changes.
  final ValueChanged<String> onChanged;

  /// Initial value for the input (format: "IP:Port").
  final String? initialValue;

  /// Whether the input is enabled.
  final bool enabled;

  const IpPortParameterInput({
    super.key,
    required this.parameter,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<IpPortParameterInput> createState() => _IpPortParameterInputState();
}

class _IpPortParameterInputState extends State<IpPortParameterInput> {
  late final List<TextEditingController> _ipControllers;
  late final TextEditingController _portController;
  late final List<FocusNode> _ipFocusNodes;
  late final FocusNode _portFocusNode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _ipControllers = List.generate(4, (_) => TextEditingController());
    _portController = TextEditingController();

    // Initialize focus nodes
    _ipFocusNodes = List.generate(4, (_) => FocusNode());
    _portFocusNode = FocusNode();

    // Parse initial value
    _parseInitialValue(
        widget.initialValue ?? widget.parameter.defaultValue ?? '');

    // Add listeners
    for (final controller in _ipControllers) {
      controller.addListener(_onValueChanged);
    }
    _portController.addListener(_onValueChanged);
  }

  void _parseInitialValue(String value) {
    if (value.isEmpty) return;

    final parts = value.split(':');
    if (parts.length == 2) {
      final ipParts = parts[0].split('.');
      if (ipParts.length == 4) {
        for (int i = 0; i < 4; i++) {
          _ipControllers[i].text = ipParts[i];
        }
      }
      _portController.text = parts[1];
    }
  }

  @override
  void dispose() {
    for (final controller in _ipControllers) {
      controller.removeListener(_onValueChanged);
      controller.dispose();
    }
    _portController.removeListener(_onValueChanged);
    _portController.dispose();

    for (final node in _ipFocusNodes) {
      node.dispose();
    }
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
    final ip = _ipControllers.map((c) => c.text).join('.');
    final port = _portController.text;

    // Only return value if we have some input
    if (_ipControllers.every((c) => c.text.isEmpty) && port.isEmpty) {
      return '';
    }

    return '$ip:$port';
  }

  void _onIpOctetChanged(int index, String value) {
    // Auto-advance to next field when 3 digits entered or . is typed
    if (value.length == 3 || value.endsWith('.')) {
      final cleanValue = value.replaceAll('.', '');
      _ipControllers[index].text = cleanValue;
      _ipControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: cleanValue.length),
      );

      if (index < 3) {
        _ipFocusNodes[index + 1].requestFocus();
      } else {
        _portFocusNode.requestFocus();
      }
    }
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

        // IP Address section
        Text(
          'IP 位址',
          style: TextStyle(
            fontSize: DesignTokens.fontS,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
                  child: Text(
                    '.',
                    style: TextStyle(
                      fontSize: DesignTokens.fontL,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: _buildIpOctetField(context, i, hasError),
              ),
            ],
          ],
        ),

        SizedBox(height: DesignTokens.spacingM),

        // Port section
        Text(
          'Port',
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

  Widget _buildIpOctetField(BuildContext context, int index, bool hasError) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _ipControllers[index],
      focusNode: _ipFocusNodes[index],
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        _IpOctetInputFormatter(),
      ],
      onChanged: (value) => _onIpOctetChanged(index, value),
      decoration: InputDecoration(
        hintText: '0',
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

/// Input formatter for IP octets (0-255).
class _IpOctetInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleanText = newValue.text.replaceAll('.', '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final num = int.tryParse(cleanText);
    if (num == null) {
      return oldValue;
    }

    if (num > 255) {
      return oldValue;
    }

    return newValue.copyWith(text: cleanText);
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
