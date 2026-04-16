/// Structured device information parsed from a $INFO response.
///
/// Each field is nullable because the device may not include every line
/// in its response, and the parser applies best-effort regex matching.
class DeviceInfo {
  final String? firmwareName;
  final String? apn;
  final String? addr;
  final String? ftpAddr;
  final String? rebootHour;
  final String? imei;
  final String? mac;

  /// Every recognized KEY:VALUE pair from the raw response.
  final Map<String, String> raw;

  const DeviceInfo({
    this.firmwareName,
    this.apn,
    this.addr,
    this.ftpAddr,
    this.rebootHour,
    this.imei,
    this.mac,
    this.raw = const {},
  });

  /// Create a copy with selected fields replaced.
  DeviceInfo copyWith({
    String? firmwareName,
    String? apn,
    String? addr,
    String? ftpAddr,
    String? rebootHour,
    String? imei,
    String? mac,
    Map<String, String>? raw,
  }) {
    return DeviceInfo(
      firmwareName: firmwareName ?? this.firmwareName,
      apn: apn ?? this.apn,
      addr: addr ?? this.addr,
      ftpAddr: ftpAddr ?? this.ftpAddr,
      rebootHour: rebootHour ?? this.rebootHour,
      imei: imei ?? this.imei,
      mac: mac ?? this.mac,
      raw: raw ?? this.raw,
    );
  }
}
