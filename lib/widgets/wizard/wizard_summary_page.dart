import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';
import '../../view_models/quick_setup_view_model.dart';

/// The confirmation page shown before executing commands.
///
/// Displays a diff of changed settings (old → new) and lets the user
/// go back to modify or confirm execution. When nothing changed, shows
/// a friendly "nothing to do" message.
class WizardSummaryPage extends StatelessWidget {
  const WizardSummaryPage({
    super.key,
    required this.commands,
    required this.hasAnyChange,
    required this.onConfirm,
    required this.onBack,
  });

  final List<SetupCommand> commands;
  final bool hasAnyChange;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.confirmChanges,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: DesignTokens.spacingL),

          if (!hasAnyChange) ...[
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 72,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    AppStrings.noChangesDetected,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ] else ...[
            Expanded(
              child: ListView.separated(
                itemCount: commands.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: DesignTokens.spacingSM),
                itemBuilder: (context, index) =>
                    _buildChangeCard(context, commands[index]),
              ),
            ),
          ],

          SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text(AppStrings.backToModify),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              if (hasAnyChange)
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    child: const Text(AppStrings.confirmAndExecute),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeCard(BuildContext context, SetupCommand cmd) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: DesignTokens.borderRadiusM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cmd.label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontM,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Expanded(
                child: Text(
                  cmd.oldValue,
                  style: TextStyle(
                    color: colorScheme.error,
                    decoration: TextDecoration.lineThrough,
                    fontSize: DesignTokens.fontS,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
                child: Icon(
                  Icons.arrow_forward,
                  size: DesignTokens.iconS,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  cmd.newValue,
                  style: TextStyle(
                    color: AppColors.successColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontS,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
