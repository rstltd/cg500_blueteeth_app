import '../models/device_info.dart';

/// Stateless service that parses CG500 $INFO response lines into a
/// structured [DeviceInfo].
///
/// The device typically responds to $INFO with multiple lines of the form
/// `KEY:VALUE` (sometimes `KEY=VALUE`). This parser applies a set of
/// regex patterns to extract known fields, and stores every recognized
/// pair in [DeviceInfo.raw] for transparency.
///
/// Usage:
/// ```dart
/// final info = InfoParserService.parse(responseLines);
/// print(info.apn);  // e.g. 'internet'
/// ```
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
  static final _addrPattern = RegExp(
    r'ADDR\s*[:=]\s*(.+)',
    caseSensitive: false,
  );
  static final _ftpAddrPattern = RegExp(
    r'(?:FTPADDR|FTP\s*ADDR)\s*[:=]\s*(.+)',
    caseSensitive: false,
  );
  static final _rebootPattern = RegExp(
    r'REBOOT\s*[:=]\s*(\d+)',
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

  /// Generic KEY:VALUE or KEY=VALUE splitter for the raw map.
  static final _kvPattern = RegExp(r'^([A-Za-z0-9_ ]+)\s*[:=]\s*(.+)$');

  /// Parse a list of $INFO response lines into [DeviceInfo].
  static DeviceInfo parse(List<String> lines) {
    String? fw;
    String? apn;
    String? addr;
    String? ftpAddr;
    String? rebootHour;
    String? imei;
    String? mac;
    final raw = <String, String>{};

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Store raw key-value pair
      final kvMatch = _kvPattern.firstMatch(line);
      if (kvMatch != null) {
        raw[kvMatch.group(1)!.trim()] = kvMatch.group(2)!.trim();
      }

      // Try each specific pattern — use "last wins" so the most recent
      // $INFO response overwrites values from earlier ones.
      fw = _extract(_fwPattern, line) ?? fw;
      apn = _extract(_apnPattern, line) ?? apn;
      // FTPADDR must be checked BEFORE ADDR because ADDR pattern would
      // also match FTPADDR lines.
      final ftpMatch = _extract(_ftpAddrPattern, line);
      if (ftpMatch != null) {
        ftpAddr = ftpMatch;
      } else {
        addr = _extract(_addrPattern, line) ?? addr;
      }
      rebootHour = _extract(_rebootPattern, line) ?? rebootHour;
      imei = _extract(_imeiPattern, line) ?? imei;
      mac = _extract(_macPattern, line) ?? mac;
    }

    return DeviceInfo(
      firmwareName: fw,
      apn: apn,
      addr: addr,
      ftpAddr: ftpAddr,
      rebootHour: rebootHour,
      imei: imei,
      mac: mac,
      raw: raw,
    );
  }

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
