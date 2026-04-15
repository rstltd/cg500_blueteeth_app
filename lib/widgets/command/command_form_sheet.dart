import 'package:flutter/material.dart';
import '../../services/command_parameter_storage_service.dart';
import '../../design/design_system.dart';
import '../../models/command/command.dart';
import '../../l10n/app_strings.dart';
import 'command_preview_widget.dart';
import 'parameters/text_parameter_input.dart';
import 'parameters/ip_port_parameter_input.dart';
import 'parameters/host_port_parameter_input.dart';
import 'parameters/hour_picker_input.dart';
import 'parameters/bit_flags_input.dart';
import 'parameters/dropdown_parameter_input.dart';

/// A bottom sheet for entering command parameters.
class CommandFormSheet extends StatefulWidget {
  /// The command to configure.
  final DeviceCommand command;

  /// Callback when the command is submitted.
  final ValueChanged<String> onSubmit;

  /// Whether the device is connected.
  final bool isConnected;

  /// Initial parameter values.
  final Map<String, String>? initialValues;

  /// Whether to load saved parameters from storage.
  final bool loadSavedParameters;

  /// Optional storage service for testing.
  final CommandParameterStorageService? storageService;

  const CommandFormSheet({
    super.key,
    required this.command,
    required this.onSubmit,
    this.isConnected = false,
    this.initialValues,
    this.loadSavedParameters = true,
    this.storageService,
  });

  /// Shows the command form as a modal bottom sheet.
  /// Returns the command string if submitted, null if cancelled.
  ///
  /// The [storageService] is required for parameter persistence.
  /// It should be obtained from the ViewModel, not directly from getIt.
  static Future<String?> show({
    required BuildContext context,
    required DeviceCommand command,
    required CommandParameterStorageService storageService,
    bool isConnected = false,
    Map<String, String>? initialValues,
    bool loadSavedParameters = true,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommandFormSheet(
        command: command,
        onSubmit: (commandString) => Navigator.of(context).pop(commandString),
        isConnected: isConnected,
        initialValues: initialValues,
        loadSavedParameters: loadSavedParameters,
        storageService: storageService,
      ),
    );
  }

  @override
  State<CommandFormSheet> createState() => _CommandFormSheetState();
}

class _CommandFormSheetState extends State<CommandFormSheet> {
  late final Map<String, String> _parameterValues;
  bool _hasSavedParameters = false;

  /// Storage service from widget (required for production, optional for testing).
  CommandParameterStorageService? get _storageService => widget.storageService;

  @override
  void initState() {
    super.initState();
    _parameterValues = _loadInitialValues();
  }

  Map<String, String> _loadInitialValues() {
    // Priority: initialValues > saved parameters > default values
    if (widget.initialValues != null) {
      return Map.from(widget.initialValues!);
    }

    if (widget.loadSavedParameters && _storageService?.isInitialized == true) {
      final saved = _storageService!.getParameters(widget.command.command);
      if (saved != null && saved.isNotEmpty) {
        _hasSavedParameters = true;
        // Merge with defaults to handle any new parameters
        final defaults = widget.command.getDefaultValues();
        return {...defaults, ...saved};
      }
    }

    return Map.from(widget.command.getDefaultValues());
  }

  void _onParameterChanged(String parameterId, String value) {
    setState(() {
      _parameterValues[parameterId] = value;
    });
  }

  bool get _isValid {
    final errors = widget.command.validateParameters(_parameterValues);
    return errors.isEmpty;
  }

  void _onSubmit() {
    if (!_isValid) return;

    // Save parameters for next time
    _saveParameters();

    final commandString = widget.command.buildCommandString(
      _parameterValues,
      throwOnMissing: true,
    );
    widget.onSubmit(commandString);
  }

  Future<void> _saveParameters() async {
    if (_storageService?.isInitialized == true) {
      await _storageService!.saveParameters(
        widget.command.command,
        _parameterValues,
      );
    }
  }

  void _clearSavedParameters() async {
    if (_storageService?.isInitialized == true) {
      await _storageService!.clearParameters(widget.command.command);
      setState(() {
        _hasSavedParameters = false;
        _parameterValues.clear();
        _parameterValues.addAll(widget.command.getDefaultValues());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildDragHandle(colorScheme),

          // Header
          _buildHeader(context),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: DesignTokens.spacingM,
                right: DesignTokens.spacingM,
                bottom: bottomPadding + DesignTokens.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Command info
                  CommandInfoWidget(
                    command: widget.command,
                    compact: false,
                  ),
                  SizedBox(height: DesignTokens.spacingL),

                  // Offline edit hint — let users prefill parameters before connecting
                  if (!widget.isConnected) ...[
                    _buildOfflineHint(context),
                    SizedBox(height: DesignTokens.spacingM),
                  ],

                  // Saved parameters indicator
                  if (_hasSavedParameters) ...[
                    _buildSavedParametersIndicator(context),
                    SizedBox(height: DesignTokens.spacingM),
                  ],

                  // Parameter inputs
                  ...widget.command.parameters.map((param) => Padding(
                        padding: EdgeInsets.only(bottom: DesignTokens.spacingL),
                        child: _buildParameterInput(param),
                      )),

                  // Command preview
                  CommandPreviewWidget(
                    command: widget.command,
                    parameterValues: _parameterValues,
                    showCopyButton: true,
                  ),
                  SizedBox(height: DesignTokens.spacingL),

                  // Action buttons
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(top: DesignTokens.spacingSM),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: DesignTokens.borderRadiusFull,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingM,
        DesignTokens.spacingM,
        DesignTokens.spacingS,
        DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_note,
            size: DesignTokens.iconM,
            color: colorScheme.primary,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.setParameters,
                  style: TextStyle(
                    fontSize: DesignTokens.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.command.name,
                  style: TextStyle(
                    fontSize: DesignTokens.fontS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: AppStrings.close,
          ),
        ],
      ),
    );
  }

  Widget _buildParameterInput(CommandParameter parameter) {
    final initialValue = _parameterValues[parameter.id] ?? '';

    switch (parameter.type) {
      case ParameterType.text:
        return TextParameterInput(
          parameter: parameter,
          onChanged: (value) => _onParameterChanged(parameter.id, value),
          initialValue: initialValue,
        );

      case ParameterType.ipPort:
        return IpPortParameterInput(
          parameter: parameter,
          onChanged: (value) => _onParameterChanged(parameter.id, value),
          initialValue: initialValue,
        );

      case ParameterType.hostPort:
        return HostPortParameterInput(
          parameter: parameter,
          onChanged: (value) => _onParameterChanged(parameter.id, value),
          initialValue: initialValue,
        );

      case ParameterType.number:
        return TextParameterInput(
          parameter: parameter,
          onChanged: (value) => _onParameterChanged(parameter.id, value),
          initialValue: initialValue,
        );

      case ParameterType.hourPicker:
        return HourPickerInput(
          parameter: parameter,
          onChanged: (value) => _onParameterChanged(parameter.id, value),
          initialValue: initialValue,
        );

      case ParameterType.bitFlags:
        return BitFlagsInput(
          parameter: parameter,
          onChanged: (value) => _onParameterChanged(parameter.id, value),
          initialValue: initialValue,
        );

      case ParameterType.dropdown:
        return DropdownParameterInput(
          parameter: parameter,
          onChanged: (value) => _onParameterChanged(parameter.id, value),
          initialValue: initialValue,
        );
    }
  }

  Widget _buildOfflineHint(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingSM,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: DesignTokens.borderRadiusS,
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: DesignTokens.iconS,
            color: colorScheme.tertiary,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              AppStrings.offlineEditHint,
              style: TextStyle(
                fontSize: DesignTokens.fontS,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedParametersIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingSM,
      ),
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
            Icons.history,
            size: DesignTokens.iconS,
            color: colorScheme.primary,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              AppStrings.lastParametersLoaded,
              style: TextStyle(
                fontSize: DesignTokens.fontS,
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _clearSavedParameters,
            icon: Icon(
              Icons.refresh,
              size: DesignTokens.iconS,
            ),
            label: Text(AppStrings.reset),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSubmit = widget.isConnected && _isValid;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingSM),
              side: BorderSide(color: colorScheme.outline),
            ),
            child: Text(AppStrings.cancel),
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: canSubmit ? _onSubmit : null,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingSM),
              backgroundColor: widget.command.dangerLevel == DangerLevel.dangerous
                  ? colorScheme.error
                  : null,
            ),
            icon: Icon(
              widget.command.dangerLevel == DangerLevel.dangerous
                  ? Icons.warning_amber_rounded
                  : Icons.send,
              size: DesignTokens.iconS,
            ),
            label: Text(
              widget.isConnected ? AppStrings.sendCommand : AppStrings.deviceNotConnected,
            ),
          ),
        ),
      ],
    );
  }
}
