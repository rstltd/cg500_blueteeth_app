#!/usr/bin/env python3

"""
CG500 BLE App Release Script (CalVer-aware)

Builds and publishes releases to GitHub. Versioning policy is documented in
docs/VERSIONING.md — read it before changing anything in this file.

Format: vYY.0M[.MICRO][-beta.N | -rc.N] (+BUILD in pubspec.yaml only).

Modes:
  release  Stable monthly release            (e.g. 26.05+31 -> 26.06+32)
  hotfix   Same-month hotfix on stable       (e.g. 26.05+31 -> 26.05.1+32)
  beta     Pre-release (GitHub prerelease=true)
  rc       Release candidate (GitHub prerelease=true)
  build    Bump build number only (no version change)

Prerequisites:
  1. GitHub CLI (https://cli.github.com/) authenticated via `gh auth login`
  2. Flutter SDK on PATH

Options:
  --force        Skip uncommitted changes check
  --clean        Run `flutter clean` before build
  --yes          Skip confirmation prompt (required for non-interactive shells)
  --notes-file   Path to a markdown file with user-facing release notes
  --allow-branch Skip the branch check and allow releasing from a non-main branch
"""

import os
import sys
import subprocess
import hashlib
import argparse
import re
import shutil
import tempfile
from dataclasses import dataclass, replace
from datetime import datetime
from pathlib import Path
from typing import Optional

# Force UTF-8 for stdout/stderr on every platform. On Traditional Chinese
# Windows this avoids "'cp950' codec can't encode character" when printing
# captured flutter / pub output containing box-drawing characters. On Linux the
# same crash happens under a C/POSIX locale (minimal cron or systemd units),
# because generate_release_notes() embeds raw git commit subjects and this
# repo's history contains em dashes. Mirrors the same fix in update_version.py.
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')  # type: ignore[attr-defined]
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')  # type: ignore[attr-defined]
except AttributeError:
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.detach(), errors='replace')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.detach(), errors='replace')

# --- Version parsing ---------------------------------------------------------

CALVER_RE = re.compile(
    r'^(\d{2,})\.(\d{2})(?:\.(\d+))?(?:-(beta|rc)\.(\d+))?(?:\+(\d+))?$'
)
LEGACY_RE = re.compile(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$')

# Two-digit year range that is unambiguously CalVer. The first CalVer release
# is May 2026, so we accept 24..99 to leave room for older imports without
# colliding with legacy `3.x.y` tags. Years <20 are always parsed as legacy.
_CALVER_YEAR_MIN = 24
_CALVER_YEAR_MAX = 99

VALID_CHANNELS = ('stable', 'beta', 'rc')


@dataclass
class Version:
    """Versioning model that handles both CalVer and legacy semver.

    CalVer fields (`year`, `month`, `micro`, `channel`, `channel_n`) are valid
    when `fmt == 'calver'`. Legacy fields (`major`, `minor`, `patch`) are valid
    when `fmt == 'legacy'`. `build` and `fmt` are always set.
    """

    fmt: str = 'calver'  # 'calver' | 'legacy'
    # CalVer
    year: Optional[int] = None
    month: Optional[int] = None
    micro: int = 0  # 0 means "no .MICRO in tag"
    channel: str = 'stable'  # 'stable' | 'beta' | 'rc'
    channel_n: int = 0  # 0 means stable; otherwise -beta.N / -rc.N
    # Legacy semver
    major: Optional[int] = None
    minor: Optional[int] = None
    patch: Optional[int] = None
    # Both
    build: int = 0

    @classmethod
    def parse(cls, raw: str) -> 'Version':
        s = raw.strip()
        m = CALVER_RE.match(s)
        if m:
            year = int(m.group(1))
            if _CALVER_YEAR_MIN <= year <= _CALVER_YEAR_MAX:
                channel = m.group(4) or 'stable'
                channel_n = int(m.group(5)) if m.group(5) else 0
                return cls(
                    fmt='calver',
                    year=year,
                    month=int(m.group(2)),
                    micro=int(m.group(3)) if m.group(3) else 0,
                    channel=channel,
                    channel_n=channel_n,
                    build=int(m.group(6)) if m.group(6) else 0,
                )
        m = LEGACY_RE.match(s)
        if m:
            return cls(
                fmt='legacy',
                major=int(m.group(1)),
                minor=int(m.group(2)),
                patch=int(m.group(3)),
                build=int(m.group(4)) if m.group(4) else 0,
            )
        raise ValueError(
            f"Invalid version format: {raw!r}. Expected vYY.0M[.MICRO][-beta.N|-rc.N][+BUILD] "
            f"or legacy MAJOR.MINOR.PATCH[+BUILD]"
        )

    def to_tag(self) -> str:
        """Git-tag form (with `v` prefix, no build number)."""
        if self.fmt == 'legacy':
            return f"v{self.major}.{self.minor}.{self.patch}"
        s = f"v{self.year}.{self.month:02d}"
        if self.micro > 0:
            s += f".{self.micro}"
        if self.channel != 'stable':
            s += f"-{self.channel}.{self.channel_n}"
        return s

    def to_pubspec(self) -> str:
        """`pubspec.yaml` form. Dart's pubspec parser requires three numeric
        segments (`MAJOR.MINOR.PATCH`), so CalVer versions always emit `.MICRO`
        here (defaulting to `.0`) even though [to_tag] omits the `.0` for the
        first release of the month. The two forms compare as equal in
        [AppVersion.compareTo] because missing segments are treated as zero.
        """
        if self.fmt == 'legacy':
            base = f"{self.major}.{self.minor}.{self.patch}"
        else:
            base = f"{self.year}.{self.month:02d}.{self.micro}"
            if self.channel != 'stable':
                base += f"-{self.channel}.{self.channel_n}"
        return f"{base}+{self.build}" if self.build > 0 else base

    @property
    def is_prerelease(self) -> bool:
        return self.fmt == 'calver' and self.channel != 'stable'


def _today_yy_mm():
    now = datetime.now()
    return (now.year % 100), now.month


def next_version(current: Version, mode: str) -> Version:
    """Compute the next version for `mode` based on the current pubspec version.

    Raises ValueError with an actionable hint when the mode is not applicable to
    the current state (e.g. hotfix on a beta).
    """
    next_build = current.build + 1
    today_y, today_m = _today_yy_mm()

    if mode == 'release':
        if (
            current.fmt == 'calver'
            and current.year == today_y
            and current.month == today_m
            and current.channel == 'stable'
        ):
            raise ValueError(
                f"Current version {current.to_tag()} is already a stable release for "
                f"{today_y:02d}.{today_m:02d}. Use 'hotfix' to bump the micro counter, "
                f"or wait for next month."
            )
        return Version(
            fmt='calver',
            year=today_y,
            month=today_m,
            micro=0,
            channel='stable',
            channel_n=0,
            build=next_build,
        )

    if mode == 'hotfix':
        if current.fmt == 'legacy':
            raise ValueError(
                f"Cannot hotfix legacy version {current.to_tag()}. Use 'release' to cut "
                f"the first CalVer release for this month."
            )
        if current.channel != 'stable':
            raise ValueError(
                f"Hotfix requires a stable base. Current version {current.to_tag()} is "
                f"on the '{current.channel}' channel. Use 'release' to ship a stable "
                f"first, or stay on '{current.channel}' to keep iterating."
            )
        if current.year != today_y or current.month != today_m:
            raise ValueError(
                f"Hotfix month mismatch: current is {current.year:02d}.{current.month:02d} "
                f"but today is {today_y:02d}.{today_m:02d}. A hotfix patches the *current "
                f"month's* stable. For a new month, use 'release' instead."
            )
        return Version(
            fmt='calver',
            year=current.year,
            month=current.month,
            micro=current.micro + 1,
            channel='stable',
            channel_n=0,
            build=next_build,
        )

    if mode == 'beta':
        if current.fmt == 'calver' and current.channel == 'beta':
            # NOTE: `year`/`month` here are the *target release month*, not
            # the month this beta build is being cut in (see docs/VERSIONING.md
            # section 1, "PRERELEASE"). A beta cycle that spans a calendar-month
            # boundary (e.g. `26.06-beta.1` cut in June, `26.06-beta.2` cut in
            # July) intentionally keeps incrementing channel_n against the
            # original target month rather than resetting -- mirrors the `rc`
            # promotion branch below, which also carries the target
            # year/month/micro forward unchanged.
            return replace(current, channel_n=current.channel_n + 1, build=next_build)
        # Start a fresh beta cycle for today's month.
        return Version(
            fmt='calver',
            year=today_y,
            month=today_m,
            micro=0,
            channel='beta',
            channel_n=1,
            build=next_build,
        )

    if mode == 'rc':
        if current.fmt == 'calver' and current.channel == 'rc':
            return replace(current, channel_n=current.channel_n + 1, build=next_build)
        if current.fmt == 'calver' and current.channel == 'beta':
            # Promote: keep target year/month/micro, fresh rc counter.
            return replace(current, channel='rc', channel_n=1, build=next_build)
        return Version(
            fmt='calver',
            year=today_y,
            month=today_m,
            micro=0,
            channel='rc',
            channel_n=1,
            build=next_build,
        )

    if mode == 'build':
        return replace(current, build=next_build)

    raise ValueError(f"Unknown mode: {mode}")


# --- Release manager ---------------------------------------------------------


class SimpleReleaseManager:
    def __init__(self, project_root: Optional[Path] = None):
        # `main()` resolves this once (anchored to the script's own location,
        # not the process CWD) and passes it in, so the prerequisite checks
        # there and every git/build operation here agree on the same repo
        # root. The fallback keeps direct instantiation (e.g. from a REPL or
        # a future test) working the same way `main()` does.
        self.project_root = (
            project_root if project_root is not None
            else Path(__file__).resolve().parent.parent
        )
        self.pubspec_path = self.project_root / 'pubspec.yaml'
        self.build_dir = self.project_root / 'build' / 'app' / 'outputs' / 'flutter-apk'

    # --- Pubspec I/O ---

    def get_current_version(self) -> Version:
        if not self.pubspec_path.exists():
            raise FileNotFoundError("pubspec.yaml not found")
        with open(self.pubspec_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('version:'):
                    return Version.parse(line.split(':', 1)[1].strip())
        raise ValueError("Version not found in pubspec.yaml")

    def update_version_in_pubspec(self, new_version: Version):
        with open(self.pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = re.sub(
            r'^version:\s*.+$',
            f'version: {new_version.to_pubspec()}',
            content,
            flags=re.MULTILINE,
        )
        with open(self.pubspec_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"[OK] Updated version to {new_version.to_pubspec()} in {self.pubspec_path.name}")

    def update_version(self, mode: str) -> Version:
        current = self.get_current_version()
        print(f"[INFO] Current version: {current.to_pubspec()}")
        new_version = next_version(current, mode)
        print(f"[INFO] New version    : {new_version.to_pubspec()} (tag {new_version.to_tag()})")
        if new_version.is_prerelease:
            print(f"[INFO] Channel        : {new_version.channel} (will be marked as GitHub pre-release)")
        self.update_version_in_pubspec(new_version)
        return new_version

    # --- Subprocess helpers ---

    def _run(self, cmd, **kwargs):
        """Run subprocess with UTF-8 to avoid Windows cp950 errors.

        Every caller passes an argv list, so `shell` must stay False. On POSIX,
        subprocess.run(list, shell=True) executes only cmd[0] and demotes the
        rest to $0/$1... of /bin/sh -- which turns `gh release create ...` into
        a bare `gh` that prints its help banner and exits 0, i.e. a release that
        reports success but never happened. shell=True was originally there so
        Windows could resolve `flutter.bat`; shutil.which() honours PATHEXT and
        returns that full path, which works fine with shell=False.
        """
        kwargs.setdefault('shell', False)
        kwargs.setdefault('encoding', 'utf-8')
        kwargs.setdefault('errors', 'replace')
        if not kwargs['shell'] and isinstance(cmd, (list, tuple)) and cmd:
            resolved = shutil.which(cmd[0])
            if resolved:
                cmd = [resolved, *cmd[1:]]
        return subprocess.run(cmd, **kwargs)

    # --- Quality gates ---

    def run_quality_checks(self):
        os.chdir(self.project_root)

        # --no-fatal-infos: `flutter analyze` (unlike `dart analyze`) exits
        # non-zero for info-level issues too. Errors and warnings still block a
        # release; style hints and deprecation notices should not.
        print("[INFO] Running flutter analyze...")
        result = self._run(
            ['flutter', 'analyze', '--no-fatal-infos'], capture_output=True
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr)
            raise RuntimeError("flutter analyze failed -- fix issues before releasing")
        print("[OK] Static analysis passed")

        print("[INFO] Running flutter test...")
        result = self._run(['flutter', 'test'], capture_output=True)
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr)
            raise RuntimeError("flutter test failed -- fix tests before releasing")
        print("[OK] All tests passed")

    # --- Build ---

    def build_release_apk(self, clean: bool = False) -> Path:
        print("[INFO] Building release APK...")
        os.chdir(self.project_root)

        if clean:
            print("[INFO] Cleaning previous builds (--clean flag)...")
            self._run(['flutter', 'clean'], check=True)

        self._run(['flutter', 'pub', 'get'], check=True)

        print("[INFO] Building APK (this may take a few minutes)...")
        result = self._run(['flutter', 'build', 'apk', '--release'], capture_output=True)
        if result.returncode != 0:
            raise RuntimeError(f"APK build failed: {result.stderr}")

        # Pick the release APK explicitly — the build dir may also contain
        # stale debug APKs from prior `flutter run` sessions, and glob('*.apk')
        # would pick app-debug.apk first alphabetically.
        release_apk = self.build_dir / 'app-release.apk'
        if release_apk.exists():
            apk_path = release_apk
        else:
            apk_files = list(self.build_dir.glob('*.apk'))
            if not apk_files:
                raise FileNotFoundError("No APK file found after build")
            apk_path = apk_files[0]
        size_mb = apk_path.stat().st_size / 1024 / 1024
        print(f"[OK] APK built: {apk_path} ({size_mb:.1f} MB)")
        return apk_path

    def rename_apk_for_release(self, apk_path: Path, version: Version) -> Path:
        # Strip the `v` for the filename (kept consistent with existing artifact
        # naming so older release assets remain searchable).
        tag_no_v = version.to_tag().lstrip('v')
        new_name = f"cg500_ble_app_v{tag_no_v}.apk"
        new_path = apk_path.parent / new_name
        if new_path.exists():
            new_path.unlink()
        apk_path.rename(new_path)
        print(f"[OK] APK renamed to: {new_name}")
        return new_path

    # --- Release notes ---

    def calculate_sha256(self, file_path: Path) -> str:
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        checksum = sha256_hash.hexdigest()
        print(f"[OK] SHA256 checksum calculated: {checksum[:16]}...")
        return checksum

    def _find_gh_command(self):
        possible_paths = ['gh']
        if sys.platform == 'win32':
            possible_paths += [
                'C:\\Program Files\\GitHub CLI\\gh.exe',
                'C:\\Program Files (x86)\\GitHub CLI\\gh.exe',
            ]
        for gh_path in possible_paths:
            try:
                self._run([gh_path, '--version'], capture_output=True, check=True)
                return gh_path
            except (subprocess.CalledProcessError, FileNotFoundError):
                continue
        return None

    def generate_release_notes(self, version: Version, sha256_checksum=None, apk_size_mb=None) -> str:
        """Auto-generate release notes from git commit log. Used as a fallback when
        no `--notes-file` is provided. Quality is poor (raw commit subjects); prefer
        a curated `release_notes.md`.
        """
        try:
            result = subprocess.run(
                ['git', 'describe', '--tags', '--abbrev=0'],
                capture_output=True, text=True, cwd=self.project_root,
            )
            last_tag = result.stdout.strip() if result.returncode == 0 else None

            if last_tag:
                cmd = ['git', 'log', f'{last_tag}..HEAD', '--oneline']
            else:
                cmd = ['git', 'log', '--oneline', '-10']
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            commits = result.stdout.strip().split('\n') if result.stdout.strip() else []

            tag = version.to_tag()
            channel_label = ' (pre-release)' if version.is_prerelease else ''
            notes = [
                f"## CG500 BLE App {tag}{channel_label}",
                "",
                f"Released: {datetime.now().strftime('%Y-%m-%d %H:%M UTC')}",
                "",
                "### Changes in this version:",
            ]
            if commits:
                for commit in commits[:10]:
                    if commit.strip():
                        notes.append(f"* {commit}")
            else:
                notes.append("* Bug fixes and improvements")

            notes.extend([
                "",
                "### Installation:",
                "1. Download the APK file below",
                "2. Install on your Android device",
                "3. Grant necessary permissions when prompted",
                "",
                "---",
                "**Minimum Android Version**: 6.0 (API 23)",
                "**BLE Protocol**: Nordic UART Service (NUS)",
            ])

            if apk_size_mb is not None:
                notes.append(f"**APK Size**: {apk_size_mb:.1f} MB")

            if sha256_checksum:
                notes.extend([
                    "",
                    "### Verification:",
                    f"SHA256: {sha256_checksum}",
                ])

            return '\n'.join(notes)

        except Exception as e:
            print(f"[WARNING] Could not generate detailed release notes: {e}")
            return f"CG500 BLE App {version.to_tag()}\n\nBug fixes and improvements."

    # --- GitHub release ---

    def create_github_release(self, version: Version, apk_path: Path, custom_notes: Optional[str] = None) -> str:
        tag = version.to_tag()
        print(f"[INFO] Creating GitHub release {tag}...")

        gh_cmd = self._find_gh_command()
        if not gh_cmd:
            raise RuntimeError(
                "GitHub CLI not found. Install from https://cli.github.com/ and "
                "authenticate with 'gh auth login'."
            )

        sha256_checksum = self.calculate_sha256(apk_path)
        apk_size_mb = apk_path.stat().st_size / 1024 / 1024

        if custom_notes:
            release_notes = (
                custom_notes
                + f"\n\n---\n**APK Size**: {apk_size_mb:.1f} MB"
                + f"\n\n### Verification:\nSHA256: {sha256_checksum}"
            )
        else:
            release_notes = self.generate_release_notes(version, sha256_checksum, apk_size_mb)

        title_suffix = ' (pre-release)' if version.is_prerelease else ''

        # Hand the notes to gh as a FILE, never as an argument. Multi-line
        # markdown on a command line is fragile in ways that fail silently and
        # only on the publishing step, where nobody is watching:
        #   - a shell splits on the first newline, so the release ships with
        #     only the first line of the notes (this is what happened to
        #     v26.05, whose entire body on GitHub reads "# Release Notes")
        #   - Windows caps a command line at ~8191 characters
        #   - cmd.exe eats % and ! through variable expansion
        # --notes-file sidesteps all three. Written UTF-8 with LF endings so
        # the rendered markdown matches the source file on every platform.
        notes_file = tempfile.NamedTemporaryFile(
            mode='w', encoding='utf-8', newline='\n',
            suffix='.md', prefix='release-notes-', delete=False,
        )
        try:
            notes_file.write(release_notes)
            notes_file.close()

            # `--verify-tag` tells gh to use the already-pushed remote tag
            # instead of creating a new one. Without this, gh creates the tag
            # against the default branch's *remote* HEAD, which may lag the
            # just-pushed version bump (and produce a tag pointing at the
            # wrong commit).
            cmd = [
                gh_cmd, 'release', 'create', tag,
                str(apk_path),
                '--title', f"CG500 BLE App {tag}{title_suffix}",
                '--notes-file', notes_file.name,
                '--verify-tag',
            ]
            if version.is_prerelease:
                cmd.append('--prerelease')

            result = self._run(cmd, cwd=self.project_root, capture_output=True)
            if result.returncode != 0:
                raise RuntimeError(f"GitHub release failed: {result.stderr}")
        finally:
            os.unlink(notes_file.name)

        # Read the published body back and compare. A release whose notes were
        # silently truncated still exits 0, and the only place that shows up is
        # the in-app updater weeks later.
        self._verify_published_notes(gh_cmd, tag, release_notes)

        print(f"[OK] GitHub release created: {tag}")
        print(f"[INFO] Release URL: https://github.com/rstltd/cg500_blueteeth_app/releases/tag/{tag}")
        return tag

    def _verify_published_notes(self, gh_cmd: str, tag: str, expected: str):
        """Read the published release body back and compare it with what we sent.

        Truncated notes are the failure mode that matters here: `gh` still exits
        0, the script still prints success, and the loss only becomes visible in
        the in-app updater — which reads exactly this body — long after the
        release. Verifying costs one API call.
        """
        result = self._run(
            [gh_cmd, 'release', 'view', tag, '--json', 'body', '-q', '.body'],
            cwd=self.project_root, capture_output=True,
        )
        if result.returncode != 0:
            print('[WARN] Could not read the release body back to verify it: '
                  f'{(result.stderr or "").strip()}')
            return

        published = (result.stdout or '').replace('\r\n', '\n').strip()
        sent = expected.replace('\r\n', '\n').strip()
        if published == sent:
            print(f"[OK] Release notes verified on GitHub "
                  f"({len(published.splitlines())} lines)")
            return

        print('[WARN] The published release notes do NOT match what was sent.')
        print(f'[WARN]   sent     : {len(sent.splitlines())} lines, {len(sent)} chars')
        print(f'[WARN]   published: {len(published.splitlines())} lines, '
              f'{len(published)} chars')
        print('[WARN] The in-app updater shows this body verbatim — fix it at')
        print(f'[WARN] https://github.com/rstltd/cg500_blueteeth_app/releases/tag/{tag}')

    # --- Git ---

    def commit_version_change(self, version: Version):
        try:
            subprocess.run(['git', 'add', 'pubspec.yaml'], check=True, cwd=self.project_root)
            subprocess.run(
                ['git', 'commit', '-m', f'Bump version to {version.to_pubspec()}'],
                check=True, cwd=self.project_root,
            )
            print("[OK] Version change committed")
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Could not commit version change: {e}") from e

    def create_local_tag(self, version: Version):
        """Create the release tag locally, pointing at the just-committed
        version-bump commit. Created before push so the tag accompanies the
        commit to the remote in [push_tag], guaranteeing the tag points
        at the right commit instead of whatever the remote default branch's
        HEAD happened to be when `gh release create` ran.
        """
        tag = version.to_tag()
        try:
            subprocess.run(['git', 'tag', tag], check=True, cwd=self.project_root)
            print(f"[OK] Local tag {tag} created at HEAD")
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Could not create local tag {tag}: {e}") from e

    # Split from a single push_changes() so the caller can tell which of the
    # two pushes succeeded. A commit on the remote without its tag needs
    # different recovery advice from a tag that made it up there without a
    # GitHub Release behind it.
    def push_commit(self):
        try:
            subprocess.run(['git', 'push'], check=True, cwd=self.project_root)
            print("[OK] Version-bump commit pushed to GitHub")
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Could not push commit: {e}") from e

    def push_tag(self):
        try:
            subprocess.run(['git', 'push', '--tags'], check=True, cwd=self.project_root)
            print("[OK] Tag pushed to GitHub")
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Could not push tag: {e}") from e

    # --- Confirmation ---

    def confirm_release(self, version: Version, apk_path: Path, release_notes: str, skip_confirm=False):
        tag = version.to_tag()
        apk_size_mb = apk_path.stat().st_size / 1024 / 1024
        sha256 = self.calculate_sha256(apk_path)

        print("")
        print("=" * 50)
        print("RELEASE SUMMARY")
        print("=" * 50)
        print(f"  Version : {version.to_pubspec()}")
        print(f"  Tag     : {tag}")
        print(f"  Channel : {version.channel if version.fmt == 'calver' else 'stable (legacy)'}")
        print(f"  GitHub  : {'pre-release' if version.is_prerelease else 'latest'}")
        print(f"  APK     : {apk_path.name}")
        print(f"  Size    : {apk_size_mb:.1f} MB")
        print(f"  SHA256  : {sha256}")
        print("")
        print("  Release notes (first 5 lines):")
        for line in release_notes.split('\n')[:5]:
            print(f"    {line}")
        print("=" * 50)

        if skip_confirm:
            print("[INFO] Skipping confirmation (--yes flag)")
            return

        answer = input("Publish this release? (y/N): ").strip().lower()
        if answer != 'y':
            raise RuntimeError("Release cancelled by user")

    # --- Pipeline ---

    def release(self, mode: str, clean: bool = False, skip_confirm: bool = False, notes_file: Optional[str] = None):
        print(f"[START] Starting release process: {mode}")
        print("=" * 50)

        # Tracks how far the publish sequence got, so a later failure can give
        # recovery advice that matches the actual remote state instead of
        # pointing the caller at 'hotfix' (which would bump the version *again*
        # on top of whatever is already up there). The two pushes are tracked
        # separately because `git push` can succeed while `git push --tags`
        # fails, which leaves the commit published but no tag to attach a
        # release to.
        pushed_commit = False
        pushed_tag: Optional[str] = None

        try:
            new_version = self.update_version(mode)
            self.run_quality_checks()
            apk_path = self.build_release_apk(clean=clean)
            release_apk_path = self.rename_apk_for_release(apk_path, new_version)

            apk_size_mb = release_apk_path.stat().st_size / 1024 / 1024
            if notes_file:
                notes_path = Path(notes_file)
                if not notes_path.exists():
                    raise FileNotFoundError(f"Release notes file not found: {notes_file}")
                custom_notes = notes_path.read_text(encoding='utf-8').strip()
                print(f"[OK] Loaded release notes from: {notes_file}")
            else:
                custom_notes = None

            preview_notes = custom_notes or self.generate_release_notes(new_version, apk_size_mb=apk_size_mb)
            self.confirm_release(new_version, release_apk_path, preview_notes, skip_confirm)

            # Order matters: commit + tag locally, push them together, then
            # let `gh release create --verify-tag` attach the release to the
            # already-published tag. Doing `gh release create` first would let
            # gh create the tag against the remote branch's stale HEAD.
            self.commit_version_change(new_version)
            self.create_local_tag(new_version)
            self.push_commit()
            pushed_commit = True
            self.push_tag()
            pushed_tag = new_version.to_tag()
            tag = self.create_github_release(new_version, release_apk_path, custom_notes=custom_notes)

            print("=" * 50)
            print("[SUCCESS] Release completed successfully!")
            print(f"Version: {new_version.to_pubspec()}")
            print(f"Tag: {tag}")
            print(f"APK: {release_apk_path.name}")
            if new_version.is_prerelease:
                print("Channel: pre-release (only beta-channel users will see this)")
                print("All releases: https://github.com/rstltd/cg500_blueteeth_app/releases")
            else:
                print(f"Download: https://github.com/rstltd/cg500_blueteeth_app/releases/latest")
            return True

        except Exception as e:
            print(f"[ERROR] Release failed: {e}")
            if pushed_tag:
                print("")
                print(f"[ERROR] The version-bump commit and tag '{pushed_tag}' were already")
                print("[ERROR] pushed to GitHub before this failure -- the GitHub Release itself")
                print("[ERROR] is the only thing missing. Do NOT run 'hotfix' (that bumps the")
                print("[ERROR] version again on top of this). Instead, create the release for the")
                print(f"[ERROR] existing tag manually once the underlying problem is fixed, e.g.:")
                print(f"[ERROR]   gh release create {pushed_tag} \"{release_apk_path}\" \\")
                print(f"[ERROR]     --title \"CG500 BLE App {pushed_tag}\" --notes-file release_notes.md \\")
                print("[ERROR]     --verify-tag" + (" --prerelease" if new_version.is_prerelease else ""))
            elif pushed_commit:
                print("")
                print("[ERROR] The version-bump commit was pushed to GitHub but its tag was")
                print("[ERROR] not, so there is no orphaned release waiting -- only a version")
                print("[ERROR] bump on the remote. Do NOT run 'hotfix' (that bumps the version")
                print("[ERROR] again). Once the underlying problem is fixed, push the existing")
                print("[ERROR] local tag and create the release for it, e.g.:")
                print(f"[ERROR]   git push origin {new_version.to_tag()}")
                print(f"[ERROR]   gh release create {new_version.to_tag()} \"{release_apk_path}\" \\")
                print(f"[ERROR]     --title \"CG500 BLE App {new_version.to_tag()}\" \\")
                print("[ERROR]     --notes-file release_notes.md --verify-tag"
                      + (" --prerelease" if new_version.is_prerelease else ""))
            return False


# --- CLI ---------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description='CG500 BLE App Release Script (CalVer)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 simple_release.py release --notes-file release_notes.md
  python3 simple_release.py hotfix  --notes-file release_notes.md
  python3 simple_release.py beta    --notes-file release_notes.md
  python3 simple_release.py rc      --notes-file release_notes.md --yes
  python3 simple_release.py build                                # build-number bump only

Versioning policy: docs/VERSIONING.md
        """,
    )
    parser.add_argument(
        'mode',
        choices=['release', 'hotfix', 'beta', 'rc', 'build'],
        help='Release mode (see docs/VERSIONING.md)',
    )
    parser.add_argument('--force', action='store_true', help='Skip uncommitted changes check')
    parser.add_argument('--clean', action='store_true', help='Run flutter clean before build')
    parser.add_argument('--yes', action='store_true', help='Skip confirmation prompt (for CI)')
    parser.add_argument(
        '--notes-file', type=str, default=None,
        help='Path to a markdown file with release notes (overrides auto-generated notes)',
    )
    parser.add_argument(
        '--allow-branch', action='store_true',
        help='Skip the branch check and allow releasing from a non-main branch',
    )

    args = parser.parse_args()

    print("[INFO] Checking prerequisites...")

    # Anchor prerequisite checks to the script's own location, not the
    # process CWD -- the rest of this class always uses self.project_root,
    # and invoking the script from a different directory should not change
    # which repo gets checked.
    project_root = Path(__file__).resolve().parent.parent

    if not (project_root / '.git').exists():
        print("[ERROR] Not in a git repository")
        sys.exit(1)

    ALLOWED_RELEASE_BRANCHES = ('main',)
    branch_result = subprocess.run(
        ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        capture_output=True, text=True, cwd=project_root,
    )
    current_branch = branch_result.stdout.strip() if branch_result.returncode == 0 else None
    if current_branch not in ALLOWED_RELEASE_BRANCHES:
        if args.allow_branch:
            print(f"[WARNING] Releasing from branch '{current_branch}' (continuing due to --allow-branch)")
        else:
            print(f"[ERROR] Releasing from branch '{current_branch}', expected one of {ALLOWED_RELEASE_BRANCHES}.")
            print("")
            print("A release tag cut here would point at commits that are not on main --")
            print("switch back first:")
            print("")
            print("  git checkout main")
            print("")
            print("If this is intentional (e.g. an urgent out-of-band build), pass --allow-branch.")
            sys.exit(1)

    result = subprocess.run(
        ['git', 'status', '--porcelain'], capture_output=True, text=True, cwd=project_root,
    )
    if result.stdout.strip():
        if args.force:
            print("[WARNING] Uncommitted changes detected (continuing due to --force)")
        else:
            print("[ERROR] Uncommitted changes detected. Commit or stash before releasing.")
            print("")
            for line in result.stdout.strip().split('\n'):
                print(f"  {line}")
            print("")
            print("Use --force to override this check.")
            sys.exit(1)

    manager = SimpleReleaseManager(project_root=project_root)

    # Check GitHub CLI auth before doing any work. `gh` auth is only needed
    # for the very last step (creating the GitHub Release), but by then the
    # version bump has already been committed, tagged, and pushed -- so an
    # unauthenticated `gh` would leave an orphaned tag with no matching
    # release. Failing here keeps that failure mode at zero residual state.
    print("[INFO] Checking GitHub CLI authentication...")
    gh_cmd = manager._find_gh_command()
    if not gh_cmd:
        print("[ERROR] GitHub CLI not found. Install from https://cli.github.com/ and "
              "authenticate with 'gh auth login'.")
        sys.exit(1)
    auth_result = manager._run([gh_cmd, 'auth', 'status'], capture_output=True)
    if auth_result.returncode != 0:
        print("[ERROR] GitHub CLI is not authenticated. Run 'gh auth login' before releasing.")
        if auth_result.stderr:
            print(auth_result.stderr)
        sys.exit(1)
    print("[OK] GitHub CLI authenticated")

    success = manager.release(
        args.mode,
        clean=args.clean,
        skip_confirm=args.yes,
        notes_file=args.notes_file,
    )
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
