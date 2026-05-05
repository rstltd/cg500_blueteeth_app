/// Version parsing and comparison shared between [UpdateInfo] and
/// [UpdateChecker]. Handles both the new CalVer format
/// (`vYY.0M[.MICRO][-beta.N|-rc.N][+BUILD]`) and legacy SemVer
/// (`MAJOR.MINOR.PATCH[+BUILD]`).
///
/// See `docs/VERSIONING.md` for the authoritative format spec.
class AppVersion {
  /// Numeric segments before any pre-release tag (e.g. `[26, 5, 1]` for
  /// `26.05.1-beta.2`, `[3, 4, 0]` for `3.4.0`). At least one element.
  final List<int> mainParts;

  /// Pre-release channel name (`beta`, `rc`, `alpha`, ...) or `null` for stable.
  final String? prerelease;

  /// Pre-release counter (`-beta.N`). `0` when [prerelease] is null.
  final int prereleaseN;

  /// `+BUILD` suffix or `null` if absent.
  final int? build;

  const AppVersion({
    required this.mainParts,
    this.prerelease,
    this.prereleaseN = 0,
    this.build,
  });

  /// Parses [raw], tolerating an optional leading `v` and trailing whitespace.
  /// Returns `null` if the string is not a recognisable version.
  static AppVersion? tryParse(String raw) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    if (s.isEmpty) return null;

    // Split off +BUILD first.
    int? build;
    final plusIdx = s.indexOf('+');
    if (plusIdx >= 0) {
      final buildStr = s.substring(plusIdx + 1);
      build = int.tryParse(buildStr);
      if (build == null) return null;
      s = s.substring(0, plusIdx);
    }

    // Split off -PRERELEASE.
    String? prerelease;
    var prereleaseN = 0;
    final dashIdx = s.indexOf('-');
    if (dashIdx >= 0) {
      final preStr = s.substring(dashIdx + 1);
      s = s.substring(0, dashIdx);
      // Expect "name.N", e.g. "beta.1". Reject malformed forms — the tag/parser
      // contract requires the counter so ordering is well-defined.
      final dotIdx = preStr.indexOf('.');
      if (dotIdx <= 0 || dotIdx == preStr.length - 1) return null;
      prerelease = preStr.substring(0, dotIdx).toLowerCase();
      final nStr = preStr.substring(dotIdx + 1);
      final n = int.tryParse(nStr);
      if (n == null || n < 0) return null;
      prereleaseN = n;
    }

    // Parse main parts.
    final parts = s.split('.');
    if (parts.isEmpty || parts.any((p) => p.isEmpty)) return null;
    final mainParts = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      mainParts.add(n);
    }

    return AppVersion(
      mainParts: mainParts,
      prerelease: prerelease,
      prereleaseN: prereleaseN,
      build: build,
    );
  }

  /// Whether this is a pre-release (beta/rc/alpha).
  bool get isPrerelease => prerelease != null;

  /// SemVer pre-release ordering: a version *without* a pre-release tag is
  /// considered higher than one with a pre-release tag of the same main parts.
  /// Within pre-releases, channel names are compared alphabetically
  /// (`alpha` < `beta` < `rc`) and then by counter.
  ///
  /// Build numbers are compared only when both sides have one *and* the
  /// main parts plus pre-release tags are identical. When only one side has a
  /// build number we treat it as equal — this preserves backward compatibility
  /// with the legacy GitHub tag format (`v3.3.0`) vs. the in-app version with
  /// build (`3.3.0+29`).
  int compareTo(AppVersion other) {
    final maxLen = mainParts.length > other.mainParts.length
        ? mainParts.length
        : other.mainParts.length;
    for (var i = 0; i < maxLen; i++) {
      final a = i < mainParts.length ? mainParts[i] : 0;
      final b = i < other.mainParts.length ? other.mainParts[i] : 0;
      if (a != b) return a.compareTo(b);
    }

    // Main parts equal — apply pre-release ordering.
    if (prerelease == null && other.prerelease == null) {
      // Fall through to build comparison.
    } else if (prerelease == null) {
      return 1; // stable > pre-release
    } else if (other.prerelease == null) {
      return -1; // pre-release < stable
    } else {
      final nameCmp = prerelease!.compareTo(other.prerelease!);
      if (nameCmp != 0) return nameCmp;
      final nCmp = prereleaseN.compareTo(other.prereleaseN);
      if (nCmp != 0) return nCmp;
    }

    // Main + pre-release equal — compare builds only when both present.
    if (build != null && other.build != null) {
      return build!.compareTo(other.build!);
    }
    return 0;
  }

  @override
  String toString() {
    final base = mainParts.join('.');
    final pre = prerelease == null ? '' : '-$prerelease.$prereleaseN';
    final b = build == null ? '' : '+$build';
    return '$base$pre$b';
  }
}
