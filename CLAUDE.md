# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application named `cg500_blueteeth_app` - appears to be related to Bluetooth functionality based on the name. It's a standard Flutter project with multi-platform support (Android, iOS, Windows, Linux, macOS, Web).

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app in development mode with hot reload
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (requires macOS)
- `flutter build web` - Build web version
- `flutter build windows` - Build Windows desktop app
- `flutter build linux` - Build Linux desktop app
- `flutter build macos` - Build macOS desktop app

### Testing and Quality
- `flutter test` - Run all unit and widget tests
- `flutter analyze` - Run static analysis and linting
- `flutter pub get` - Install/update dependencies
- `flutter pub upgrade` - Upgrade dependencies to latest versions
- `flutter clean` - Clean build artifacts

## Architecture

### Project Structure
- `lib/main.dart` - Main application entry point with standard Flutter counter app
- `test/widget_test.dart` - Widget tests for the main app
- Platform-specific folders: `android/`, `ios/`, `windows/`, `linux/`, `macos/`, `web/`

### Current Implementation
The app is a fully functional Bluetooth Low Energy (BLE GATT) scanner and management application:

#### Main Components:
- `main.dart` - App entry point with Material Design theme
- `ble_manager.dart` - Core BLE management singleton class handling all Bluetooth operations
- `ble_scanner_page.dart` - Main UI for scanning and listing BLE devices
- `device_detail_page.dart` - Detailed view for connected devices showing GATT services and characteristics

#### Key Features:
- **BLE Device Scanning**: Automatic discovery of nearby BLE devices with 15-second timeout
- **Device Connection**: Connect/disconnect to/from BLE devices with connection state monitoring
- **GATT Service Discovery**: Automatic discovery and display of all services and characteristics
- **Characteristic Operations**: Read, Write, and Subscribe to notifications from characteristics
- **Permission Management**: Automatic request of required Bluetooth and location permissions
- **Real-time UI Updates**: StreamBuilder-based reactive UI for device lists and connection status

### Dependencies
- **Core**: Flutter SDK (^3.8.1)
- **BLE**: flutter_blue_plus (^1.32.12) - Primary BLE communication library
- **Permissions**: permission_handler (^11.3.1) - Handle Bluetooth and location permissions
- **Icons**: cupertino_icons (^1.0.8)
- **Testing**: flutter_test, flutter_lints (^5.0.0)

### Android Permissions
Configured in `android/app/src/main/AndroidManifest.xml`:
- `BLUETOOTH`, `BLUETOOTH_ADMIN` - Legacy Bluetooth permissions
- `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE` - Android 12+ permissions
- `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` - Required for BLE scanning
- `android.hardware.bluetooth_le` - Declares BLE hardware requirement

### Code Quality
- Uses `flutter_lints` package for recommended linting rules
- Analysis options configured in `analysis_options.yaml`
- All code passes static analysis with zero issues
- Follows Flutter best practices and Material Design guidelines

## MVC Architecture Implementation

The application has been refactored to follow MVC (Model-View-Controller) architecture with additional Service and Repository layers for better separation of concerns.

### Architecture Layers:

#### 1. **Models Layer** (`lib/models/`)
- **`connection_state.dart`** - BLE connection state enumeration with extensions
- **`ble_device.dart`** - Complete device model with connection state, services, RSSI, favorites, and persistence
- **`ble_service.dart`** - Service model with characteristic management and UUID resolution
- **`ble_characteristic.dart`** - Characteristic model with properties, value formatting, and operations

#### 2. **Services Layer** (`lib/services/`)
- **`ble_service.dart`** - Core BLE operations service with device management and GATT operations
- **`permission_service.dart`** - Bluetooth and location permission management
- **`notification_service.dart`** - Centralized user notification system with different message types

#### 3. **Controllers Layer** (`lib/controllers/`)
- **`simple_ble_controller.dart`** - Main BLE operations coordinator with command support

#### 4. **Views Layer** (`lib/views/`)
- **`simple_scanner_view.dart`** - Main BLE scanner interface with MVC architecture
- **`command_interface_view.dart`** - Text command communication interface

### Key Architecture Benefits:

#### **Separation of Concerns:**
- **Models**: Pure data representations with business logic
- **Services**: External service communications and core operations
- **Controllers**: Coordinate between UI and business logic
- **Repository**: Abstract data access and caching
- **Views**: Pure UI components with minimal logic

#### **Enhanced Features:**
- **Text Command Communication**: Send text commands to devices and receive real-time responses
- **MTU Configuration**: Automatic MTU setting to 517 bytes as required by device manufacturer
- **Auto-Discovery**: Automatic detection of command and response characteristics
- **Command History**: Track and navigate through up to 20 previous commands
- **Real-time Communication Log**: Live display of sent commands and received responses
- **Device Favorites**: Mark frequently used devices
- **Connection History**: Track connection times and duration
- **Signal Strength**: RSSI-based connection quality indicators
- **Notification System**: Centralized user feedback with different severity levels
- **Permission Management**: Robust Bluetooth and location permission handling
- **State Management**: Reactive streams for real-time UI updates

#### **Improved Maintainability:**
- **Single Responsibility**: Each class focused on specific functionality
- **Dependency Injection**: Loosely coupled components
- **Error Handling**: Centralized error management and user notifications
- **Testing**: Clear interfaces enable comprehensive unit testing

### Development Workflow:

#### **Current Working Features:**
- Original BLE scanning and connection functionality
- Complete Models layer with rich domain objects
- Service layer with permission and notification management
- Enhanced BLE service with improved state management

#### **Next Steps (To Complete MVC):**
1. **Controllers Implementation** - Business logic coordination
2. **Repository Implementation** - Data persistence and caching
3. **Views Refactoring** - Separate UI from business logic
4. **State Management Integration** - Provider/GetX/BLoC integration
5. **Testing Suite** - Unit and integration tests

## BLE Usage Guide

### Basic Operations:
1. **Scan for devices**: Tap "Start Scanning" button
2. **Connect to device**: Tap connect icon next to desired device  
3. **Access Command Interface**: After device connection, tap the chat icon (💬) in the top-right corner
4. **Send text commands**: In the command interface, type commands and press Enter or tap Send
5. **View responses**: Device responses appear in real-time in the communication log
6. **Navigate command history**: Use up/down arrows to browse previous commands

### Text Command Communication:
- **MTU Setting**: Automatically configured to 517 bytes as required
- **Character Encoding**: UTF-8 support for international characters
- **Auto-Discovery**: Automatically finds writable and notifiable characteristics
- **Real-time Response**: Instant display of device responses with timestamps
- **Command History**: Access to last 20 commands with arrow key navigation
- **Connection Status**: Live indicator showing communication channel status

### Supported GATT Operations:
- Service discovery with automatic UUID recognition for common services
- Characteristic property detection (Read/Write/Notify/Indicate)
- Hex and string value display for characteristic data
- Write operations with hex string parsing (supports "01,FF,A0" or "01FFA0" formats)

### Architecture Usage Example:
```dart
// Using the new service layer
final BleService bleService = BleService();
final NotificationService notifications = NotificationService();

// Initialize and start scanning
await bleService.initialize();
await bleService.startScanning();

// Listen to device updates
bleService.devicesStream.listen((devices) {
  // Update UI with discovered devices
});

// Connect to device
bool connected = await bleService.connectToDevice(deviceId);
if (connected) {
  // Discover services
  List<BleServiceModel> services = await bleService.discoverServices(deviceId);
}
```