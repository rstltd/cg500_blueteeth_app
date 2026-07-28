#!/usr/bin/env python3

"""
CG500 BLE App Version Update Script (CalVer-aware)

Bumps `pubspec.yaml` to the next version without building or releasing.
Versioning policy is documented in docs/VERSIONING.md.

Usage:
  python3 update_version.py current                   # Show current version
  python3 update_version.py release                   # Bump to next stable (e.g. 26.05+31 -> 26.06+32)
  python3 update_version.py hotfix                    # Bump to next hotfix (e.g. 26.05+31 -> 26.05.1+32)
  python3 update_version.py beta                      # Bump to next beta
  python3 update_version.py rc                        # Bump to next release candidate
  python3 update_version.py build                     # Bump build number only
  python3 update_version.py set <version>             # Set explicit version (e.g. 26.05.1+32)
"""

import sys
import re
from pathlib import Path

# Reuse the version logic from simple_release.py so the two scripts cannot drift.
sys.path.insert(0, str(Path(__file__).parent))
from simple_release import Version, next_version  # noqa: E402

# NOTE: no stdout/stderr UTF-8 setup here on purpose. Importing simple_release
# above already reconfigures both streams to UTF-8 with errors='replace' on
# every platform; repeating it here would detach an already-reconfigured stream.


def get_pubspec_path() -> Path:
    current_dir = Path.cwd()
    for path in [current_dir] + list(current_dir.parents):
        candidate = path / 'pubspec.yaml'
        if candidate.exists():
            return candidate
    # Fallback: walk up from this script's location.
    script_root = Path(__file__).resolve().parent.parent
    candidate = script_root / 'pubspec.yaml'
    if candidate.exists():
        return candidate
    raise FileNotFoundError("pubspec.yaml not found")


def read_current_version() -> Version:
    pubspec_path = get_pubspec_path()
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()
    match = re.search(r'^version:\s*(.+)$', content, re.MULTILINE)
    if not match:
        raise ValueError("Version not found in pubspec.yaml")
    return Version.parse(match.group(1).strip())


def update_version_in_pubspec(new_version: Version):
    pubspec_path = get_pubspec_path()
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = re.sub(
        r'^version:\s*.+$',
        f'version: {new_version.to_pubspec()}',
        content,
        flags=re.MULTILINE,
    )
    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"[OK] Updated version to {new_version.to_pubspec()} in {pubspec_path.name}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1].lower()

    try:
        if command == 'current':
            current = read_current_version()
            print(f"[INFO] Current version: {current.to_pubspec()}")
            print(f"[INFO] Tag form       : {current.to_tag()}")
            print(f"[INFO] Channel        : {current.channel if current.fmt == 'calver' else 'stable (legacy semver)'}")
            return

        if command in ('release', 'hotfix', 'beta', 'rc', 'build'):
            current = read_current_version()
            print(f"[INFO] Current version: {current.to_pubspec()}")
            new_version = next_version(current, command)
            print(f"[INFO] New version    : {new_version.to_pubspec()} (tag {new_version.to_tag()})")

            confirm = input("Update pubspec.yaml? (y/N): ").strip().lower()
            if confirm in ('y', 'yes'):
                update_version_in_pubspec(new_version)
                print("\n[INFO] Next steps:")
                print(f"  1. git add pubspec.yaml && git commit -m 'Bump version to {new_version.to_pubspec()}'")
                print(f"  2. python3 scripts/simple_release.py {command} --notes-file release_notes.md")
                print("     (Or use simple_release.py directly — it bumps and releases in one go.)")
            else:
                print("[CANCELLED] Version update cancelled")
            return

        if command == 'set':
            if len(sys.argv) < 3:
                print("[ERROR] Specify version: python3 update_version.py set 26.05.1+32")
                sys.exit(1)
            new_version = Version.parse(sys.argv[2])
            current = read_current_version()
            print(f"[INFO] Current version: {current.to_pubspec()}")
            print(f"[INFO] Target version : {new_version.to_pubspec()} (tag {new_version.to_tag()})")
            confirm = input("Update pubspec.yaml? (y/N): ").strip().lower()
            if confirm in ('y', 'yes'):
                update_version_in_pubspec(new_version)
            else:
                print("[CANCELLED] Version update cancelled")
            return

        print(f"[ERROR] Unknown command: {command}")
        print(__doc__)
        sys.exit(1)

    except Exception as e:
        print(f"[ERROR] {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
