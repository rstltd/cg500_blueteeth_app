import '../models/device_info.dart';
import '../utils/logger.dart';

/// Stateless regex-based extractor that maps a single CG500 $INFO response
/// line onto fields of [DeviceInfo].
///
/// The device responds to $INFO with multiple lines of the form
/// `KEY:VALUE` (sometimes `KEY=VALUE`). [DeviceInfoTracker] feeds each
/// arriving line through [updateFromLine] so the accumulated [DeviceInfo]
/// reflects the most recent values seen on the wire.
class InfoParserService {
  InfoParserService._();

  // ---- Patterns (case-insensitive, trimmed) ----

  static final _fwPattern = RegExp(
    r'(?:FW|Firmware)\s*(?:name\s*)?[:=]\s*(.+)',
    caseSensitive: false,
  );
  static final _apnPattern = RegExp(
    r'APN\s*[:=]\s*(\S+)',
    caseSensitive: false,
  );
  // Only match "Target Addr" or a standalone "ADDR" at the start of the
  // line — NOT substrings like "Command Addr" or "Wifi Address".
  static final _addrPattern = RegExp(
    r'(?:^ADDR\b|Target\s+Addr)\s*[:=]\s*(.+)',
    caseSensitive: false,
  );
  static final _ftpAddrPattern = RegExp(
    r'(?:FTPADDR|FTP\s*ADDR|Prog\s*Address)\s*[:=]\s*(.+)',
    caseSensitive: false,
  );
  static final _rebootPattern = RegExp(
    r'(?:REBOOT|Reset\s*hour)\s*[:=]\s*(\d+)',
    caseSensitive: false,
  );
  static final _imeiPattern = RegExp(
    r'IMEI\s*[:=]\s*(\d{10,20})',
    caseSensitive: false,
  );
  static final _macPattern = RegExp(
    r'MAC\s*[:=]\s*([0-9A-Fa-f:]{17})',
    caseSensitive: false,
  );

  /// Incrementally update a [DeviceInfo] with a single new response line.
  /// Returns a new [DeviceInfo] if the line matched any field, or the
  /// original instance if nothing changed.
  static DeviceInfo updateFromLine(DeviceInfo current, String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return current;

    final fw = _extract(_fwPattern, line);
    final apn = _extract(_apnPattern, line);
    final ftpAddr = _extract(_ftpAddrPattern, line);
    final addr = ftpAddr == null ? _extract(_addrPattern, line) : null;

    // Diagnostic: log lines that contain "addr" (case-insensitive) to help
    // debug field-name mismatches with the actual device output.
    if (line.toLowerCase().contains('addr')) {
      Logger.diagnostic(
        '[INFO_PARSER] addr-related line: "$line" → '
        'ftpAddr=$ftpAddr, addr=$addr',
      );
    }
    final rebootHour = _extract(_rebootPattern, line);
    final imei = _extract(_imeiPattern, line);
    final mac = _extract(_macPattern, line);

    if (fw == null &&
        apn == null &&
        addr == null &&
        ftpAddr == null &&
        rebootHour == null &&
        imei == null &&
        mac == null) {
      return current;
    }

    return current.copyWith(
      firmwareName: fw,
      apn: apn,
      addr: addr,
      ftpAddr: ftpAddr,
      rebootHour: rebootHour,
      imei: imei,
      mac: mac,
    );
  }

  static String? _extract(RegExp pattern, String line) {
    final match = pattern.firstMatch(line);
    return match?.group(1)?.trim();
  }
}
