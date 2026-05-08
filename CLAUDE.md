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
- `lib/views/quick_setup_wizard_view.dart` - 4-step guided wizard (APN → ADDR → FTPADDR → REBOOT)
- `lib/views/custom_commands_view.dart` - Developer-mode custom command CRUD
- `lib/views/developer_options_view.dart` - Role/password management for dev mode
- `lib/controllers/simple_ble_controller.dart` - MVC controller coordinating BLE operations
- `lib/controllers/update_controller.dart` - Update lifecycle coordinator across check/download/install/preferences
- `lib/services/ble_service.dart` - Core BLE service with Nordic UART Service support
- `lib/services/ble_message_assembler.dart` - Reassembles `\r\n`-terminated lines from BLE chunks
- `lib/services/notification_service.dart` - In-app notifications with optional `NotificationFilter` (smart dedup/silence/debounce)
- `lib/services/network_service.dart` - Network connectivity monitoring and optimization
- `lib/services/update_checker.dart` / `download_manager.dart` / `install_manager.dart` / `update_preferences_store.dart` - The four narrow services behind `UpdateController`

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

#### 2. **Services Layer** (`lib/services/` — 18 files)
- **`ble_service.dart`** - Core BLE operations with Nordic UART Service implementation
- **`ble_message_assembler.dart`** - Reassembles BLE chunks into `\r\n`-delimited lines (50ms quiet-timeout fallback, 4KB safety flush)
- **`notification_service.dart`** - In-app notifications. The `NotificationService.smart()` factory enables dedup/silence/debounce via an internal `NotificationFilter` config; the plain constructor is unfiltered (used by tests). Production wires `.smart()` in `service_locator.dart`.
- **`permission_service.dart`** - Bluetooth and location permission management
- **`network_service.dart`** - Network connectivity monitoring (`connectivity_plus`)
- **`error_handling_service.dart`** - Comprehensive error categorization and user feedback
- **`theme_service.dart`** - Dark/light theme management with persistence
- **`animation_service.dart`** - Page transitions and custom animation effects
- **`layout_preference_service.dart`** - Persists user layout/density choices
- **`role_service.dart`** - Role lifecycle (normal / developer) + password hashing; broadcasts via `roleStream`
- **`custom_command_service.dart`** - Persists user-defined BLE commands (SharedPreferences, JSON)
- **`command_parameter_storage_service.dart`** - Persists last-used command parameter values
- **`device_info_tracker.dart`** - App-wide accumulator for the connected device's parsed `DeviceInfo` (subscribes to `commandResponseStream`, feeds `info_parser_service`)
- **`info_parser_service.dart`** - Stateless regex extraction from `$INFO` response lines
- **Update subsystem** (4 narrow services, coordinated by `UpdateController`):
  - **`update_checker.dart`** - GitHub API polling, version comparison, channel filtering
  - **`download_manager.dart`** - APK fetch, progress stream, retry logic, checksum
  - **`install_manager.dart`** - Native Android APK install via platform channel
  - **`update_preferences_store.dart`** - Single owner of update settings (auto-check, WiFi-only, channel, skipped versions); broadcasts via `changeStream`

#### 3. **Controllers Layer** (`lib/controllers/`)
- **`simple_ble_controller.dart`** - Main BLE operations coordinator with command support
- **`command_manager.dart`** - Shared command history + `TextEditingController` + send pipeline. Used by both `CommandInterfaceViewModel` and `QuickSetupViewModel`.
- **`update_controller.dart`** - App-wide update flow coordinator. Owns latest update info, in-flight check flag, download progress, network status, and dialog context in one place. ChangeNotifier so any UI piece that renders update state can `ListenableBuilder` it.
- **`ble_controller_interface.dart`** - Interface for `SimpleBleController` (kept because tests mock it via `MockBleController`).

#### 4. **Core Layer** (`lib/core/`)
- **`service_locator.dart`** - GetIt-based dependency injection container
- **`view_model/`** - ViewModelProvider pattern implementation (see ViewModelProvider Guide below)
- **`mixins/notification_listener_mixin.dart`** - Simplified mixin for displaying SnackBar notifications
- **`interfaces/ble_notification_delegate.dart`** - Notification delegate interface with `BleNotificationVerbosity` enum and `ConfigurableBleNotificationDelegate`

#### 5. **ViewModels Layer** (`lib/view_models/`)
- **`simple_scanner_view_model.dart`** - ViewModel for BLE scanner with device/theme/update management
- **`command_interface_view_model.dart`** - ViewModel for command interface with message management
- **`update_settings_view_model.dart`** - ViewModel for update settings with preferences management
- **`quick_setup_view_model.dart`** - ViewModel for the 4-step Quick Setup wizard
- **`custom_commands_view_model.dart`** - ViewModel for custom-command CRUD (developer mode)

#### 6. **Views Layer** (`lib/views/`)
- **`simple_scanner_view.dart`** — BLE scanner (uses `SimpleScannerViewModel`)
- **`command_interface_view.dart`** — Chat-style command interface (uses `CommandInterfaceViewModel`)
- **`update_settings_view.dart`** — Update preferences (uses `UpdateSettingsViewModel`)
- **`quick_setup_wizard_view.dart`** — Guided field-deployment wizard (uses `QuickSetupViewModel`); shares `CommandManager` with the command interface so wizard commands appear in the chat log
- **`custom_commands_view.dart`** — Developer-mode custom command CRUD (uses `CustomCommandsViewModel`)
- **`developer_options_view.dart`** — Developer mode entry / password management

#### 7. **Repositories Layer** (`lib/repositories/`)
- **`command_repository.dart`** - Canonical built-in command list (12 commands; see [`docs/command.md`](docs/command.md))
- **`custom_command_repository.dart`** - Decorator that merges user-defined commands from `CustomCommandService` into the built-in list and filters collisions
- **`role_aware_command_repository.dart`** - Outermost decorator that filters by `RoleService.currentRole` (normal-mode whitelist: `$INFO`, `$APN`, `$ADDR`, `$FTPADDR`, `$REBOOT`)

The decorator chain registered in `service_locator.dart` is:
`built-in → custom (merge) → role-aware (filter)`. UI consumers see only the outermost wrapper via `CommandRepositoryInterface`.

#### 8. **Widgets Layer** (`lib/widgets/`, organised by feature subdirectories)

**`widgets/ble/` — Scanner & device components**
- `device_list_widget.dart` / `device_grid_widget.dart` / `device_search_widget.dart` - device discovery and listing
- `connected_device_card_widget.dart` / `device_details_dialog.dart` / `device_status_panel_widget.dart` - connected device display
- `connection_status_widget.dart` / `connection_stats_panel_widget.dart` - connection state and stats
- `scanning_indicator_widget.dart` / `quick_stats_widget.dart` - scan progress and stats
- `control_panel_widget.dart` - scanner control buttons

**`widgets/message/` — Chat / command interface**
- `message_bubble_widget.dart` / `message_filter_widget.dart` - message display + filter chips
- `command_input_panel_widget.dart` / `command_history_panel_widget.dart` - text input + history navigation

**`widgets/command/` — Smart Command Center**
- `quick_access_bar_widget.dart` / `quick_command_button.dart` - quick-send buttons
- `command_menu_sheet.dart` / `command_category_tabs.dart` / `command_list_tile.dart` / `command_search_bar.dart` - command browser
- `command_form_sheet.dart` / `command_preview_widget.dart` / `command_feedback_widget.dart` - parameter form + preview + feedback
- `danger_confirm_dialog.dart` - confirmation for warning/dangerous commands (orange / red)
- `widgets/command/parameters/` - typed inputs (`text`, `dropdown`, `host_port`, `ip_port`, `hour_picker`, `bit_flags`)

**`widgets/wizard/` — Quick Setup Wizard**
- `wizard_step_form.dart` / `wizard_summary_page.dart` / `wizard_execution_page.dart`

**`widgets/dev_mode/` — Developer mode UI**
- `dev_mode_password_dialog.dart` / `change_password_dialog.dart`
- `custom_command_form_dialog.dart` - custom command edit form

**`widgets/update/` — Update system**
- `update_dialog.dart` - main update dialog container
- `update_header_widget.dart` / `version_info_widget.dart` / `update_progress_widget.dart` / `update_actions_widget.dart` - dialog parts
- `network_info_widget.dart` - network status and download suitability
- `update_notification_banner.dart` - inline update notification banner

**`widgets/layout/` & `widgets/common/`**
- `widgets/layout/responsive_layout.dart` - adaptive layout system for mobile/tablet/desktop. Re-exports `responsive_utils.dart` and `app_colors.dart` — single import covers all responsive utilities.
- `widgets/common/animated_widgets.dart` - custom animated components (scan buttons, connection status)
- `widgets/common/app_empty_state.dart` - shared empty-state placeholder

#### 9. **Localization Layer** (`lib/l10n/`)
- **`app_strings.dart`** - Centralized UI string constants for internationalization preparation

#### 10. **Utils Layer** (`lib/utils/`)
- **`responsive_utils.dart`** - Screen breakpoint management and responsive calculations
- **`app_colors.dart`** - Theme-aware color palette
- **`app_version.dart`** - CalVer + legacy SemVer parser/comparator (`AppVersion.tryParse`, `compareTo`); see [`docs/VERSIONING.md`](docs/VERSIONING.md)
- **`formatting_utils.dart`** - Duration / byte / date formatters
- **`accessibility_utils.dart`** / **`focus_management.dart`** - a11y helpers
- **`logger.dart`** - Tagged logging (`Logger.ble` / `ui` / `command` etc.; `Logger.diagnostic` for production traces — see Diagnostic section below)
- **`painters/`** - Custom CustomPainter implementations

### ViewModelProvider Pattern Guide

The application uses a custom lightweight ViewModelProvider pattern for View-specific state management. This pattern is designed to work seamlessly with the existing Service Locator (GetIt) pattern.

#### Core Components (`lib/core/view_model/`):

| Component | Purpose |
|-----------|---------|
| `BaseViewModel` | Base class with lifecycle management, stream subscriptions, loading/error states |
| `ViewModelProvider<T>` | Widget that creates, provides, and disposes ViewModels |
| `ViewModelBuilder<T>` | Consumes ViewModel from ancestor provider (for nested widgets) |
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
- `lib/widgets/layout/responsive_layout.dart` re-exports `responsive_utils.dart` and `app_colors.dart` — single import covers all responsive utilities.

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

#### Update System Architecture:
The update flow is split across one controller and four narrow services. UI consumers inject `UpdateController`; the four services are internal implementation detail.

- **`UpdateController`** (`lib/controllers/update_controller.dart`): Owns the full update lifecycle (latest info, in-flight check flag, download progress, network status, dialog context). ChangeNotifier so any UI piece can `ListenableBuilder` it.
- **`UpdateChecker`** (`lib/services/update_checker.dart`): GitHub Releases API polling, version comparison, channel filtering (`stable` vs `beta`).
- **`DownloadManager`** (`lib/services/download_manager.dart`): APK fetch with progress stream, retry, SHA256 checksum.
- **`InstallManager`** (`lib/services/install_manager.dart`): Triggers Android APK install via platform channel.
- **`UpdatePreferencesStore`** (`lib/services/update_preferences_store.dart`): Single owner of update settings (auto-check, WiFi-only, channel, skipped versions). Mutations save to disk and broadcast via `changeStream`.
- **Models**: `UpdateInfo` (version comparison + metadata), `DownloadProgress`, `UpdatePreferences`, `UpdateType`.
- **GitHub API integration**: Repository `rstltd/cg500_blueteeth_app`.

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

## Diagnostic and Troubleshooting

### Key Troubleshooting Areas

#### Update System Issues:
1. **WiFi-Only Setting Problems**: Check `lib/widgets/update/network_info_widget.dart` for proper null handling in preference loading.
2. **APK Installation Failures**: `InstallManager.diagnosePermissions()` returns a status map; use it to verify Android `canRequestPackageInstalls()` and FileProvider configuration.
3. **Download Failures**: Verify GitHub API access (`UpdateChecker`) and network connectivity (`NetworkService`); `DownloadManager` retries automatically on transient failure.
4. **Setting Synchronization**: All update-preference mutations must go through `UpdatePreferencesStore` — its `changeStream` is the single broadcast channel that `UpdateController` and the settings VM listen on.

#### Common Fix Patterns:
- **Preference Fallback Logic**: Always use non-restrictive fallbacks (allow mobile data) when settings are loading.
- **Setting Synchronization**: Call `getIt<UpdatePreferencesStore>().update(...)`; never hold a private copy of preferences.
- **Permission Handling**: Check both legacy and Android 8.0+ unknown-sources permissions.
- **Diagnostic Logging in Release Builds**: `Logger.ble` / `debug` / `command` / `info` are silent in release because `_currentLogLevel = kDebugMode ? _debugLevel : _errorLevel`. For traces that must work in production (e.g. capturing user-reported BLE bugs), use `Logger.diagnostic()` and toggle `Logger.diagnosticEnabled = true`. The diagnostic channel is used by `BleMessageAssembler` to log raw hex chunks and by the `addMessage` dedup guard in `CommandInterfaceViewModel`.

#### Documentation References:
- Versioning policy: [`docs/VERSIONING.md`](docs/VERSIONING.md)
- Device command reference: [`docs/command.md`](docs/command.md) (for the canonical app-side command list, see `lib/repositories/command_repository.dart`)
- **Architecture Decision Records**: [`docs/adr/`](docs/adr/) — load-bearing decisions that aren't obvious from the code. Read the relevant ADR before proposing structural changes; some apparent over-engineering is deliberate and the ADR explains why. Index:
  - [ADR-0001](docs/adr/0001-update-system-decomposition.md) — Why the update system is 4 narrow services + `UpdateController`, not a single facade.
  - [ADR-0002](docs/adr/0002-app-scope-rst-device-family.md) — Why this is one app for the whole RST device family (GNSS receivers, accelerometers, inclinometers), even though the repo name says `cg500`.
  - [ADR-0003](docs/adr/0003-keep-update-ui-delegate-seam.md) — Why `UpdateUIDelegate` survives despite SIMPLIFICATION_PLAN listing it for removal.
  - [ADR-0004](docs/adr/0004-command-manager-shared-instance.md) — Why `CommandManager` is a shared instance across `CommandInterfaceVM` and `QuickSetupVM`, not absorbed into either VM.
  - [ADR-0005](docs/adr/0005-role-state-not-persisted.md) — Why developer-mode state never persists across app launches (only the password hash does), even though re-prompting on every cold start is a real UX cost.
  - [ADR-0006](docs/adr/0006-quick-setup-wizard-dual-purpose.md) — Why the Quick Setup Wizard's pre-fill + diff-send-only-changes behaviour is load-bearing: it serves both commissioning and (more frequently) monthly maintenance review.
  - [ADR-0007](docs/adr/0007-wizard-startx-summary-gate.md) — Why the wizard auto-sends `$STARTX` only when changes were dispatched, and why the summary page itself (red-highlighted reboot row + dynamic Apply button) is the safety gate instead of a `DangerConfirmDialog`.
  - [ADR-0008](docs/adr/0008-scanner-device-type-filter-no-profile.md) — Why `RstDeviceType` and the BLE-name-prefix classifier are confined to scanner display + filter, and explicitly do NOT open the device-profile abstraction that ADR-0002 deferred.
- Historical architecture analyses (now stale, kept for context): [`docs/OVER_ENGINEERING_ANALYSIS.md`](docs/OVER_ENGINEERING_ANALYSIS.md), [`docs/SIMPLIFICATION_PLAN.md`](docs/SIMPLIFICATION_PLAN.md), [`docs/SMART_COMMAND_CENTER_PLAN.md`](docs/SMART_COMMAND_CENTER_PLAN.md), [`docs/TEST_COVERAGE_PLAN.md`](docs/TEST_COVERAGE_PLAN.md)