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
"""

import os
import sys
import json
import subprocess
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
        """Update version"""
        print(f"[INFO] Incrementing {increment_type} version...")
        
        new_version = self.increment_version(increment_type)
        self.update_version_in_pubspec(new_version)
        
        print(f"[OK] Version updated to: {new_version}")
        return new_version
    
    def build_release_apk(self):
        """Build release APK"""
        print("[INFO] Building release APK...")
        
        os.chdir(self.project_root)
        
        # Clean previous builds
        print("[INFO] Cleaning previous builds...")
        subprocess.run(['flutter', 'clean'], check=True)
        subprocess.run(['flutter', 'pub', 'get'], check=True)
        
        # Build APK
        print("[INFO] Building APK (this may take a few minutes)...")
        result = subprocess.run([
            'flutter', 'build', 'apk', '--release'
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            raise RuntimeError(f"APK build failed: {result.stderr}")
        
        # Find built APK
        apk_files = list(self.build_dir.glob('*.apk'))
        if not apk_files:
            raise FileNotFoundError("No APK file found after build")
        
        apk_path = apk_files[0]  # Usually app-release.apk
        size_mb = apk_path.stat().st_size / 1024 / 1024
        print(f"[OK] APK built: {apk_path} ({size_mb:.1f} MB)")
        
        return apk_path
    
    def rename_apk_for_release(self, apk_path, version):
        """Rename APK with version number"""
        new_name = f"cg500_ble_app_v{version}.apk"
        new_path = apk_path.parent / new_name
        
        if new_path.exists():
            new_path.unlink()
        
        apk_path.rename(new_path)
        print(f"[OK] APK renamed to: {new_name}")
        
        return new_path
    
    def generate_release_notes(self, version):
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
            
            # Format release notes
            notes = [
                f"## CG500 BLE App v{version}",
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
                "### Features:",
                "* Bluetooth Low Energy device scanning",
                "* Nordic UART Service communication",
                "* Real-time text command interface",
                "* Smart notification filtering",
                "* Modern Material Design 3 UI",
                "* Dark/Light theme support",
                "",
                "---",
                "**Minimum Android Version**: 6.0 (API 23)",
                "**BLE Protocol**: Nordic UART Service (NUS)",
                f"**APK Size**: ~15MB"
            ])
            
            return '\n'.join(notes)
            
        except Exception as e:
            print(f"[WARNING] Could not generate detailed release notes: {e}")
            return f"CG500 BLE App v{version}\n\nBug fixes and improvements."
    
    def create_github_release(self, version, apk_path):
        """Create GitHub release using GitHub CLI"""
        print(f"[INFO] Creating GitHub release v{version}...")
        
        # Check if gh CLI is available
        try:
            subprocess.run(['gh', '--version'], capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise RuntimeError(
                "GitHub CLI not found. Please install from https://cli.github.com/ "
                "and authenticate with 'gh auth login'"
            )
        
        # Generate release notes
        release_notes = self.generate_release_notes(version)
        
        # Create release
        tag = f"v{version}"
        cmd = [
            'gh', 'release', 'create', tag,
            str(apk_path),
            '--title', f"CG500 BLE App v{version}",
            '--notes', release_notes,
        ]
        
        result = subprocess.run(cmd, cwd=self.project_root, capture_output=True, text=True)
        
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
    
    def release(self, increment_type):
        """Complete release process"""
        print(f"[START] Starting release process: {increment_type}")
        print("=" * 50)
        
        try:
            # Update version
            new_version = self.update_version(increment_type)
            
            # Commit version change
            self.commit_version_change(new_version)
            
            # Build APK
            apk_path = self.build_release_apk()
            
            # Rename APK for release
            release_apk_path = self.rename_apk_for_release(apk_path, new_version)
            
            # Create GitHub release
            tag = self.create_github_release(new_version, release_apk_path)
            
            # Push changes
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
    if len(sys.argv) != 2:
        print("Usage:")
        print("  python simple_release.py patch   # Increment patch version")
        print("  python simple_release.py minor   # Increment minor version")
        print("  python simple_release.py major   # Increment major version")
        print("  python simple_release.py build   # Increment build number")
        sys.exit(1)
    
    increment_type = sys.argv[1].lower()
    
    if increment_type not in ['patch', 'minor', 'major', 'build']:
        print(f"[ERROR] Invalid increment type: {increment_type}")
        print("Valid options: patch, minor, major, build")
        sys.exit(1)
    
    # Check prerequisites
    print("[INFO] Checking prerequisites...")
    
    # Check if we're in a git repository
    if not Path('.git').exists():
        print("[ERROR] Not in a git repository")
        sys.exit(1)
    
    # Check for uncommitted changes
    result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
    if result.stdout.strip():
        print("[WARNING] You have uncommitted changes")
        try:
            confirm = input("Continue anyway? (y/N): ").strip().lower()
            if confirm not in ['y', 'yes']:
                print("[CANCELLED] Release cancelled")
                sys.exit(1)
        except KeyboardInterrupt:
            print("\n[CANCELLED] Release cancelled")
            sys.exit(1)
    
    # Create release manager and start release
    manager = SimpleReleaseManager()
    success = manager.release(increment_type)
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()