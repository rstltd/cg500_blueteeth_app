import 'dart:async';

import '../controllers/ble_controller_interface.dart';
import '../models/ble_device.dart';
import '../models/connection_state.dart';
import '../models/device_info.dart';
import 'info_parser_service.dart';

/// Tracks the connected device's structured [DeviceInfo] by listening to
/// the BLE controller's response stream and incrementally applying
/// [InfoParserService.updateFromLine] to each non-command response line.
///
/// Replaces the older pattern where every consumer re-buffered raw response
/// lines and re-parsed them. With the tracker, the first $INFO response on a
/// connection populates [current], subsequent $INFO responses overwrite
/// fields they touch (last-wins), and disconnects reset [current] to empty.
///
/// Lifecycle: register as a singleton in the service locator. The tracker
/// subscribes lazily on first construction; nothing else needs to drive it.
class DeviceInfoTracker {
  DeviceInfoTracker({required BleControllerInterface controller})
      : _controller = controller {
    _responseSubscription =
        _controller.commandResponseStream.listen(_onResponseLine);
    _connectionSubscription =
        _controller.connectedDeviceStream.listen(_onConnectionChanged);
  }

  final BleControllerInterface _controller;
  StreamSubscription<String>? _responseSubscription;
  StreamSubscription<BleDeviceModel?>? _connectionSubscription;

  final StreamController<DeviceInfo> _infoController =
      StreamController<DeviceInfo>.broadcast();

  DeviceInfo _current = const DeviceInfo();

  /// The most recent parsed device info. Empty [DeviceInfo] when no
  /// $INFO line has been received on the current connection.
  DeviceInfo get current => _current;

  /// Emits a new [DeviceInfo] every time a response line updates any field,
  /// and an empty one on disconnect.
  Stream<DeviceInfo> get infoStream => _infoController.stream;

  void _onResponseLine(String line) {
    final next = InfoParserService.updateFromLine(_current, line);
    if (!identical(next, _current)) {
      _current = next;
      _infoController.add(_current);
    }
  }

  void _onConnectionChanged(BleDeviceModel? device) {
    final disconnected =
        device == null || !device.connectionState.isConnected;
    if (disconnected && _current != const DeviceInfo()) {
      _current = const DeviceInfo();
      _infoController.add(_current);
    }
  }

  void dispose() {
    _responseSubscription?.cancel();
    _connectionSubscription?.cancel();
    _infoController.close();
  }
}
