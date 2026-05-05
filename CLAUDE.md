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

### Release and Deployment

**The authoritative versioning policy is `docs/VERSIONING.md`.** Read it before
running any release command. The summary below is convenience only; if it
disagrees with `docs/VERSIONING.md`, the doc wins.

The project uses **CalVer** (`vYY.0M[.MICRO][-beta.N]`, e.g. `v26.05`,
`v26.05.1`, `v26.05-beta.1`) with two channels — `stable` and `beta`.

- `python scripts/simple_release.py release` — monthly stable release (`26.05+31 → 26.06+33`)
- `python scripts/simple_release.py hotfix`  — same-month hotfix (`26.05+31 → 26.05.1+32`)
- `python scripts/simple_release.py beta`    — beta pre-release (`26.05+31 → 26.06-beta.1+32`)
- `python scripts/simple_release.py rc`      — release candidate (rarely used)
- `python scripts/simple_release.py build`   — build-number-only bump
- `python scripts/update_version.py current` — show current version
- `python scripts/update_version.py release|hotfix|beta|rc|build` — bump version without releasing

### Release Notes Workflow (IMPORTANT)
**Before every release**, AI must generate a user-facing `release_notes.md` file in the project root summarizing all changes since the last release. This file is used by the release script via `--notes-file`.

**Steps:**
1. Review commits since last tag: `git log $(git describe --tags --abbrev=0)..HEAD --oneline`
2. Decide the mode (`release` / `hotfix` / `beta` / `rc`) using the rules in `docs/VERSIONING.md` §5.
3. Write a clear, user-facing `release_notes.md` (in the project root) with sections like "New Features", "Improvements", "Bug Fixes" as appropriate. Write in English. Do not include commit hashes. Do not include the version number in the title — the release script supplies it.
4. Show the content to the user for approval
5. User runs: `python scripts/simple_release.py <mode> --notes-file release_notes.md`

**AI must proactively do this whenever the user asks to release/publish/deploy** — do not wait for the user to ask for release notes separately. **Never edit `pubspec.yaml` by hand to change the version** — the release script is the only authorized writer.

## Architecture

### Project Structure
- `lib/main.dart` - Main application entry point with standard Flutter counter app
- `test/widget_test.dart` - Widget tests for the main app
- Platform-specific folders: `android/`, `ios/`, `windows/`, `linux/`, `macos/`, `web/`

### Current Implementation
The app is a comprehensive Bluetooth Low Energy (BLE GATT) scanner and communication application with modern UI/UX and advanced update management:

#### Main Components:
- `main.dart` - App entry point with Material Design 3 theme and dark mode support
- `lib/views/simple_scanner_view.dart` - Modern responsive BLE scanner interface with animated components
- `lib/views/command_interface_view.dart` - Chat-style text command communication interface
- `lib/views/update_settings_view.dart` - Comprehensive update preferences management
- `lib/controllers/simple_ble_controller.dart` - MVC controller coordinating BLE operations
- `lib/services/ble_service.dart` - Core BLE service with Nordic UART Service support
- `lib/services/smart_notification_service.dart` - Intelligent notification filtering system
- `lib/services/update_service.dart` - Enhanced update management with user preferences
- `lib/services/network_service.dart` - Network connectivity monitoring and optimization

#### Key Features:
- **Nordic UART Service Communication**: Text command communication via standardized BLE UART protocol
- **Modern Responsive UI**: Material Design 3 with dark/light themes and responsive layouts for mobile/tablet/desktop
- **Advanced Update Management**: User-controlled update preferences with network awareness and retry mechanisms
- **Smart Notification System**: Unified notification control with ConfigurableBleNotificationDelegate for source-level filtering
- **BLE Device Scanning**: Automatic discovery with animated scanning indicators and signal strength visualization
- **Chat-Style Command Interface**: Real-time bidirectional communication with command history and message bubbles
- **Connection Management**: Visual connection states with duration tracking and automatic reconnection
- **Service Discovery**: Automatic GATT service enumeration with characteristic property detection
- **Permission Management**: Comprehensive Bluetooth and location permission handling
- **Animation System**: Smooth transitions, scanning effects, and connection status animations

#### Enhanced Update System:
- **User Preference Controls**: Complete settings page for managing update behavior
- **Network-Aware Downloads**: WiFi-only options with mobile data warnings and download time estimates
- **Skip Version Management**: Allow users to skip specific versions with undo functionality
- **Intelligent Retry Mechanism**: Automatic retry on download failures with progressive backoff
- **Installation Guidance**: Step-by-step visual guide for APK installation process
- **Real-time Network Monitoring**: Display current connection status and suitability for downloads

### Dependencies
- **Core**: Flutter SDK (^3.8.1)
- **BLE**: flutter_blue_plus (^1.32.12) - Primary BLE communication library
- **Permissions**: permission_handler (^11.3.1) - Handle Bluetooth and location permissions
- **Update System**: package_info_plus (^8.0.2), path_provider (^2.1.4), http (^1.2.2), url_launcher (^6.3.0)
- **Storage**: shared_preferences (^2.3.2) - Local data persistence
- **Network**: connectivity_plus (^6.0.5) - Network connectivity detection and monitoring
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

## MVC + MVVM Hybrid Architecture

The application follows an MVC (Model-View-Controller) architecture enhanced with MVVM (Model-View-ViewModel) pattern for Views. This hybrid approach provides:
- **MVC**: Overall application structure with Services and Controllers
- **MVVM**: View-specific state management via the in-house `ViewModelProvider` pattern (`lib/core/view_model/`); all main views use it.

### Architecture Layers:

#### 1. **Models Layer** (`lib/models/`)
- **`connection_state.dart`** - BLE connection state enumeration with extensions
- **`ble_device.dart`** - Complete device model with connection state, services, RSSI, favorites, and persistence
- **`ble_service.dart`** - Service model with characteristic management and UUID resolution
- **`ble_characteristic.dart`** - Characteristic model with properties, value formatting, and operations

#### 2. **Services Layer** (`lib/services/`)
- **`ble_service.dart`** - Core BLE operations with Nordic UART Service implementation
- **`smart_notification_service.dart`** - Intelligent notification filtering with debouncing and duplicate prevention
- **`update_service.dart`** - GitHub Releases-based automatic update system
- **`permission_service.dart`** - Bluetooth and location permission management
- **`notification_service.dart`** - Base notification system with categorized message types
- **`theme_service.dart`** - Dark/light theme management with persistence
- **`animation_service.dart`** - Page transitions and custom animation effects
- **`error_handling_service.dart`** - Comprehensive error categorization and user feedback

#### 3. **Controllers Layer** (`lib/controllers/`)
- **`simple_ble_controller.dart`** - Main BLE operations coordinator with command support
- **`command_manager.dart`** - Command history management and UART communication controller
- **`update_logic_manager.dart`** - Update process coordinator handling download, install, and skip operations

#### 4. **Core Layer** (`lib/core/`)
- **`service_locator.dart`** - GetIt-based dependency injection container
- **`view_model/`** - ViewModelProvider pattern implementation (see ViewModelProvider Guide below)
- **`mixins/notification_listener_mixin.dart`** - Simplified mixin for displaying SnackBar notifications
- **`interfaces/ble_notification_delegate.dart`** - Notification delegate interface with `BleNotificationVerbosity` enum and `ConfigurableBleNotificationDelegate`

#### 5. **ViewModels Layer** (`lib/view_models/`)
- **`simple_scanner_view_model.dart`** - ViewModel for BLE scanner with device/theme/update management
- **`command_interface_view_model.dart`** - ViewModel for command interface with message management
- **`update_settings_view_model.dart`** - ViewModel for update settings with preferences management

#### 6. **Views Layer** (`lib/views/`)
- **`simple_scanner_view.dart`** — BLE scanner (uses `SimpleScannerViewModel`)
- **`command_interface_view.dart`** — Chat-style command interface (uses `CommandInterfaceViewModel`)
- **`update_settings_view.dart`** — Update preferences (uses `UpdateSettingsViewModel`)

#### 7. **Widgets Layer** (`lib/widgets/`)
**Scanner Components:**
- **`device_list_widget.dart`** - BLE device discovery and listing
- **`device_grid_widget.dart`** - Grid layout for discovered devices
- **`connected_device_card_widget.dart`** - Connected device status display
- **`scanning_indicator_widget.dart`** - Animated scanning progress indicators
- **`control_panel_widget.dart`** - Scanner control buttons and options
- **`quick_stats_widget.dart`** - Real-time scanning statistics

**Communication Components:**
- **`message_bubble_widget.dart`** - Chat-style message display for BLE communication
- **`connection_status_widget.dart`** - Connection state and duration display

**Command Components:**
- **`danger_confirm_dialog.dart`** - Confirmation dialog for dangerous/warning level commands with dynamic colors (orange for warning, red for dangerous)

**Update System Components:**
- **`update_dialog.dart`** - Main update dialog container
- **`update_header_widget.dart`** - Update type header with visual indicators
- **`version_info_widget.dart`** - Version details and release notes display
- **`update_progress_widget.dart`** - Download progress indicators
- **`network_info_widget.dart`** - Network status and download suitability
- **`update_actions_widget.dart`** - Update action buttons and browser fallback
- **`install_guide_dialog.dart`** - APK installation guidance
- **`legacy_update_banner.dart`** - Legacy update notification banner

**Common UI Components:**
- **`responsive_layout.dart`** - Adaptive layout system for mobile/tablet/desktop
- **`animated_widgets.dart`** - Custom animated components (scan buttons, connection status)
- **`notification_settings_dialog.dart`** - User interface for notification preferences

#### 8. **Localization Layer** (`lib/l10n/`)
- **`app_strings.dart`** - Centralized UI string constants for internationalization preparation

#### 9. **Utils Layer** (`lib/utils/`)
- **`responsive_utils.dart`** - Screen breakpoint management and responsive calculations
- **`logger.dart`** - Application logging utilities

### ViewModelProvider Pattern Guide

The application uses a custom lightweight ViewModelProvider pattern for View-specific state management. This pattern is designed to work seamlessly with the existing Service Locator (GetIt) pattern.

#### Core Components (`lib/core/view_model/`):

| Component | Purpose |
|-----------|---------|
| `BaseViewModel` | Base class with lifecycle management, stream subscriptions, loading/error states |
| `ViewModelProvider<T>` | Widget that creates, provides, and disposes ViewModels |
| `ViewModelBuilder<T>` | Consumes ViewModel from ancestor provider |
| `ViewModelSelector<T, S>` | Fine-grained rebuilds based on selected value |
| `ViewModelConsumer<T>` | Built-in loading/error state handling |
| `ViewModelListener<T>` | Side effects without rebuilds |
| `MountedAwareMixin` | Safe widget mount state tracking |

#### Creating a ViewModel:

```dart
import 'package:cg500_blueteeth_app/core/view_model/view_model.dart';

class MyViewModel extends BaseViewModel with MountedAwareMixin {
  // Dependencies (can be injected or from service locator)
  late final MyService _service;

  // State
  final List<String> _items = [];
  List<String> get items => List.unmodifiable(_items);

  @override
  Future<void> onInit() async {
    // Called automatically after creation
    _service = getIt<MyService>();

    // Subscribe to streams (auto-cancelled on dispose)
    subscribe<String>(
      _service.dataStream,
      (data) => _onDataReceived(data),
    );

    // Load initial data
    await _loadData();
  }

  void _onDataReceived(String data) {
    _items.add(data);
    safeNotifyListeners(); // Safe to call even after dispose
  }

  Future<void> _loadData() async {
    setLoading(true);
    try {
      final data = await _service.fetchData();
      _items.addAll(data);
    } catch (e) {
      setError('Failed to load: $e');
    } finally {
      setLoading(false);
    }
  }

  @override
  void onDispose() {
    // Custom cleanup (stream subscriptions are auto-cancelled)
    super.onDispose();
  }
}
```

#### Using ViewModelProvider in a View:

```dart
import 'package:cg500_blueteeth_app/core/view_model/view_model.dart';

class MyView extends StatelessWidget {
  const MyView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<MyViewModel>(
      create: () => MyViewModel(),
      builder: (context, viewModel, child) {
        // Handle loading state
        if (!viewModel.isInitialized) {
          return const CircularProgressIndicator();
        }

        // Handle error state
        if (viewModel.hasError) {
          return Text('Error: ${viewModel.errorMessage}');
        }

        // Main content
        return MyContent(viewModel: viewModel);
      },
    );
  }
}
```

#### Accessing ViewModel from Descendants:

```dart
// Method 1: Using static method
final vm = ViewModelProvider.of<MyViewModel>(context);

// Method 2: Using context extension (recommended)
final vm = context.viewModel<MyViewModel>();

// Method 3: Safe access (returns null if not found)
final vm = ViewModelProvider.maybeOf<MyViewModel>(context);
```

#### Using ViewModelSelector for Optimized Rebuilds:

```dart
ViewModelSelector<MyViewModel, int>(
  selector: (vm) => vm.items.length,  // Only rebuild when length changes
  builder: (context, itemCount, child) {
    return Text('Items: $itemCount');
  },
)
```

#### Using ViewModelListener for Side Effects:

```dart
ViewModelListener<MyViewModel>(
  listenWhen: (vm) => vm.hasError,  // Only listen when has error
  listener: (context, vm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.errorMessage!)),
    );
  },
  child: MyContent(),
)
```

#### Key Features:
- **Automatic Lifecycle**: ViewModels are created, initialized, and disposed automatically
- **Stream Auto-Cleanup**: All stream subscriptions are cancelled on dispose
- **Safe Notifications**: `safeNotifyListeners()` prevents errors after dispose
- **Loading/Error States**: Built-in `isLoading`, `hasError`, `errorMessage` properties
- **Mounted State Tracking**: `MountedAwareMixin` for safe async operations
- **Service Locator Compatible**: Works with existing GetIt dependency injection

#### Creating New Views (ViewModelProvider Pattern):
1. Create a new ViewModel class extending `BaseViewModel`
2. Move state and business logic to the ViewModel
3. Use `subscribe()` method for stream subscriptions (auto-cleanup on dispose)
4. Create view using `ViewModelProvider` wrapper
5. Add comprehensive tests for both ViewModel and View
6. Follow existing patterns in `simple_scanner_view.dart` as reference

### Key Architecture Benefits:

#### **Separation of Concerns:**
- **Models**: Pure data representations with business logic and state management
- **Services**: External service communications, core operations, and system integrations
- **Controllers**: Coordinate between UI and business logic, manage state transitions
- **Views**: Main application screens with minimal logic, orchestrate widget components
- **Widgets**: Focused, reusable UI components following single responsibility principle
- **Utils**: Pure utility functions and helper classes for common operations

#### **Improved Maintainability:**
- **Single Responsibility**: Each class focused on specific functionality
- **Dependency Injection**: Loosely coupled components
- **Error Handling**: Centralized error management and user notifications
- **Testing**: Clear interfaces enable comprehensive unit testing
- **Zero-Cost Deployment**: Automated release system using GitHub infrastructure

### Development Workflow:

#### **Modular Widget Architecture:**
The codebase follows strict single responsibility principles with highly modular components:
- Each widget has a single, focused responsibility (e.g., `UpdateProgressWidget` only handles progress display)
- Controllers separate business logic from UI components
- Services provide clean APIs for external integrations
- Models encapsulate data and state management
- This architecture enables easy testing, maintenance, and feature additions

#### **Conventions:**
- `lib/widgets/common/responsive_layout.dart` re-exports `responsive_utils.dart` and `app_colors.dart` — single import for all responsive utilities.

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
- **Unified Notification Control**: Single "Notification Level" setting for simplified user experience
- **ConfigurableBleNotificationDelegate**: Runtime-configurable notification filtering at source level
- **Four Verbosity Levels**:
  - `Errors Only` (minimal) - Only show error notifications (recommended)
  - `Errors & Warnings` (normal) - Show errors and warnings
  - `All Details` (verbose) - Show all notifications including info and success
  - `Silent` - Don't generate any notifications
- **Intelligent Filtering**: Prevents notification spam through debouncing and deduplication
- **Statistics**: Track filtered vs shown notifications for optimization
- **Silent Operations**: Internal processes (MTU config, etc.) don't spam users
- **NotificationListenerMixin**: Simplified mixin for Views to display SnackBar notifications

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

### BLE Response Reassembly (BleMessageAssembler)
CG500 device responses are `\r\n` line-terminated and frequently span multiple BLE notifications. Long responses like `$INFO`, `$SHOWP`, `$CMD`, and the `$DEBUG` GPS stream exceed `MTU - 3` (~514 bytes) and arrive as several chunks that must be reassembled into logical messages.

- **Never decode `characteristic.lastValueStream` chunks directly** — feed them into `BleMessageAssembler` (`lib/services/ble_message_assembler.dart`).
- The assembler emits **one message per `\r\n` / `\n` line** (line drain has zero-delay), with a **50ms quiet-timeout fallback** for un-delimited streaming output and a **4KB overflow safety flush**. UTF-8 is decoded with `allowMalformed: true` so multi-byte codepoints split across chunk boundaries do not throw.
- When re-subscribing to the TX characteristic on reconnect, **always `await _responseSubscription?.cancel()` and `_assembler?.dispose()` first**. The previous broadcast subscription is not auto-cancelled when the field is overwritten — leaking it causes N-fold duplicate emissions.

### Signal Strength Optimization
RSSI thresholds optimized based on real-world BLE testing (-60 dBm at ~10cm, -80 dBm at ~1m):
- Excellent: ≥-65dBm (1.0 signal strength)
- Very Good: ≥-75dBm (0.8 signal strength)
- Good: ≥-85dBm (0.6 signal strength)
- Fair: ≥-95dBm (0.4 signal strength)
- Poor: <-95dBm (0.2 or 0.1 signal strength)

## Deployment and Release System

### GitHub-Based Zero-Cost Deployment
The application uses a complete GitHub Releases-based deployment system that eliminates the need for additional servers:

#### Automated Release Process:
- **One-command release**: `python scripts/simple_release.py release|hotfix|beta|rc` (see `docs/VERSIONING.md`)
- **Automatic version management**: Updates `pubspec.yaml` using CalVer (`vYY.0M[.MICRO][-beta.N]+BUILD`)
- **APK building**: Clean Flutter release build with optimized size
- **GitHub Release creation**: Automated release notes and APK upload; `beta`/`rc` modes mark the release as `prerelease=true`
- **Git integration**: Commits version changes and pushes to repository

#### In-App Update System:
- **Automatic update checking**: Queries GitHub Releases API on app startup
- **Smart update notifications**: Categorized update types (optional, recommended, forced)
- **Seamless APK installation**: Downloads and installs updates directly from GitHub
- **Private repository support**: Works with private repositories via GitHub API

#### Update Service Architecture:
- **UpdateService** (`lib/services/update_service.dart`): Core update management
- **UpdateInfo model**: Version comparison and release metadata
- **GitHub API integration**: Repository: `rstltd/cg500_blueteeth_app`
- **Download management**: Progress tracking and error handling
- **Platform channel**: Android APK installation via native code

#### Prerequisites for Deployment:
1. **GitHub CLI**: `winget install GitHub.cli`
2. **Authentication**: `gh auth login`
3. **Repository access**: Configured for `rstltd/cg500_blueteeth_app`

#### Version Management:
- **Calendar versioning (CalVer)**: `vYY.0M[.MICRO][-beta.N]+BUILD` — see `docs/VERSIONING.md`
- **Channels**: `stable` (default) and `beta` (opt-in via update settings)
- **Build number**: monotonically increases on every release across both channels (Android `versionCode` requirement)
- **Release notes**: User-supplied via `--notes-file release_notes.md`. Auto-generated commit-log notes are a fallback only — they leak internal jargon
- **Force updates**: Support for critical updates via `[forced]` / `[critical]` markers in release notes

This system provides professional-grade deployment capabilities without server maintenance costs, leveraging GitHub's infrastructure for reliable global distribution.

## Diagnostic and Testing Tools

### Test Runners
The project includes specialized diagnostic tools for troubleshooting specific functionality:

#### WiFi Only Settings Test:
```bash
flutter run -t test_wifi_only.dart
```
- Tests WiFi-only download preferences behavior
- Validates setting synchronization between UI and services
- Simulates network condition testing
- Verifies preference loading and fallback logic

#### Permission Diagnosis Tool:
```bash
flutter run -t test_permissions.dart
```
- Diagnoses Android APK installation permissions
- Tests `canRequestPackageInstalls()` functionality
- Validates FileProvider configuration
- Provides step-by-step permission request flow

### Key Troubleshooting Areas

#### Update System Issues:
1. **WiFi-Only Setting Problems**: Check `lib/widgets/network_info_widget.dart` for proper null handling in preference loading
2. **APK Installation Failures**: Use `test_permissions.dart` to validate Android permissions and FileProvider setup
3. **Download Failures**: Verify GitHub API access and network connectivity in UpdateService
4. **Setting Synchronization**: Ensure `UpdateService.updatePreferences()` is called after UI preference changes

#### Common Fix Patterns:
- **Preference Fallback Logic**: Always use non-restrictive fallbacks (allow mobile data) when settings are loading
- **Setting Synchronization**: Call `updateService.updatePreferences(prefs)` after any UI setting changes
- **Permission Handling**: Check both legacy and Android 8.0+ unknown sources permissions
- **Diagnostic Logging in Release Builds**: `Logger.ble` / `debug` / `command` / `info` are silent in release because `_currentLogLevel = kDebugMode ? _debugLevel : _errorLevel`. For traces that must work in production (e.g. capturing user-reported BLE bugs), use `Logger.diagnostic()` and toggle `Logger.diagnosticEnabled = true`. The diagnostic channel is used by `BleMessageAssembler` to log raw hex chunks and by the `addMessage` dedup guard in `CommandInterfaceViewModel`.

#### Documentation References:
- WiFi-only fix details: `WIFI_ONLY_FIX.md`
- Architecture patterns: Follow MVC separation with single-responsibility widgets