#!/bin/bash

# CG500 BLE App Release Build Script
# This script automates the APK build process for production

set -e  # Exit on any error

echo "========================================"
echo "CG500 BLE App Release Build"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    print_error "Please install Flutter and try again"
    exit 1
fi

# Get current version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
print_status "Building version: $VERSION"

# Step 1: Clean previous build
print_status "[1/6] Cleaning previous build..."
flutter clean

# Step 2: Get dependencies
print_status "[2/6] Getting dependencies..."
flutter pub get

# Step 3: Static analysis
print_status "[3/6] Running static analysis..."
if ! flutter analyze; then
    print_warning "Static analysis found issues"
    read -p "Continue anyway? (y/n): " continue
    if [[ $continue != [yY] ]]; then
        exit 1
    fi
fi

# Step 4: Run tests
print_status "[4/6] Running tests..."
if ! flutter test; then
    print_warning "Tests failed"
    read -p "Continue anyway? (y/n): " continue
    if [[ $continue != [yY] ]]; then
        exit 1
    fi
fi

# Step 5: Build release APK
print_status "[5/6] Building release APK..."
flutter build apk --release --target-platform android-arm,android-arm64,android-x64

# Step 6: Show results
print_status "[6/6] Build completed successfully!"
echo

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [[ -f "$APK_PATH" ]]; then
    print_success "APK Location: $APK_PATH"
    
    # Get file size
    if command -v stat &> /dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            SIZE=$(stat -f%z "$APK_PATH")
        else
            # Linux
            SIZE=$(stat -c%s "$APK_PATH")
        fi
        print_status "File size: $(numfmt --to=iec-i --suffix=B --format="%.1f" $SIZE)"
    fi
    
    # Generate SHA256 checksum
    if command -v sha256sum &> /dev/null; then
        CHECKSUM=$(sha256sum "$APK_PATH" | cut -d' ' -f1)
        print_status "SHA256: $CHECKSUM"
    elif command -v shasum &> /dev/null; then
        CHECKSUM=$(shasum -a 256 "$APK_PATH" | cut -d' ' -f1)
        print_status "SHA256: $CHECKSUM"
    fi
else
    print_error "APK file not found!"
    exit 1
fi

echo
echo "========================================"
print_success "Build completed successfully!"
echo "========================================"

# Ask if user wants to open the APK location (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    read -p "Open APK folder in Finder? (y/n): " open_folder
    if [[ $open_folder == [yY] ]]; then
        open "build/app/outputs/flutter-apk/"
    fi
fi

echo
print_status "Next steps:"
echo "1. Test the APK on a device"
echo "2. Upload to your update server"
echo "3. Update version info in server API"
echo "4. Consider creating a Shorebird release for hot updates"