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
The app is a comprehensive Bluetooth Low Energy (BLE GATT) scanner and communication application with modern UI/UX:

#### Main Components:
- `main.dart` - App entry point with Material Design 3 theme and dark mode support
- `lib/views/simple_scanner_view.dart` - Modern responsive BLE scanner interface with animated components
- `lib/views/command_interface_view.dart` - Chat-style text command communication interface
- `lib/controllers/simple_ble_controller.dart` - MVC controller coordinating BLE operations
- `lib/services/ble_service.dart` - Core BLE service with Nordic UART Service support
- `lib/services/smart_notification_service.dart` - Intelligent notification filtering system

#### Key Features:
- **Nordic UART Service Communication**: Text command communication via standardized BLE UART protocol
- **Modern Responsive UI**: Material Design 3 with dark/light themes and responsive layouts for mobile/tablet/desktop
- **Smart Notification System**: Intelligent filtering to prevent notification spam with user-configurable settings
- **BLE Device Scanning**: Automatic discovery with animated scanning indicators and signal strength visualization
- **Chat-Style Command Interface**: Real-time bidirectional communication with command history and message bubbles
- **Connection Management**: Visual connection states with duration tracking and automatic reconnection
- **Service Discovery**: Automatic GATT service enumeration with characteristic property detection
- **Permission Management**: Comprehensive Bluetooth and location permission handling
- **Animation System**: Smooth transitions, scanning effects, and connection status animations

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
- **`ble_service.dart`** - Core BLE operations with Nordic UART Service implementation
- **`smart_notification_service.dart`** - Intelligent notification filtering with debouncing and duplicate prevention
- **`permission_service.dart`** - Bluetooth and location permission management
- **`notification_service.dart`** - Base notification system with categorized message types
- **`theme_service.dart`** - Dark/light theme management with persistence
- **`animation_service.dart`** - Page transitions and custom animation effects
- **`error_handling_service.dart`** - Comprehensive error categorization and user feedback

#### 3. **Controllers Layer** (`lib/controllers/`)
- **`simple_ble_controller.dart`** - Main BLE operations coordinator with command support

#### 4. **Views Layer** (`lib/views/`)
- **`simple_scanner_view.dart`** - Responsive BLE scanner with animated components and device management
- **`command_interface_view.dart`** - Chat-style command interface with history and real-time responses

#### 5. **Utils and Widgets** (`lib/utils/`, `lib/widgets/`)
- **`responsive_utils.dart`** - Screen breakpoint management and responsive calculations
- **`responsive_layout.dart`** - Adaptive layout system for mobile/tablet/desktop
- **`animated_widgets.dart`** - Custom animated components (scan buttons, connection status)
- **`notification_settings_dialog.dart`** - User interface for notification preferences

### Key Architecture Benefits:

#### **Separation of Concerns:**
- **Models**: Pure data representations with business logic
- **Services**: External service communications and core operations
- **Controllers**: Coordinate between UI and business logic
- **Repository**: Abstract data access and caching
- **Views**: Pure UI components with minimal logic

#### **Enhanced Features:**
- **Nordic UART Service**: Standard BLE UART communication protocol with proper UUID mapping
- **Smart Notification Filtering**: Debounced notifications with duplicate prevention and user customization
- **Responsive Design System**: Adaptive layouts with mobile/tablet/desktop breakpoints
- **Modern UI Components**: Material Design 3 with animated elements and smooth transitions
- **Chat-Style Communication**: Message bubbles with timestamps and command history navigation
- **Theme Management**: Persistent dark/light mode with comprehensive color system
- **Signal Strength Visualization**: Realistic RSSI thresholds optimized for BLE devices
- **Connection Duration Tracking**: Real-time connection time display and statistics
- **MTU Auto-Configuration**: Automatic 517-byte MTU setting for optimal data transfer
- **Error Handling System**: Categorized error responses with user-friendly messaging
- **Animation Framework**: Custom painters for radar effects and status indicators

#### **Improved Maintainability:**
- **Single Responsibility**: Each class focused on specific functionality
- **Dependency Injection**: Loosely coupled components
- **Error Handling**: Centralized error management and user notifications
- **Testing**: Clear interfaces enable comprehensive unit testing

### Development Workflow:

#### **Fully Implemented Architecture:**
- Complete MVC architecture with Models, Views, Controllers, and Services
- Nordic UART Service integration for text command communication  
- Smart notification system with spam prevention and user controls
- Responsive UI system with dark/light themes and animations
- Comprehensive error handling and user feedback
- Modern Material Design 3 components throughout

#### **Current Status:**
All major features are implemented and functional. The app provides:
- Professional BLE device scanning and management
- Real-time text command communication via Nordic UART Service
- Intelligent user notification system
- Multi-platform responsive design
- Comprehensive error handling and user feedback

## BLE Usage Guide

### Basic Operations:
1. **Scan for devices**: Tap "Start Scanning" button
2. **Connect to device**: Tap connect icon next to desired device  
3. **Access Command Interface**: After device connection, tap the chat icon (💬) in the top-right corner
4. **Send text commands**: In the command interface, type commands and press Enter or tap Send
5. **View responses**: Device responses appear in real-time in the communication log
6. **Navigate command history**: Use up/down arrows to browse previous commands

### Nordic UART Service Communication:
- **Standard Protocol**: Uses Nordic UART Service (UUID: 6e400001-b5a3-f393-e0a9-e50e24dcca9e)
- **TX/RX Channels**: RX for phone->device (6e400002), TX for device->phone (6e400003) 
- **MTU Auto-Configuration**: Automatically set to 517 bytes for optimal throughput
- **UTF-8 Text Encoding**: Full international character support
- **Real-time Bidirectional**: Instant command sending and response display
- **Command History**: Navigate through last 20 commands with arrow keys
- **Connection Monitoring**: Live status indicators and duration tracking

### Supported GATT Operations:
- Service discovery with automatic UUID recognition for common services
- Characteristic property detection (Read/Write/Notify/Indicate)
- Hex and string value display for characteristic data
- Write operations with hex string parsing (supports "01,FF,A0" or "01FFA0" formats)

## UI/UX Architecture

### Responsive Design System
- **Breakpoints**: Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)
- **Adaptive Layouts**: Different UI arrangements for each screen size
- **Theme System**: Persistent dark/light mode with comprehensive color palette
- **Animation Framework**: Smooth transitions, scanning effects, and micro-interactions

### Smart Notification System
- **Intelligent Filtering**: Prevents notification spam through debouncing and deduplication
- **User Controls**: Configurable notification categories and preferences  
- **Statistics**: Track filtered vs shown notifications for optimization
- **Silent Operations**: Internal processes (MTU config, etc.) don't spam users

### Nordic UART Service Implementation
```dart
// Key Nordic UART Service UUIDs used throughout the app
const String nordicUartServiceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const String nordicUartRxUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // RX - phone writes to device  
const String nordicUartTxUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // TX - device notifies phone

// Controller usage for BLE operations
final SimpleBleController controller = SimpleBleController();
await controller.initialize();
await controller.connectToDevice(deviceId);
bool success = await controller.sendCommand("your command here");
```

### Signal Strength Optimization
RSSI thresholds optimized for typical BLE operating ranges:
- Excellent: ≥-40dBm 
- Very Good: ≥-55dBm
- Good: ≥-70dBm  
- Fair: ≥-85dBm
- Poor: <-85dBm