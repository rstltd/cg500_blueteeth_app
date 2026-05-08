import 'package:flutter/material.dart';

/// Identifies an RST device family member from its BLE advertising name.
///
/// `RstDeviceType` is **scanner-display only**: it drives the leading icon,
/// type-grouped list ordering, and the optional whitelist filter. It must
/// NOT drive the command repository, `$INFO` parsing, or wizard-step
/// composition. See [`docs/adr/0008-scanner-device-type-filter-no-profile.md`]
/// for the full scope rationale.
enum RstDeviceType {
  gnss,
  accelerometer,
  inclinometer,
  unknown,
}

/// Canonical prefix → device type table. The inclinometer entry is
/// intentionally absent: as of 2026-05 no prefix has been assigned (see
/// CONTEXT.md "Flagged ambiguities"), but the enum value is reserved so
/// callers can render an inclinometer icon once the prefix arrives.
const Map<String, RstDeviceType> _devicePrefixMap = {
  'A01LT': RstDeviceType.gnss,
  'B01LT': RstDeviceType.accelerometer,
};

/// Classify a BLE device by its advertising name.
///
/// Match is case-insensitive (`name.toUpperCase().startsWith(prefix)`).
/// Whitespace is **not** trimmed — broadcast names with leading whitespace
/// indicate a firmware bug we want surfaced, not silently corrected.
/// Empty input maps to [RstDeviceType.unknown].
RstDeviceType classifyDeviceType(String name) {
  if (name.isEmpty) return RstDeviceType.unknown;
  final upper = name.toUpperCase();
  for (final entry in _devicePrefixMap.entries) {
    if (upper.startsWith(entry.key)) return entry.value;
  }
  return RstDeviceType.unknown;
}

/// The canonical leading icon for a device type, parameterised by
/// connection state.
///
/// Known types use the same icon shape regardless of state (color signals
/// connection elsewhere). [RstDeviceType.unknown] preserves the historical
/// `bluetooth` ↔ `bluetooth_connected` swap so the existing UX for
/// non-RST devices does not regress.
IconData iconForDeviceType(RstDeviceType type, {required bool connected}) {
  switch (type) {
    case RstDeviceType.gnss:
      return Icons.satellite_alt;
    case RstDeviceType.accelerometer:
      return Icons.vibration;
    case RstDeviceType.inclinometer:
      return Icons.architecture;
    case RstDeviceType.unknown:
      return connected ? Icons.bluetooth_connected : Icons.bluetooth;
  }
}
