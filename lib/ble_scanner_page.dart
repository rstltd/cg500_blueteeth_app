import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_manager.dart';
import 'device_detail_page.dart';

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});

  @override
  State<BleScannerPage> createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  final BleManager _bleManager = BleManager();
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeBle();
  }

  @override
  void dispose() {
    _bleManager.dispose();
    super.dispose();
  }

  Future<void> _initializeBle() async {
    bool success = await _bleManager.initialize();
    setState(() {
      _isInitialized = success;
      _statusMessage = success 
          ? 'Ready to scan' 
          : 'Failed to initialize Bluetooth';
    });
  }

  Future<void> _startScanning() async {
    if (!await _bleManager.isBluetoothEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable Bluetooth to scan for devices'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await _bleManager.turnOnBluetooth();
      return;
    }

    await _bleManager.startScanning(timeout: const Duration(seconds: 15));
  }

  Future<void> _stopScanning() async {
    await _bleManager.stopScanning();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool success = await _bleManager.connectToDevice(device);
    
    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.platformName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to device detail page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DeviceDetailPage(device: device),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${device.platformName}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDeviceDisplayName(BluetoothDevice device) {
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }
    return 'Unknown Device';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CG500 Bluetooth Scanner'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_statusMessage),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CG500 Bluetooth Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          StreamBuilder<BluetoothDevice?>(
            stream: _bleManager.connectedDeviceStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.bluetooth_connected),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DeviceDetailPage(device: snapshot.data!),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Control panel
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<bool>(
                    stream: _bleManager.scanningStream,
                    initialData: false,
                    builder: (context, snapshot) {
                      bool isScanning = snapshot.data ?? false;
                      return ElevatedButton.icon(
                        onPressed: isScanning ? _stopScanning : _startScanning,
                        icon: Icon(isScanning ? Icons.stop : Icons.search),
                        label: Text(isScanning ? 'Stop Scanning' : 'Start Scanning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isScanning ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<BluetoothDevice?>(
                  stream: _bleManager.connectedDeviceStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ElevatedButton(
                        onPressed: () => _bleManager.disconnectDevice(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Disconnect'),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          
          // Scanning indicator
          StreamBuilder<bool>(
            stream: _bleManager.scanningStream,
            initialData: false,
            builder: (context, snapshot) {
              bool isScanning = snapshot.data ?? false;
              if (isScanning) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Scanning for devices...'),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Device list
          Expanded(
            child: StreamBuilder<List<BluetoothDevice>>(
              stream: _bleManager.scannedDevicesStream,
              initialData: const [],
              builder: (context, snapshot) {
                List<BluetoothDevice> devices = snapshot.data ?? [];
                
                if (devices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No devices found'),
                        SizedBox(height: 8),
                        Text('Tap "Start Scanning" to discover BLE devices'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = devices[index];
                    
                    return StreamBuilder<BluetoothDevice?>(
                      stream: _bleManager.connectedDeviceStream,
                      builder: (context, connectedSnapshot) {
                        bool isConnected = connectedSnapshot.data?.remoteId == device.remoteId;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                              color: isConnected ? Colors.green : Colors.blue,
                              size: 32,
                            ),
                            title: Text(
                              _getDeviceDisplayName(device),
                              style: TextStyle(
                                fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${device.remoteId.toString()}'),
                                if (isConnected)
                                  const Text(
                                    'Connected',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isConnected
                                ? IconButton(
                                    icon: const Icon(Icons.settings),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => DeviceDetailPage(device: device),
                                        ),
                                      );
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.connect_without_contact),
                                    onPressed: () => _connectToDevice(device),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}