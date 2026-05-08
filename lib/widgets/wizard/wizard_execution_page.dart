import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';
import '../../models/device_info.dart';
import '../../view_models/quick_setup_view_model.dart';

/// Displays the execution progress or the final result.
///
/// During [WizardPhase.executing]: shows a list of commands with checkmarks,
/// spinners, and greyed-out states.
/// During [WizardPhase.done]: shows the updated device info summary; when
///   [willReboot] is true, also shows the reboot-in-progress banner.
/// During [WizardPhase.failed]: shows the failure message with a retry hint.
class WizardExecutionPage extends StatelessWidget {
  const WizardExecutionPage({
    super.key,
    required this.phase,
    required this.commands,
    required this.executingIndex,
    this.willReboot = false,
    this.failureMessage,
    this.updatedInfo,
    this.onFinish,
    this.onBack,
  });

  final WizardPhase phase;
  final List<SetupCommand> commands;
  final int executingIndex;
  final bool willReboot;
  final String? failureMessage;
  final DeviceInfo? updatedInfo;
  final VoidCallback? onFinish;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: DesignTokens.spacingL),
          if (phase == WizardPhase.done && willReboot) ...[
            _buildRebootBanner(context),
            SizedBox(height: DesignTokens.spacingM),
          ],
          if (phase == WizardPhase.done && updatedInfo != null)
            Expanded(child: _buildDeviceInfoSummary(context))
          else
            Expanded(child: _buildCommandList(context)),
          SizedBox(height: DesignTokens.spacingM),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final IconData icon;
    final String title;
    final Color color;

    switch (phase) {
      case WizardPhase.executing:
        icon = Icons.sync;
        title = AppStrings.executing;
        color = Theme.of(context).colorScheme.primary;
        break;
      case WizardPhase.done:
        icon = Icons.check_circle;
        title = AppStrings.setupComplete;
        color = AppColors.successColor(context);
        break;
      case WizardPhase.failed:
        icon = Icons.error;
        title = AppStrings.setupFailed;
        color = Theme.of(context).colorScheme.error;
        break;
      default:
        icon = Icons.help;
        title = '';
        color = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, size: 32, color: color),
        SizedBox(width: DesignTokens.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              if (phase == WizardPhase.failed && failureMessage != null)
                Text(
                  AppStrings.failedAt(failureMessage!),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: DesignTokens.fontS,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommandList(BuildContext context) {
    // Commands + $INFO + (optionally) $STARTX. When the run has zero
    // diffed commands, we never reach this method (the VM short-circuits
    // straight to `done` per ADR-0007).
    final infoStepIndex = commands.length;
    final rebootStepIndex = commands.length + 1;
    final totalItems = commands.length + 1 + (willReboot ? 1 : 0);

    return ListView.separated(
      itemCount: totalItems,
      separatorBuilder: (_, __) => SizedBox(height: DesignTokens.spacingS),
      itemBuilder: (context, index) {
        final String label;
        final String cmdStr;

        if (index == rebootStepIndex && willReboot) {
          label = AppStrings.wizardRebootRowLabel;
          cmdStr = r'$STARTX';
        } else if (index == infoStepIndex) {
          label = r'$INFO（確認結果）';
          cmdStr = r'$INFO';
        } else {
          label = commands[index].label;
          cmdStr = commands[index].commandString;
        }

        final _StepStatus status;
        if (index < executingIndex) {
          status = _StepStatus.done;
        } else if (index == executingIndex) {
          status = phase == WizardPhase.failed
              ? _StepStatus.failed
              : _StepStatus.running;
        } else {
          status = _StepStatus.pending;
        }

        return _CommandRow(
          label: label,
          commandString: cmdStr,
          status: status,
        );
      },
    );
  }

  /// Banner surfaced on the done screen explaining that the device is
  /// already rebooting (per ADR-0007). Only shown when the run actually
  /// dispatched a `$STARTX`.
  Widget _buildRebootBanner(BuildContext context) {
    final color = AppColors.warningColor(context);
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warningContainer(context),
        borderRadius: DesignTokens.borderRadiusM,
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.power_settings_new, color: color),
          SizedBox(width: DesignTokens.spacingSM),
          Expanded(
            child: Text(
              AppStrings.wizardDoneWithRebootBanner,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: DesignTokens.fontS,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoSummary(BuildContext context) {
    final info = updatedInfo!;
    final entries = <MapEntry<String, String>>[];

    if (info.firmwareName != null) {
      entries.add(MapEntry('FW', info.firmwareName!));
    }
    if (info.apn != null) entries.add(MapEntry('APN', info.apn!));
    if (info.addr != null) entries.add(MapEntry('ADDR', info.addr!));
    if (info.ftpAddr != null) {
      entries.add(MapEntry('FTPADDR', info.ftpAddr!));
    }
    if (info.rebootHour != null) {
      entries.add(MapEntry('REBOOT', '${info.rebootHour} 時'));
    }
    if (info.imei != null) entries.add(MapEntry('IMEI', info.imei!));

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final e = entries[index];
        return ListTile(
          dense: true,
          title: Text(
            e.key,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: DesignTokens.fontS,
            ),
          ),
          trailing: Text(
            e.value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: DesignTokens.fontS,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    if (phase == WizardPhase.executing) {
      return LinearProgressIndicator(
        value: commands.isEmpty
            ? 0
            : executingIndex / (commands.length + 1),
      );
    }

    if (phase == WizardPhase.done) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onFinish,
          child: const Text(AppStrings.finish),
        ),
      );
    }

    // Failed
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            child: const Text(AppStrings.backToModify),
          ),
        ),
      ],
    );
  }
}

enum _StepStatus { pending, running, done, failed }

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.label,
    required this.commandString,
    required this.status,
  });

  final String label;
  final String commandString;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color textColor;
    final Widget leading;

    switch (status) {
      case _StepStatus.done:
        textColor = AppColors.successColor(context);
        leading = Icon(Icons.check_circle, color: textColor, size: 20);
        break;
      case _StepStatus.running:
        textColor = colorScheme.primary;
        leading = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(textColor),
          ),
        );
        break;
      case _StepStatus.failed:
        textColor = colorScheme.error;
        leading = Icon(Icons.error, color: textColor, size: 20);
        break;
      case _StepStatus.pending:
        textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
        leading = Icon(Icons.circle_outlined, color: textColor, size: 20);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingSM,
      ),
      decoration: BoxDecoration(
        color: status == _StepStatus.running
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: DesignTokens.borderRadiusS,
      ),
      child: Row(
        children: [
          leading,
          SizedBox(width: DesignTokens.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  commandString,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: DesignTokens.fontS,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
