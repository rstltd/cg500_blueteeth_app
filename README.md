# CG500 BLE App

A comprehensive Flutter application for Bluetooth Low Energy (BLE) device scanning and communication using Nordic UART Service.

## Features

- **BLE Device Scanning**: Automatic discovery with animated scanning indicators and signal strength visualization
- **Nordic UART Service Communication**: Text command communication via standardized BLE UART protocol
- **Modern Responsive UI**: Material Design 3 with dark/light themes and responsive layouts for mobile/tablet/desktop
- **Smart Notification System**: Intelligent filtering to prevent notification spam with user-configurable settings
- **Chat-Style Command Interface**: Real-time bidirectional communication with command history and message bubbles
- **Connection Management**: Visual connection states with duration tracking and automatic reconnection
- **Automatic Updates**: GitHub Releases-based update system with in-app notifications

## Getting Started

### Prerequisites

- Flutter SDK (^3.8.1)
- Android development environment
- Bluetooth Low Energy capable device

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/rstltd/cg500_blueteeth_app.git
   cd cg500_blueteeth_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Scan for devices**: Tap "Start Scanning" button
2. **Connect to device**: Tap connect icon next to desired device  
3. **Access Command Interface**: After device connection, tap the chat icon (💬) in the top-right corner
4. **Send text commands**: In the command interface, type commands and press Enter or tap Send
5. **View responses**: Device responses appear in real-time in the communication log

## BLE Protocol

- **Service**: Nordic UART Service (UUID: 6e400001-b5a3-f393-e0a9-e50e24dcca9e)
- **TX/RX Channels**: RX for phone→device (6e400002), TX for device→phone (6e400003)
- **MTU**: Auto-configured to 517 bytes for optimal throughput
- **Encoding**: UTF-8 text with full international character support

## Development

### Key Commands

- `flutter run` - Run with hot reload
- `flutter test` - Run tests
- `flutter analyze` - Static analysis
- `flutter build apk` - Build release APK

### Deployment

This project uses GitHub Releases for deployment:

```bash
# Release new version
python scripts/simple_release.py patch   # Bug fixes (1.0.0 → 1.0.1)
python scripts/simple_release.py minor   # New features (1.0.1 → 1.1.0)
python scripts/simple_release.py major   # Breaking changes (1.1.0 → 2.0.0)
```

See [GITHUB_DEPLOYMENT.md](GITHUB_DEPLOYMENT.md) for detailed deployment instructions.

## Architecture

The application follows MVC architecture with additional Service and Repository layers:

- **Models**: Data representations (`lib/models/`)
- **Views**: UI components (`lib/views/`)
- **Controllers**: Business logic coordination (`lib/controllers/`)
- **Services**: External communications and core operations (`lib/services/`)

## Key Dependencies

- **flutter_blue_plus**: BLE communication
- **permission_handler**: Bluetooth permissions
- **shared_preferences**: Local data persistence
- **package_info_plus**: Version management
- **http**: Network requests for updates

## Requirements

- **Minimum Android Version**: 6.0 (API 23)
- **Permissions**: Bluetooth, Location
- **Hardware**: Bluetooth Low Energy support

## License

This project is private and proprietary.
