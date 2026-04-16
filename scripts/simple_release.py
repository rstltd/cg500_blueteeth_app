#!/usr/bin/env python3

"""
CG500 BLE App Simple Release Script (Windows Compatible)

A simplified version without emoji characters for Windows compatibility.
Automatically builds and publishes releases to GitHub.

Prerequisites:
1. Install GitHub CLI: https://cli.github.com/
2. Authenticate with GitHub: gh auth login
3. Install Flutter SDK

Usage:
  python simple_release.py patch       # Build and release patch version
  python simple_release.py minor       # Build and release minor version
  python simple_release.py major       # Build and release major version
  python simple_release.py build       # Build and release with build number increment

Options:
  --force    Skip uncommitted changes check
  --clean    Run flutter clean before build
  --yes      Skip confirmation prompt (for CI)
"""

import os
import sys
import subprocess
import hashlib
import argparse
from pathlib import Path
from datetime import datetime
import re

class SimpleReleaseManager:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.pubspec_path = self.project_root / 'pubspec.yaml'
        self.build_dir = self.project_root / 'build' / 'app' / 'outputs' / 'flutter-apk'

    def get_current_version(self):
        """Get current version from pubspec.yaml"""
        if not self.pubspec_path.exists():
            raise FileNotFoundError("pubspec.yaml not found")

        with open(self.pubspec_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('version:'):
                    return line.split(':', 1)[1].strip()

        raise ValueError("Version not found in pubspec.yaml")

    def parse_version(self, version_string):
        """Parse version string into components"""
        match = re.match(r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$', version_string)
        if not match:
            raise ValueError(f"Invalid version format: {version_string}")

        return {
            'major': int(match.group(1)),
            'minor': int(match.group(2)),
            'patch': int(match.group(3)),
            'build': int(match.group(4))
        }

    def format_version(self, version_dict):
        """Format version dictionary into string"""
        return f"{version_dict['major']}.{version_dict['minor']}.{version_dict['patch']}+{version_dict['build']}"

    def semver_tag(self, version_string):
        """Extract semver part (without build number) for use as git tag"""
        match = re.match(r'^(\d+\.\d+\.\d+)', version_string)
        if not match:
            raise ValueError(f"Cannot extract semver from: {version_string}")
        return f"v{match.group(1)}"

    def update_version_in_pubspec(self, new_version):
        """Update version in pubspec.yaml"""
        with open(self.pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Replace version line
        new_content = re.sub(
            r'^version:\s*.+$',
            f'version: {new_version}',
            content,
            flags=re.MULTILINE
        )

        with open(self.pubspec_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

        print(f"[OK] Updated version to {new_version} in {self.pubspec_path.name}")

    def increment_version(self, increment_type):
        """Increment version based on type"""
        current_version_str = self.get_current_version()
        print(f"[INFO] Current version: {current_version_str}")

        version = self.parse_version(current_version_str)

        if increment_type == 'major':
            version['major'] += 1
            version['minor'] = 0
            version['patch'] = 0
            version['build'] += 1
        elif increment_type == 'minor':
            version['minor'] += 1
            version['patch'] = 0
            version['build'] += 1
        elif increment_type == 'patch':
            version['patch'] += 1
            version['build'] += 1
        elif increment_type == 'build':
            version['build'] += 1
        else:
            raise ValueError(f"Invalid increment type: {increment_type}")

        new_version_str = self.format_version(version)
        print(f"[INFO] New version: {new_version_str}")

        return new_version_str

    def update_version(self, increment_type):
        """Update version in pubspec.yaml only (no commit yet)"""
        print(f"[INFO] Incrementing {increment_type} version...")

        new_version = self.increment_version(increment_type)
        self.update_version_in_pubspec(new_version)

        print(f"[OK] Version updated to: {new_version}")
        return new_version

    def _run(self, cmd, **kwargs):
        """Run a subprocess with UTF-8 encoding to avoid cp950 errors on Windows."""
        kwargs.setdefault('shell', True)
        kwargs.setdefault('encoding', 'utf-8')
        kwargs.setdefault('errors', 'replace')
        return subprocess.run(cmd, **kwargs)

    def run_quality_checks(self):
        """Run flutter analyze and flutter test before building."""
        os.chdir(self.project_root)

        print("[INFO] Running flutter analyze...")
        result = self._run(
            ['flutter', 'analyze'], capture_output=True
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr)
            raise RuntimeError("flutter analyze failed -- fix issues before releasing")

        print("[OK] Static analysis passed")

        print("[INFO] Running flutter test...")
        result = self._run(
            ['flutter', 'test'], capture_output=True
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr)
            raise RuntimeError("flutter test failed -- fix tests before releasing")

        print("[OK] All tests passed")

    def build_release_apk(self, clean=False):
        """Build release APK"""
        print("[INFO] Building release APK...")

        os.chdir(self.project_root)

        if clean:
            print("[INFO] Cleaning previous builds (--clean flag)...")
            self._run(['flutter', 'clean'], check=True)

        self._run(['flutter', 'pub', 'get'], check=True)

        # Build APK
        print("[INFO] Building APK (this may take a few minutes)...")
        result = self._run([
            'flutter', 'build', 'apk', '--release'
        ], capture_output=True)

        if result.returncode != 0:
            raise RuntimeError(f"APK build failed: {result.stderr}")

        # Find the release APK specifically — the build directory may also
        # contain stale debug APKs from previous flutter run sessions.
        # glob('*.apk') would pick app-debug.apk first alphabetically.
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

    def rename_apk_for_release(self, apk_path, version):
        """Rename APK with version number"""
        semver = self.semver_tag(version).lstrip('v')
        new_name = f"cg500_ble_app_v{semver}.apk"
        new_path = apk_path.parent / new_name

        if new_path.exists():
            new_path.unlink()

        apk_path.rename(new_path)
        print(f"[OK] APK renamed to: {new_name}")

        return new_path

    def calculate_sha256(self, file_path):
        """Calculate SHA256 checksum of a file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        checksum = sha256_hash.hexdigest()
        print(f"[OK] SHA256 checksum calculated: {checksum[:16]}...")
        return checksum

    def _find_gh_command(self):
        """Find GitHub CLI command path"""
        # Try common paths
        possible_paths = [
            'gh',
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

    def generate_release_notes(self, version, sha256_checksum=None, apk_size_mb=None):
        """Generate release notes from git commits since last tag"""
        try:
            # Get last tag
            result = subprocess.run([
                'git', 'describe', '--tags', '--abbrev=0'
            ], capture_output=True, text=True, cwd=self.project_root)

            last_tag = result.stdout.strip() if result.returncode == 0 else None

            # Get commits since last tag
            if last_tag:
                cmd = ['git', 'log', f'{last_tag}..HEAD', '--oneline']
            else:
                cmd = ['git', 'log', '--oneline', '-10']  # Last 10 commits

            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.project_root)
            commits = result.stdout.strip().split('\n') if result.stdout.strip() else []

            semver = self.semver_tag(version).lstrip('v')

            # Format release notes
            notes = [
                f"## CG500 BLE App v{semver}",
                "",
                f"Released: {datetime.now().strftime('%Y-%m-%d %H:%M UTC')}",
                "",
                "### Changes in this version:",
            ]

            if commits:
                for commit in commits[:10]:  # Limit to 10 commits
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

            # Add SHA256 checksum for APK verification (used by app auto-update)
            if sha256_checksum:
                notes.extend([
                    "",
                    "### Verification:",
                    f"SHA256: {sha256_checksum}",
                ])

            return '\n'.join(notes)

        except Exception as e:
            print(f"[WARNING] Could not generate detailed release notes: {e}")
            return f"CG500 BLE App v{version}\n\nBug fixes and improvements."

    def create_github_release(self, version, apk_path, custom_notes=None):
        """Create GitHub release using GitHub CLI"""
        tag = self.semver_tag(version)
        print(f"[INFO] Creating GitHub release {tag}...")

        # Check if gh CLI is available
        gh_cmd = self._find_gh_command()
        if not gh_cmd:
            raise RuntimeError(
                "GitHub CLI not found. Please install from https://cli.github.com/ "
                "and authenticate with 'gh auth login'"
            )

        # Calculate SHA256 checksum for APK verification
        sha256_checksum = self.calculate_sha256(apk_path)

        # Actual APK size
        apk_size_mb = apk_path.stat().st_size / 1024 / 1024

        # Use custom notes if provided, otherwise auto-generate
        if custom_notes:
            # Append verification info to custom notes
            release_notes = custom_notes + f"\n\n---\n**APK Size**: {apk_size_mb:.1f} MB\n\n### Verification:\nSHA256: {sha256_checksum}"
        else:
            release_notes = self.generate_release_notes(version, sha256_checksum, apk_size_mb)

        # Create release
        semver = tag.lstrip('v')
        cmd = [
            gh_cmd, 'release', 'create', tag,
            str(apk_path),
            '--title', f"CG500 BLE App v{semver}",
            '--notes', release_notes,
        ]

        result = self._run(cmd, cwd=self.project_root, capture_output=True)

        if result.returncode != 0:
            raise RuntimeError(f"GitHub release failed: {result.stderr}")

        print(f"[OK] GitHub release created: {tag}")
        print(f"[INFO] Release URL: https://github.com/rstltd/cg500_blueteeth_app/releases/tag/{tag}")

        return tag

    def commit_version_change(self, version):
        """Commit version change to git"""
        try:
            subprocess.run(['git', 'add', 'pubspec.yaml'], check=True, cwd=self.project_root)
            subprocess.run([
                'git', 'commit', '-m', f'Bump version to {version}'
            ], check=True, cwd=self.project_root)
            print(f"[OK] Version change committed")
        except subprocess.CalledProcessError as e:
            print(f"[WARNING] Could not commit version change: {e}")

    def push_changes(self):
        """Push changes and tags to GitHub"""
        try:
            subprocess.run(['git', 'push'], check=True, cwd=self.project_root)
            subprocess.run(['git', 'push', '--tags'], check=True, cwd=self.project_root)
            print(f"[OK] Changes pushed to GitHub")
        except subprocess.CalledProcessError as e:
            print(f"[WARNING] Could not push changes: {e}")

    def confirm_release(self, version, apk_path, release_notes, skip_confirm=False):
        """Prompt user to confirm before publishing."""
        tag = self.semver_tag(version)
        apk_size_mb = apk_path.stat().st_size / 1024 / 1024
        sha256 = self.calculate_sha256(apk_path)

        print("")
        print("=" * 50)
        print("RELEASE SUMMARY")
        print("=" * 50)
        print(f"  Version : {version}")
        print(f"  Tag     : {tag}")
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

    def release(self, increment_type, clean=False, skip_confirm=False, notes_file=None):
        """Complete release process"""
        print(f"[START] Starting release process: {increment_type}")
        print("=" * 50)

        try:
            # 1. Update version in pubspec only (no commit yet)
            new_version = self.update_version(increment_type)

            # 2. Quality gates
            self.run_quality_checks()

            # 3. Build APK
            apk_path = self.build_release_apk(clean=clean)

            # 4. Rename APK for release
            release_apk_path = self.rename_apk_for_release(apk_path, new_version)

            # 5. Load or generate release notes, then confirm
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

            # 6. Commit version change (only after build succeeds)
            self.commit_version_change(new_version)

            # 7. Create GitHub release
            tag = self.create_github_release(new_version, release_apk_path, custom_notes=custom_notes)

            # 8. Push changes
            self.push_changes()

            print("=" * 50)
            print("[SUCCESS] Release completed successfully!")
            print(f"Version: {new_version}")
            print(f"Tag: {tag}")
            print(f"APK: {release_apk_path.name}")
            print(f"Download: https://github.com/rstltd/cg500_blueteeth_app/releases/latest")

            return True

        except Exception as e:
            print(f"[ERROR] Release failed: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(
        description='CG500 BLE App Release Script',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python simple_release.py patch          # Patch release (1.0.0 -> 1.0.1)
  python simple_release.py minor          # Minor release (1.0.1 -> 1.1.0)
  python simple_release.py major          # Major release (1.1.0 -> 2.0.0)
  python simple_release.py patch --clean  # Clean build before release
  python simple_release.py patch --force  # Ignore uncommitted changes
  python simple_release.py patch --yes    # Skip confirmation (CI mode)
        """,
    )
    parser.add_argument(
        'increment_type',
        choices=['patch', 'minor', 'major', 'build'],
        help='Version increment type',
    )
    parser.add_argument(
        '--force', action='store_true',
        help='Skip uncommitted changes check',
    )
    parser.add_argument(
        '--clean', action='store_true',
        help='Run flutter clean before build',
    )
    parser.add_argument(
        '--yes', action='store_true',
        help='Skip confirmation prompt (for CI)',
    )
    parser.add_argument(
        '--notes-file', type=str, default=None,
        help='Path to a markdown file with release notes (overrides auto-generated notes)',
    )

    args = parser.parse_args()

    # Check prerequisites
    print("[INFO] Checking prerequisites...")

    # Check if we're in a git repository
    if not Path('.git').exists():
        print("[ERROR] Not in a git repository")
        sys.exit(1)

    # Check for uncommitted changes
    result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
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

    # Create release manager and start release
    manager = SimpleReleaseManager()
    success = manager.release(
        args.increment_type,
        clean=args.clean,
        skip_confirm=args.yes,
        notes_file=args.notes_file,
    )

    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
