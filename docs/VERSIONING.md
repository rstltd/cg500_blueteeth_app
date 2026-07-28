# Versioning Policy

**Status**: Authoritative. Any change to release format, channel naming, or
release-script CLI must update this document in the same commit.

This project switched from traditional SemVer (`3.4.0+30`) to **Calendar
Versioning (CalVer)** with explicit release channels in May 2026. Apple's own
user-visible version numbers are *not* date-based — they are `MAJOR.MINOR.PATCH`
(e.g. macOS `15.3.1`). The CalVer convention adopted here is the format the
team agreed visually resembles "Apple-style years," and it is widely used by
Ubuntu, JetBrains, and Unity.

---

## 1. Format

### Public version (git tag, GitHub Release title, `pubspec.yaml`)

```
vYY.0M[.MICRO][-PRERELEASE]
```

| Segment       | Meaning                                                    | Example     |
| ------------- | ---------------------------------------------------------- | ----------- |
| `YY`          | Two-digit year (`26` = 2026). No zero-padding required.    | `26`        |
| `0M`          | **Zero-padded** month (`01`–`12`). **Always two digits.**  | `05`, `10`  |
| `MICRO`       | Optional. Same-month hotfix counter starting at `1`.       | `.1`, `.2`  |
| `PRERELEASE`  | Optional. Channel tag — see §2.                            | `-beta.1`   |

### Build number (`pubspec.yaml` only — never in tag, never in release title)

```
vYY.0M[.MICRO][-PRERELEASE]+BUILD
```

`BUILD` is a **monotonically increasing integer**. Android (`versionCode`)
requires it to grow on every install-able artifact, otherwise OTA upgrade is
silently rejected. Beta builds count too — never reset, never decrease.

### Examples

Dart's pubspec parser requires three numeric segments (`MAJOR.MINOR.PATCH`),
so the pubspec form always carries an explicit `.MICRO` (defaulting to `.0`)
even when the corresponding git tag omits it. This is purely a storage detail
— `AppVersion.compareTo` treats missing segments as zero, so `v26.05` and
`26.05.0+31` order identically.

| Tag             | `pubspec.yaml`         | When to use                                  |
| --------------- | ---------------------- | -------------------------------------------- |
| `v26.05`        | `26.05.0+31`           | First stable release of May 2026             |
| `v26.05.1`      | `26.05.1+32`           | Same-month hotfix on top of `v26.05`         |
| `v26.05-beta.1` | `26.05.0-beta.1+30`    | First beta cut for the May 2026 release      |
| `v26.05-beta.2` | `26.05.0-beta.2+33`    | Second beta after `v26.05.1` already shipped |
| `v26.10`        | `26.10.0+40`           | October 2026 stable                          |
| `v27.01`        | `27.01.0+45`           | January 2027 stable                          |

### Examples that are **wrong**

| Wrong              | Why                                                          |
| ------------------ | ------------------------------------------------------------ |
| `v26.5`            | Month must be zero-padded to `05`                            |
| `26.05`            | Tag must include the `v` prefix                              |
| `v2026.05`         | Use two-digit year                                           |
| `v26.05.0`         | Don't add `.0` for the first release of the month            |
| `v26.05-beta`      | Pre-release tag must end with a counter (`-beta.1`)          |
| `v26.05-Beta.1`    | Pre-release tag is **lowercase**                             |
| `v26.05+31`        | `+BUILD` belongs in `pubspec.yaml`, not the git tag          |

---

## 2. Channels

The project ships through two channels. Both flow through the same GitHub
Releases page; the only difference is the tag suffix and the GitHub
*pre-release* flag.

| Channel  | Tag pattern                | GitHub flag    | Audience                |
| -------- | -------------------------- | -------------- | ----------------------- |
| `stable` | `vYY.0M[.MICRO]`           | (none)         | All users by default    |
| `beta`   | `vYY.0M[.MICRO]-beta.N`    | `--prerelease` | Opt-in only             |

Optional intermediate stage:

| Channel  | Tag pattern                | GitHub flag    | Audience                |
| -------- | -------------------------- | -------------- | ----------------------- |
| `rc`     | `vYY.0M[.MICRO]-rc.N`      | `--prerelease` | Opt-in only (treated as beta) |

`rc` exists in the spec for projects that want a feature-freeze step between
beta and stable. The CG500 app currently has no defined RC step — use it only
when the team explicitly decides a release needs one. The in-app channel
selector groups `rc` with `beta`; users who opt into beta receive RC builds
too.

### Ordering (semver pre-release rules)

A version *without* a pre-release tag is **higher** than the same version
*with* one:

```
v26.05-beta.1  <  v26.05-beta.2  <  v26.05-rc.1  <  v26.05  <  v26.05.1
```

Within the same channel, the trailing counter is compared numerically
(`-beta.10` > `-beta.2`).

### Channel selection in the app

`UpdatePreferences.updateChannel` controls which releases the in-app updater
will offer:

- `stable` (default) — only fetches releases without the `-beta`/`-rc` suffix.
  GitHub `prerelease=true` releases are filtered out.
- `beta` — fetches all releases. The most recent one (by version comparison,
  not publish time) wins, regardless of channel.

A user on the beta channel who downgrades to stable will *not* be auto-rolled
back: their installed beta build is still considered "newer than" any prior
stable, so `hasUpdate` stays `false` until a newer stable is published.

---

## 3. Release script CLI

`scripts/simple_release.py` and `scripts/update_version.py` accept the same
mode names. **Always use the script, never edit `pubspec.yaml` by hand.**

| Mode      | What it does                                                                                       | Example transition           |
| --------- | -------------------------------------------------------------------------------------------------- | ---------------------------- |
| `release` | Stable release for the current month. If a stable already exists this month, fails with a hint.    | `26.05.1+32 → 26.06+33`     |
| `hotfix`  | Same-month hotfix on top of the latest stable. Increments `MICRO` (or sets it to `1`).            | `26.05+31 → 26.05.1+32`     |
| `beta`    | Pre-release for the *current* month. Auto-increments the `-beta.N` counter.                       | `26.05+31 → 26.06-beta.1+32`<br>`26.06-beta.1+32 → 26.06-beta.2+33` |
| `rc`      | Pre-release candidate. Same logic as `beta`, but with `-rc.N`.                                    | `26.06-beta.3+35 → 26.06-rc.1+36` |
| `build`   | Build-number-only bump (no version change). For local re-packaging; rarely used in releases.       | `26.05+31 → 26.05+32`        |

The script always increments the build number. Beta and RC modes pass
`--prerelease` to `gh release create`.

### Common command

```pwsh
python3 scripts/simple_release.py release --notes-file release_notes.md --yes
python3 scripts/simple_release.py hotfix  --notes-file release_notes.md --yes
python3 scripts/simple_release.py beta    --notes-file release_notes.md --yes
```

`--yes` skips the confirmation prompt and is required when running from
non-interactive shells (CI, Claude Code's Bash tool).

---

## 4. Transition policy

Legacy SemVer tags (`v3.4.0` and earlier) coexist with CalVer tags. The
in-app `UpdateChecker` parses both and compares them numerically — because
`26 > 3`, every CalVer release outranks every legacy SemVer release without
special-case code.

- **First CalVer release**: cut as `v26.05` (or whichever month). No need for
  a "bridge" version like `v26.05-bridge`.
- **Build number**: do **not** reset across the transition. The first CalVer
  build counter must be `latestSemverBuild + 1` so Android upgrade still
  works (e.g. `3.4.0+30` → `26.05+31`).
- **Old test files** that hard-code `1.0.0` / `3.0.0` are still valid as unit
  tests of the comparator — keep them. They guard against regression in the
  legacy path.

---

## 5. AI / agent operating rules

When the user asks for a release, follow this checklist exactly:

1. Read `pubspec.yaml` to confirm the current version and build number.
2. Run `git log $(git describe --tags --abbrev=0)..HEAD --oneline` and read
   each commit message to decide whether `release`, `hotfix`, `beta`, or
   `rc` is appropriate:
   - **`release`** — every month gets exactly one. If the latest tag is from
     a previous month and contains stable + breaking changes, this is a
     `release`.
   - **`hotfix`** — only `fix:` commits since the last stable, same calendar
     month.
   - **`beta`** — opt-in pre-release. Use when the user explicitly says
     "beta," "pre-release," or "test build."
   - **`rc`** — only when the user explicitly asks. There is no automatic
     promotion from beta to RC.
3. Draft `release_notes.md` in the project root, in **English**, with sections:
   - `## New Features` — `feat:` commits
   - `## Improvements` — `refactor:`, `perf:`, `docs:` commits worth surfacing
   - `## Bug Fixes` — `fix:` commits
   No commit hashes. No internal jargon ("controller", "viewmodel"). Phrase
   from the user's perspective.
4. Show the draft to the user for approval **before** invoking the release
   script. Do not push, tag, or publish without explicit approval.
5. Never edit `pubspec.yaml` by hand to change the version. The script is
   the only authorized writer.
6. Never create a tag that does not match the format in §1. If `git tag`
   reports a mismatched tag, stop and ask.

### Forbidden

- Running `git tag` directly to create a release tag (the script does this).
- Force-pushing tags or amending a published release.
- Skipping `--notes-file` so the script auto-generates notes from commit
  messages — auto-generated notes leak internal jargon to end users.
- Choosing a `beta` channel without the user explicitly asking for one.
- Bumping the major year (`27.xx` instead of `26.xx`) before the calendar
  rolls over.
