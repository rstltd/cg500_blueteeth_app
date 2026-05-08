import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// AppBar action button that toggles the RST whitelist filter on the
/// scanner. Visible icon and tooltip switch with the [enabled] state
/// (per ADR-0008): `filter_alt` when on, `filter_alt_off` when off.
///
/// Extracted from `SimpleScannerView` so widget tests can exercise it
/// without booting the entire scanner view + ViewModelProvider stack.
class ScannerWhitelistToggleButton extends StatelessWidget {
  const ScannerWhitelistToggleButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(enabled ? Icons.filter_alt : Icons.filter_alt_off),
      tooltip: enabled
          ? AppStrings.scannerWhitelistFilterEnabledTooltip
          : AppStrings.scannerWhitelistFilterDisabledTooltip,
      onPressed: onPressed,
    );
  }
}
