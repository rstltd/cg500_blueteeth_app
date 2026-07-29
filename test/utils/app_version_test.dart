import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/utils/app_version.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('parses a bare CalVer version', () {
      final v = AppVersion.tryParse('26.06');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 6]);
      expect(v.prerelease, isNull);
      expect(v.prereleaseN, 0);
      expect(v.build, isNull);
    });

    test('tolerates a leading lowercase v', () {
      final v = AppVersion.tryParse('v26.06');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 6]);
    });

    test('tolerates a leading uppercase V', () {
      final v = AppVersion.tryParse('V26.06');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 6]);
    });

    test('trims surrounding whitespace', () {
      final v = AppVersion.tryParse('  v26.06  ');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 6]);
    });

    test('parses MICRO segment', () {
      final v = AppVersion.tryParse('26.05.1');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 5, 1]);
    });

    test('parses a +BUILD suffix', () {
      final v = AppVersion.tryParse('26.05.0+31');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 5, 0]);
      expect(v.build, 31);
    });

    test('parses a pre-release channel and counter', () {
      final v = AppVersion.tryParse('26.06-beta.1');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 6]);
      expect(v.prerelease, 'beta');
      expect(v.prereleaseN, 1);
      expect(v.isPrerelease, isTrue);
    });

    test('parses pre-release plus build together', () {
      final v = AppVersion.tryParse('26.05.0-beta.2+33');

      expect(v, isNotNull);
      expect(v!.mainParts, [26, 5, 0]);
      expect(v.prerelease, 'beta');
      expect(v.prereleaseN, 2);
      expect(v.build, 33);
    });

    test('lowercases the pre-release channel name', () {
      // The tag format itself forbids uppercase (`v26.05-Beta.1` is invalid
      // per docs/VERSIONING.md), but the parser still normalises defensively.
      final v = AppVersion.tryParse('26.05-BETA.1');

      expect(v, isNotNull);
      expect(v!.prerelease, 'beta');
    });

    test('rejects an empty string', () {
      expect(AppVersion.tryParse(''), isNull);
    });

    test('rejects a string that is only the v prefix', () {
      expect(AppVersion.tryParse('v'), isNull);
    });

    test('rejects non-numeric garbage', () {
      expect(AppVersion.tryParse('not-a-version'), isNull);
    });

    test('parses a bare integer as a single main part', () {
      final v = AppVersion.tryParse('123');

      expect(v, isNotNull);
      expect(v!.mainParts, [123]);
    });

    test('rejects a pre-release tag missing its counter', () {
      // docs/VERSIONING.md and the inline comment above the dotIdx check both
      // say the counter is required so ordering is well-defined.
      expect(AppVersion.tryParse('26.06-beta'), isNull);
    });

    test('rejects a pre-release tag with an empty channel name', () {
      expect(AppVersion.tryParse('26.06-.1'), isNull);
    });

    test('rejects a pre-release counter that is not numeric', () {
      expect(AppVersion.tryParse('26.06-beta.x'), isNull);
    });

    test('rejects a negative pre-release counter', () {
      expect(AppVersion.tryParse('26.06-beta.-1'), isNull);
    });

    test('rejects a non-numeric build number', () {
      expect(AppVersion.tryParse('26.06+abc'), isNull);
    });

    test('rejects a negative main-part segment', () {
      expect(AppVersion.tryParse('26.-5'), isNull);
    });

    test('rejects a main part with an empty segment (double dot)', () {
      expect(AppVersion.tryParse('26..5'), isNull);
    });
  });

  group('AppVersion.compareTo — stable vs pre-release', () {
    test('a stable release outranks a beta of the same version', () {
      final stable = AppVersion.tryParse('26.06')!;
      final beta = AppVersion.tryParse('26.06-beta.1')!;

      expect(stable.compareTo(beta) > 0, isTrue,
          reason: '26.06 must be considered newer than 26.06-beta.1');
      expect(beta.compareTo(stable) < 0, isTrue);
    });

    test('rc outranks beta of the same version', () {
      final rc = AppVersion.tryParse('26.06-rc.1')!;
      final beta = AppVersion.tryParse('26.06-beta.5')!;

      expect(rc.compareTo(beta) > 0, isTrue,
          reason: '26.06-rc.1 must be considered newer than 26.06-beta.5');
    });

    test('full pre-release ladder from docs/VERSIONING.md orders correctly',
        () {
      // v26.05-beta.1 < v26.05-beta.2 < v26.05-rc.1 < v26.05 < v26.05.1
      final beta1 = AppVersion.tryParse('26.05-beta.1')!;
      final beta2 = AppVersion.tryParse('26.05-beta.2')!;
      final rc1 = AppVersion.tryParse('26.05-rc.1')!;
      final stable = AppVersion.tryParse('26.05')!;
      final hotfix = AppVersion.tryParse('26.05.1')!;

      expect(beta1.compareTo(beta2) < 0, isTrue);
      expect(beta2.compareTo(rc1) < 0, isTrue);
      expect(rc1.compareTo(stable) < 0, isTrue);
      expect(stable.compareTo(hotfix) < 0, isTrue);
    });
  });

  group('AppVersion.compareTo — pre-release counter is numeric, not lexical',
      () {
    test('beta.2 is less than beta.10 (numeric, not string, comparison)', () {
      final beta2 = AppVersion.tryParse('26.06-beta.2')!;
      final beta10 = AppVersion.tryParse('26.06-beta.10')!;

      // A naive string comparison of "2" vs "10" would say "10" < "2"
      // because '1' < '2' lexically. The counter must be compared as an int.
      expect(beta2.compareTo(beta10) < 0, isTrue,
          reason: 'beta.10 must be newer than beta.2 under numeric ordering');
      expect(beta10.compareTo(beta2) > 0, isTrue);
    });
  });

  group('AppVersion.compareTo — main-part ordering', () {
    test('MICRO increments rank higher than the base release', () {
      final base = AppVersion.tryParse('26.05')!;
      final hotfix = AppVersion.tryParse('26.05.1')!;

      expect(base.compareTo(hotfix) < 0, isTrue);
      expect(hotfix.compareTo(base) > 0, isTrue);
    });

    test('month ordering does not fall into the "09" vs "10" string trap',
        () {
      final sep = AppVersion.tryParse('26.09')!;
      final oct = AppVersion.tryParse('26.10')!;

      // A string comparison of "09" vs "10" would (correctly, by luck)
      // still order '0' < '1', but a comparison of the raw un-padded
      // segments as strings ("9" vs "10") would say "10" < "9". This
      // exercises the parser's guarantee that segments are compared as
      // ints, not strings.
      expect(sep.compareTo(oct) < 0, isTrue,
          reason: '26.09 must be older than 26.10');
    });

    test('year rollover orders December before next January', () {
      final dec = AppVersion.tryParse('26.12')!;
      final jan = AppVersion.tryParse('27.01')!;

      expect(dec.compareTo(jan) < 0, isTrue);
    });

    test('missing trailing segments are treated as zero', () {
      // docs/VERSIONING.md: "v26.05 and 26.05.0+31 order identically"
      // because AppVersion.compareTo treats missing segments as zero.
      final short = AppVersion.tryParse('26.05')!;
      final long = AppVersion.tryParse('26.05.0')!;

      expect(short.compareTo(long), 0);
    });
  });

  group('AppVersion — case-insensitive v/V prefix equivalence', () {
    test('V26.05 and v26.05 parse to an equal version', () {
      final upper = AppVersion.tryParse('V26.05')!;
      final lower = AppVersion.tryParse('v26.05')!;

      expect(upper.compareTo(lower), 0);
      expect(upper.mainParts, lower.mainParts);
    });
  });

  group('AppVersion.compareTo — build numbers', () {
    test('build numbers only break ties when both sides have one', () {
      final withBuild = AppVersion.tryParse('26.05.0+40')!;
      final withHigherBuild = AppVersion.tryParse('26.05.0+41')!;

      expect(withBuild.compareTo(withHigherBuild) < 0, isTrue);
    });

    test(
        'legacy tag without a build (v3.3.0) compares equal to the in-app '
        'version with a build (3.3.0+29) — backward-compat rule from the '
        'class doc comment', () {
      final tagOnly = AppVersion.tryParse('3.3.0')!;
      final withBuild = AppVersion.tryParse('3.3.0+29')!;

      expect(tagOnly.compareTo(withBuild), 0);
      expect(withBuild.compareTo(tagOnly), 0);
    });
  });

  group('AppVersion.compareTo — legacy SemVer vs CalVer transition', () {
    test('every CalVer release outranks every legacy SemVer release', () {
      // docs/VERSIONING.md §4: "because 26 > 3, every CalVer release
      // outranks every legacy SemVer release without special-case code."
      final legacy = AppVersion.tryParse('3.4.0+30')!;
      final calver = AppVersion.tryParse('26.05+31')!;

      expect(legacy.compareTo(calver) < 0, isTrue);
    });

    test('legacy SemVer PATCH ordering still works (regression guard)', () {
      final v1 = AppVersion.tryParse('1.0.0')!;
      final v2 = AppVersion.tryParse('1.0.1')!;

      expect(v1.compareTo(v2) < 0, isTrue);
    });
  });

  group('AppVersion.toString', () {
    test('round-trips a stable version with no build', () {
      final v = AppVersion.tryParse('26.06')!;

      expect(v.toString(), '26.6');
    });

    test('round-trips a pre-release version with a build', () {
      final v = AppVersion.tryParse('26.05.0-beta.2+33')!;

      expect(v.toString(), '26.5.0-beta.2+33');
    });
  });
}
