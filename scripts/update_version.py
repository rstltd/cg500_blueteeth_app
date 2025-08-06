#!/usr/bin/env python3

"""
CG500 BLE App Version Update Script

This script helps manage version numbers in pubspec.yaml
Supports semantic versioning (major.minor.patch+build)

Usage:
  python update_version.py patch          # Increment patch version
  python update_version.py minor          # Increment minor version
  python update_version.py major          # Increment major version
  python update_version.py build          # Increment build number
  python update_version.py set 1.2.3+4    # Set specific version
"""

import sys
import re
import os
from pathlib import Path

# Fix Windows console encoding for emoji support
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.detach())
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.detach())

def get_pubspec_path():
    """Find pubspec.yaml file"""
    current_dir = Path.cwd()
    
    # Look for pubspec.yaml in current directory or parent directories
    for path in [current_dir] + list(current_dir.parents):
        pubspec_path = path / 'pubspec.yaml'
        if pubspec_path.exists():
            return pubspec_path
    
    raise FileNotFoundError("pubspec.yaml not found")

def parse_version(version_string):
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

def format_version(version_dict):
    """Format version dictionary into string"""
    return f"{version_dict['major']}.{version_dict['minor']}.{version_dict['patch']}+{version_dict['build']}"

def read_current_version():
    """Read current version from pubspec.yaml"""
    pubspec_path = get_pubspec_path()
    
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    match = re.search(r'^version:\s*(.+)$', content, re.MULTILINE)
    if not match:
        raise ValueError("Version not found in pubspec.yaml")
    
    return match.group(1).strip()

def update_version_in_pubspec(new_version):
    """Update version in pubspec.yaml"""
    pubspec_path = get_pubspec_path()
    
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace version line
    new_content = re.sub(
        r'^version:\s*.+$',
        f'version: {new_version}',
        content,
        flags=re.MULTILINE
    )
    
    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"✅ Updated version to {new_version} in {pubspec_path.name}")

def increment_version(increment_type):
    """Increment version based on type"""
    current_version_str = read_current_version()
    print(f"📋 Current version: {current_version_str}")
    
    version = parse_version(current_version_str)
    
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
    
    new_version_str = format_version(version)
    print(f"🚀 New version: {new_version_str}")
    
    return new_version_str

def set_specific_version(version_string):
    """Set specific version"""
    current_version_str = read_current_version()
    print(f"📋 Current version: {current_version_str}")
    
    # Validate new version format
    parse_version(version_string)
    
    print(f"🎯 Setting version: {version_string}")
    return version_string

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python update_version.py patch          # Increment patch version")
        print("  python update_version.py minor          # Increment minor version") 
        print("  python update_version.py major          # Increment major version")
        print("  python update_version.py build          # Increment build number")
        print("  python update_version.py set 1.2.3+4    # Set specific version")
        print("  python update_version.py current        # Show current version")
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    try:
        if command == 'current':
            current_version = read_current_version()
            print(f"📋 Current version: {current_version}")
        
        elif command in ['patch', 'minor', 'major', 'build']:
            new_version = increment_version(command)
            
            # Confirm before updating
            confirm = input("Update pubspec.yaml? (y/N): ").strip().lower()
            if confirm in ['y', 'yes']:
                update_version_in_pubspec(new_version)
                
                # Suggest next steps
                print("\n💡 Next steps:")
                print("   1. Commit version change: git add pubspec.yaml && git commit -m 'Bump version to {}'".format(new_version))
                print("   2. Create git tag: git tag v{}".format(new_version))
                print("   3. Build release: ./scripts/build_release.sh")
            else:
                print("❌ Version update cancelled")
        
        elif command == 'set':
            if len(sys.argv) < 3:
                print("❌ Please specify version: python update_version.py set 1.2.3+4")
                sys.exit(1)
            
            new_version = set_specific_version(sys.argv[2])
            
            # Confirm before updating
            confirm = input("Update pubspec.yaml? (y/N): ").strip().lower()
            if confirm in ['y', 'yes']:
                update_version_in_pubspec(new_version)
                
                print("\n💡 Next steps:")
                print("   1. Commit version change: git add pubspec.yaml && git commit -m 'Set version to {}'".format(new_version))
                print("   2. Create git tag: git tag v{}".format(new_version))
                print("   3. Build release: ./scripts/build_release.sh")
            else:
                print("❌ Version update cancelled")
        
        else:
            print(f"❌ Unknown command: {command}")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()