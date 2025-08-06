import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_manager.dart';

class DeviceDetailPage extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final BleManager _bleManager = BleManager();
  List<BluetoothService> _services = [];
  bool _isDiscovering = false;
  final Map<String, List<int>> _characteristicValues = {};
  final Map<String, bool> _notificationSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _discoverServices();
    _listenToConnectionState();
  }

  void _listenToConnectionState() {
    widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device disconnected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    setState(() {
      _isDiscovering = true;
    });

    try {
      List<BluetoothService> services = await _bleManager.getServices();
      setState(() {
        _services = services;
        _isDiscovering = false;
      });
    } catch (e) {
      setState(() {
        _isDiscovering = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error discovering services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      List<int>? value = await _bleManager.readCharacteristic(characteristic);
      if (value != null) {
        setState(() {
          _characteristicValues[characteristic.uuid.toString()] = value;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading characteristic: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _writeCharacteristic(BluetoothCharacteristic characteristic) async {
    TextEditingController controller = TextEditingController();
    
    String? result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write to ${_getCharacteristicName(characteristic)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Hex value (e.g., 01,02,03 or 010203)',
                hintText: 'Enter comma-separated or continuous hex values',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Examples: "01,FF,A0" or "01FFA0"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Write'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        List<int> bytes = _parseHexString(result);
        bool success = await _bleManager.writeCharacteristic(characteristic, bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Write successful' : 'Write failed'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error parsing hex string: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<int> _parseHexString(String hex) {
    // Remove spaces and convert to uppercase
    hex = hex.replaceAll(' ', '').toUpperCase();
    
    // Handle comma-separated format
    if (hex.contains(',')) {
      return hex.split(',').map((s) => int.parse(s.trim(), radix: 16)).toList();
    }
    
    // Handle continuous hex format
    if (hex.length % 2 != 0) {
      throw const FormatException('Invalid hex string length');
    }
    
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      String hexPair = _safeSubstring(hex, i, i + 2);
      if (hexPair.length == 2) {
        bytes.add(int.parse(hexPair, radix: 16));
      }
    }
    
    return bytes;
  }

  Future<void> _toggleNotification(BluetoothCharacteristic characteristic) async {
    String key = characteristic.uuid.toString();
    bool currentlySubscribed = _notificationSubscriptions[key] ?? false;
    
    try {
      if (currentlySubscribed) {
        await characteristic.setNotifyValue(false);
        setState(() {
          _notificationSubscriptions[key] = false;
        });
      } else {
        await characteristic.setNotifyValue(true);
        
        // Listen to value changes
        characteristic.lastValueStream.listen((value) {
          setState(() {
            _characteristicValues[key] = value;
          });
        });
        
        setState(() {
          _notificationSubscriptions[key] = true;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlySubscribed 
                ? 'Notifications disabled' 
                : 'Notifications enabled'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _safeSubstring(String str, int start, int end) {
    if (start >= str.length) return '';
    if (end > str.length) end = str.length;
    if (start >= end) return '';
    return str.substring(start, end);
  }

  String _getServiceName(BluetoothService service) {
    Map<String, String> knownServices = {
      '1800': 'Generic Access',
      '1801': 'Generic Attribute',
      '180f': 'Battery Service',
      '1812': 'Human Interface Device',
    };
    
    String uuidStr = service.uuid.toString();
    String shortUuid = _safeSubstring(uuidStr, 4, 8).toLowerCase();
    return knownServices[shortUuid] ?? 'Service ${_safeSubstring(uuidStr, 0, 8)}...';
  }

  String _getCharacteristicName(BluetoothCharacteristic characteristic) {
    Map<String, String> knownCharacteristics = {
      '2a00': 'Device Name',
      '2a01': 'Appearance',
      '2a04': 'Peripheral Preferred Connection Parameters',
      '2a19': 'Battery Level',
    };
    
    String uuidStr = characteristic.uuid.toString();
    String shortUuid = _safeSubstring(uuidStr, 4, 8).toLowerCase();
    return knownCharacteristics[shortUuid] ?? 'Characteristic ${_safeSubstring(uuidStr, 0, 8)}...';
  }

  String _formatByteArray(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  String _formatByteArrayAsString(List<int> bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (e) {
      return 'Binary data';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName.isNotEmpty 
            ? widget.device.platformName 
            : 'BLE Device'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _discoverServices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Device info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_connected, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Connected', style: TextStyle(color: Colors.green)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _bleManager.disconnectDevice(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Device ID: ${widget.device.remoteId.toString()}'),
                  Text('Services: ${_services.length}'),
                ],
              ),
            ),
          ),
          
          // Services list
          Expanded(
            child: _isDiscovering
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No services found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, serviceIndex) {
                          BluetoothService service = _services[serviceIndex];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ExpansionTile(
                              title: Text(_getServiceName(service)),
                              subtitle: Text('UUID: ${service.uuid}'),
                              leading: const Icon(Icons.miscellaneous_services),
                              children: service.characteristics.map((characteristic) {
                                String charKey = characteristic.uuid.toString();
                                List<int>? value = _characteristicValues[charKey];
                                bool isSubscribed = _notificationSubscriptions[charKey] ?? false;
                                
                                return ListTile(
                                  title: Text(_getCharacteristicName(characteristic)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('UUID: ${characteristic.uuid}'),
                                      Text('Properties: ${_getPropertiesString(characteristic.properties)}'),
                                      if (value != null) ...[
                                        Text('Hex: ${_formatByteArray(value)}'),
                                        Text('String: ${_formatByteArrayAsString(value)}'),
                                      ],
                                    ],
                                  ),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      if (characteristic.properties.read)
                                        IconButton(
                                          icon: const Icon(Icons.download, size: 20),
                                          onPressed: () => _readCharacteristic(characteristic),
                                          tooltip: 'Read',
                                        ),
                                      if (characteristic.properties.write || characteristic.properties.writeWithoutResponse)
                                        IconButton(
                                          icon: const Icon(Icons.upload, size: 20),
                                          onPressed: () => _writeCharacteristic(characteristic),
                                          tooltip: 'Write',
                                        ),
                                      if (characteristic.properties.notify || characteristic.properties.indicate)
                                        IconButton(
                                          icon: Icon(
                                            isSubscribed ? Icons.notifications_active : Icons.notifications_none,
                                            size: 20,
                                            color: isSubscribed ? Colors.orange : null,
                                          ),
                                          onPressed: () => _toggleNotification(characteristic),
                                          tooltip: isSubscribed ? 'Disable notifications' : 'Enable notifications',
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _getPropertiesString(CharacteristicProperties properties) {
    List<String> props = [];
    if (properties.read) props.add('Read');
    if (properties.write) props.add('Write');
    if (properties.writeWithoutResponse) props.add('WriteNoResp');
    if (properties.notify) props.add('Notify');
    if (properties.indicate) props.add('Indicate');
    if (properties.authenticatedSignedWrites) props.add('AuthWrite');
    if (properties.extendedProperties) props.add('Extended');
    if (properties.notifyEncryptionRequired) props.add('NotifyEnc');
    if (properties.indicateEncryptionRequired) props.add('IndicateEnc');
    
    return props.join(', ');
  }
}