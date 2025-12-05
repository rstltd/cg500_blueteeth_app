# Dependency Injection Refactoring Plan

## Overview

This document outlines the plan to introduce dependency injection (DI) using `get_it` to improve testability and maintainability of the BLE + Update system.

## Current Problems

### 1. Singleton Hard Dependencies
```dart
// Current: Services create their own dependencies internally
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;

  final PermissionService _permissionService = PermissionService();  // Cannot mock
  final SmartNotificationService _notificationService = SmartNotificationService();  // Cannot mock
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();

  final SmartNotificationService _notificationService = SmartNotificationService();  // Cannot mock
  final NetworkService _networkService = NetworkService();  // Cannot mock
}
```

### 2. Tight Coupling Between Services
```
UpdateService -> NetworkService -> (external: connectivity_plus)
             -> SmartNotificationService

BleService -> PermissionService -> (external: permission_handler)
          -> SmartNotificationService
          -> (external: flutter_blue_plus)
```

## Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Service Locator                          │
│                         (get_it)                                │
├─────────────────────────────────────────────────────────────────┤
│  Interfaces                    │  Implementations               │
│  ─────────────                 │  ─────────────────             │
│  NetworkServiceInterface   ────┼─► NetworkService               │
│  NotificationServiceInterface ─┼─► SmartNotificationService     │
│  BleServiceInterface       ────┼─► BleService                   │
│  UpdateServiceInterface    ────┼─► UpdateService                │
│  BleControllerInterface    ────┼─► SimpleBleController          │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Test Environment                        │
├─────────────────────────────────────────────────────────────────┤
│  Mock Implementations                                           │
│  ─────────────────────                                          │
│  MockNetworkService                                             │
│  MockNotificationService                                        │
│  MockBleService                                                 │
│  MockUpdateService                                              │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Setup DI Infrastructure
**Files to create:**
- `lib/core/service_locator.dart` - Main DI container setup
- `lib/core/interfaces/` - Interface definitions

**Changes:**
- Add `get_it` dependency to `pubspec.yaml`
- Modify `main.dart` to initialize service locator

### Phase 2: NetworkService Interface
**Files to create:**
- `lib/core/interfaces/network_service_interface.dart`

**Files to modify:**
- `lib/services/network_service.dart` - Implement interface, accept constructor injection

### Phase 3: NotificationService Interface
**Files to create:**
- `lib/core/interfaces/notification_service_interface.dart`

**Files to modify:**
- `lib/services/smart_notification_service.dart` - Implement interface

### Phase 4: BleService Interface
**Files to create:**
- `lib/core/interfaces/ble_service_interface.dart`

**Files to modify:**
- `lib/services/ble_service.dart` - Implement interface, accept dependencies via constructor

### Phase 5: UpdateService Interface
**Files to create:**
- `lib/core/interfaces/update_service_interface.dart`

**Files to modify:**
- `lib/services/update_service.dart` - Implement interface, accept dependencies via constructor

### Phase 6: Controller Layer DI
**Files to modify:**
- `lib/controllers/simple_ble_controller.dart` - Accept dependencies via constructor
- `lib/controllers/ble_controller_interface.dart` - Already exists, may need updates

### Phase 7: Test Infrastructure
**Files to create:**
- `test/mocks/mock_network_service.dart`
- `test/mocks/mock_notification_service.dart`
- `test/mocks/mock_ble_service.dart`
- `test/mocks/mock_update_service.dart`
- `test/helpers/test_service_locator.dart`

## Detailed Implementation

### Phase 1: Service Locator Setup

```dart
// lib/core/service_locator.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Initialize all services for production use
Future<void> setupServiceLocator() async {
  // Register services in dependency order

  // 1. Base services (no dependencies)
  getIt.registerLazySingleton<NetworkServiceInterface>(
    () => NetworkService(),
  );

  getIt.registerLazySingleton<NotificationServiceInterface>(
    () => SmartNotificationService(),
  );

  getIt.registerLazySingleton<PermissionServiceInterface>(
    () => PermissionService(),
  );

  // 2. Services with dependencies
  getIt.registerLazySingleton<BleServiceInterface>(
    () => BleService(
      permissionService: getIt<PermissionServiceInterface>(),
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );

  getIt.registerLazySingleton<UpdateServiceInterface>(
    () => UpdateService(
      networkService: getIt<NetworkServiceInterface>(),
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );

  // 3. Controllers
  getIt.registerLazySingleton<BleControllerInterface>(
    () => SimpleBleController(
      bleService: getIt<BleServiceInterface>(),
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );
}

/// Reset service locator (for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
```

### Phase 2: NetworkService Interface

```dart
// lib/core/interfaces/network_service_interface.dart
import 'dart:async';

/// Network connectivity status
enum NetworkStatus {
  none('No Connection'),
  mobile('Mobile Data'),
  wifi('WiFi'),
  unknown('Unknown');

  const NetworkStatus(this.displayName);
  final String displayName;
}

/// Interface for network connectivity monitoring
abstract class NetworkServiceInterface {
  /// Stream of network status changes
  Stream<NetworkStatus> get networkStream;

  /// Current network status
  NetworkStatus get currentStatus;

  /// Initialize network monitoring
  Future<bool> initialize();

  /// Check if current network is suitable for downloads
  bool isSuitableForDownload({required bool wifiOnly});

  /// Get user-friendly status description
  String getStatusDescription();

  /// Get network type display name
  String getNetworkTypeDisplayName();

  /// Estimate download time based on file size
  String estimateDownloadTime(int fileSizeBytes);

  /// Dispose resources
  void dispose();
}
```

### Phase 4: BleService Interface

```dart
// lib/core/interfaces/ble_service_interface.dart
import 'dart:async';
import '../../models/ble_device.dart';
import '../../models/ble_service.dart';

/// Interface for BLE operations
abstract class BleServiceInterface {
  // Streams
  Stream<List<BleDeviceModel>> get devicesStream;
  Stream<bool> get scanningStream;
  Stream<BleDeviceModel?> get connectedDeviceStream;
  Stream<String> get commandResponseStream;

  // State getters
  List<BleDeviceModel> get scannedDevices;
  BleDeviceModel? get connectedDevice;
  bool get isScanning;
  bool get isInitialized;

  // Operations
  Future<bool> initialize();
  Future<bool> isBluetoothEnabled();
  Future<void> turnOnBluetooth();
  Future<bool> startScanning({Duration timeout});
  Future<void> stopScanning();
  Future<bool> connectToDevice(String deviceId);
  Future<void> disconnectDevice();
  Future<List<BleServiceModel>> discoverServices(String deviceId);
  Future<bool> sendCommand(String command);
  Map<String, dynamic> getCommandInfo();
  void clearScannedDevices();
  void dispose();
}
```

## Migration Strategy

### Backward Compatibility
To ensure existing code continues to work during migration:

1. **Keep factory constructors** - Allow both DI and direct instantiation
2. **Optional constructor parameters** - Dependencies can be injected or use defaults
3. **Incremental migration** - One service at a time

```dart
// Example: Backward compatible service
class NetworkService implements NetworkServiceInterface {
  // Keep singleton for backward compatibility
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;

  // Allow dependency injection for testing
  NetworkService._internal();

  // Named constructor for DI
  NetworkService.withDependencies();  // No deps needed for this service

  // ... rest of implementation
}
```

### Migration Order
1. `NetworkService` - No dependencies, easiest to start
2. `SmartNotificationService` - No dependencies
3. `PermissionService` - No dependencies (external only)
4. `BleService` - Depends on Permission + Notification
5. `UpdateService` - Depends on Network + Notification
6. `SimpleBleController` - Depends on BleService + Notification

## Testing Strategy

### Unit Test Example
```dart
// test/services/network_service_test.dart
void main() {
  late NetworkService networkService;

  setUp(() {
    networkService = NetworkService.withDependencies();
  });

  tearDown(() {
    networkService.dispose();
  });

  test('initial status is unknown', () {
    expect(networkService.currentStatus, NetworkStatus.unknown);
  });
}
```

### Integration Test with Mocks
```dart
// test/controllers/simple_ble_controller_test.dart
void main() {
  late SimpleBleController controller;
  late MockBleService mockBleService;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockBleService = MockBleService();
    mockNotificationService = MockNotificationService();

    controller = SimpleBleController.withDependencies(
      bleService: mockBleService,
      notificationService: mockNotificationService,
    );
  });

  test('initialize calls bleService.initialize', () async {
    when(() => mockBleService.initialize()).thenAnswer((_) async => true);

    final result = await controller.initialize();

    expect(result, true);
    verify(() => mockBleService.initialize()).called(1);
  });
}
```

## Success Criteria

1. **All existing tests pass** after refactoring
2. **New unit tests** for each service with mocked dependencies
3. **Coverage improvement** target: 60%+ (currently 53.8%)
4. **No runtime behavior changes** - existing functionality works identically

## Estimated Time

| Phase | Estimated Time |
|-------|---------------|
| Phase 1: DI Setup | 30 min |
| Phase 2: NetworkService | 30 min |
| Phase 3: NotificationService | 30 min |
| Phase 4: BleService | 45 min |
| Phase 5: UpdateService | 45 min |
| Phase 6: Controller | 30 min |
| Phase 7: Tests | 60 min |
| **Total** | **~4.5 hours** |

## Rollback Plan

If issues arise during migration:
1. Each phase is independent - can revert individual changes
2. Factory constructors preserved - old code paths still work
3. Git commits per phase - easy to identify and revert specific changes
