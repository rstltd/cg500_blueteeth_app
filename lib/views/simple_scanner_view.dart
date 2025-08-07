import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../models/ble_device.dart';
import '../models/connection_state.dart';
import '../services/animation_service.dart';
import '../services/notification_service.dart'; // For NotificationModel and NotificationType
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/notification_settings_dialog.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/legacy_update_banner.dart';
import 'command_interface_view.dart';
import 'update_settings_view.dart';

/// Simple Scanner View demonstrating MVC architecture usage
/// Shows how Views interact with Controllers instead of directly with Services
class SimpleScannerView extends StatefulWidget {
  const SimpleScannerView({super.key});

  @override
  State<SimpleScannerView> createState() => _SimpleScannerViewState();
}

class _SimpleScannerViewState extends State<SimpleScannerView> {
  final SimpleBleController _controller = SimpleBleController();
  final ThemeService _themeService = ThemeService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    bool success = await _controller.initialize();
    setState(() {
      _isInitialized = success;
    });
  }

  void _listenToNotifications() {
    _controller.notificationStream.listen((notification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.message}'),
            backgroundColor: _getNotificationColor(notification.type),
            duration: notification.duration ?? const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CG500 BLE Scanner'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing BLE Controller...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CG500 BLE Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Notification Settings Button
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const NotificationSettingsDialog(),
            ),
            tooltip: 'Notification Settings',
          ),
          
          // More Settings Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Settings',
            onSelected: (String value) {
              switch (value) {
                case 'update_settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpdateSettingsView(),
                    ),
                  );
                  break;
                case 'toggle_theme':
                  _themeService.toggleTheme();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'update_settings',
                child: Row(
                  children: [
                    const Icon(Icons.system_update_alt),
                    const SizedBox(width: 12),
                    const Text('Update Settings'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'toggle_theme',
                child: StreamBuilder<AppThemeMode>(
                  stream: _themeService.themeModeStream,
                  initialData: _themeService.currentThemeMode,
                  builder: (context, snapshot) {
                    return Row(
                      children: [
                        Icon(_themeService.themeModeIcon),
                        const SizedBox(width: 12),
                        Text(_themeService.themeModeDescription),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Connected Device Actions
          StreamBuilder<BleDeviceModel?>(
            stream: _controller.connectedDeviceStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: () => Navigator.of(context).push(
                        AnimationService.createPageTransition(
                          page: const CommandInterfaceView(),
                          type: PageTransitionType.slideFromBottom,
                        ),
                      ),
                      tooltip: 'Command Interface',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bluetooth_connected),
                      onPressed: () => _showConnectedDeviceInfo(snapshot.data!),
                      tooltip: 'Device Info',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Legacy update banner for old versions
          const LegacyUpdateBanner(),
          
          // Main content
          Expanded(
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(),
              tablet: _buildTabletLayout(),
              desktop: _buildDesktopLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundGradientStart(context),
            AppColors.backgroundGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StreamBuilder<bool>(
                  stream: _controller.scanningStream,
                  initialData: false,
                  builder: (context, snapshot) {
                    bool isScanning = snapshot.data ?? false;
                    return AnimatedScanButton(
                      isScanning: isScanning,
                      onPressed: isScanning 
                          ? _controller.stopScanning 
                          : _controller.startScanning,
                      text: 'Start Scanning',
                      scanningText: 'Stop Scanning',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  onPressed: _controller.clearDevices,
                  icon: Icon(Icons.clear_all, color: Colors.grey.shade700),
                  tooltip: 'Clear Devices',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BleDeviceModel>>(
            stream: _controller.devicesStream,
            initialData: const [],
            builder: (context, snapshot) {
              int deviceCount = snapshot.data?.length ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$deviceCount devices found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return StreamBuilder<bool>(
      stream: _controller.scanningStream,
      initialData: false,
      builder: (context, snapshot) {
        bool isScanning = snapshot.data ?? false;
        if (!isScanning) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.blue.shade50],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Scanning for BLE devices...',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceList() {
    return StreamBuilder<List<BleDeviceModel>>(
      stream: _controller.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        List<BleDeviceModel> devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.bluetooth_searching,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No BLE devices found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start scanning to discover nearby devices',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                StreamBuilder<bool>(
                  stream: _controller.scanningStream,
                  initialData: false,
                  builder: (context, snapshot) {
                    bool isScanning = snapshot.data ?? false;
                    if (isScanning) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Scanning...',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) => AnimatedListItem(
            index: index,
            child: _buildDeviceCard(devices[index]),
          ),
        );
      },
    );
  }

  Widget _buildDeviceCard(BleDeviceModel device) {
    return StreamBuilder<BleDeviceModel?>(
      stream: _controller.connectedDeviceStream,
      builder: (context, connectedSnapshot) {
        bool isConnected = connectedSnapshot.data?.id == device.id;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isConnected 
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.green.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isConnected 
                  ? BorderSide(color: Colors.green.shade300, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _showDeviceDetails(device),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Device Icon with Connection Animation
                        AnimatedConnectionStatus(
                          isConnected: isConnected,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isConnected 
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.green.shade800.withValues(alpha: 0.3)
                                      : Colors.green.shade100)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.blue.shade800.withValues(alpha: 0.3)
                                      : Colors.blue.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                              color: isConnected 
                                  ? AppColors.successColor(context)
                                  : AppColors.infoColor(context),
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Device Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isConnected ? FontWeight.bold : FontWeight.w600,
                                  color: isConnected 
                                      ? AppColors.successColor(context)
                                      : AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                device.id,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                  fontFamily: 'monospace',
                                ),
                              ),
                              if (isConnected && device.services.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Services: ${device.services.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.successColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // RSSI and Actions
                        Column(
                          children: [
                            _buildSignalStrengthIndicator(device),
                            const SizedBox(height: 8),
                            _buildDeviceActions(device, isConnected),
                          ],
                        ),
                      ],
                    ),
                    
                    if (isConnected) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, 
                                 color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (device.connectionDuration != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(device.connectionDuration!),
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignalStrengthIndicator(BleDeviceModel device) {
    return Column(
      children: [
        // RSSI Bars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            double threshold = (index + 1) * 0.25;
            bool isActive = device.signalStrength >= threshold;
            return Container(
              width: 3,
              height: 8 + (index * 2),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isActive 
                    ? _getSignalColor(device.signalStrength)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${device.rssi}dBm',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getSignalColor(double strength) {
    if (strength >= 0.8) return Colors.green;
    if (strength >= 0.6) return Colors.lightGreen;
    if (strength >= 0.4) return Colors.orange;
    if (strength >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _buildDeviceActions(BleDeviceModel device, bool isConnected) {
    if (isConnected) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(Icons.bluetooth_disabled, color: Colors.red.shade700),
          onPressed: _controller.disconnectDevice,
          tooltip: 'Disconnect',
          iconSize: 20,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(Icons.connect_without_contact, color: Colors.blue.shade700),
        onPressed: () => _controller.connectToDevice(device.id),
        tooltip: 'Connect',
        iconSize: 20,
      ),
    );
  }

  void _showDeviceDetails(BleDeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Device ID', device.id),
              _buildInfoRow('Name', device.name.isNotEmpty ? device.name : 'Unknown'),
              _buildInfoRow('RSSI', '${device.rssi} dBm (${device.rssiDescription})'),
              _buildInfoRow('Connection', device.connectionState.displayName),
              if (device.lastSeen != null)
                _buildInfoRow('Last Seen', _formatDateTime(device.lastSeen!)),
              if (device.connectedAt != null)
                _buildInfoRow('Connected At', _formatDateTime(device.connectedAt!)),
              if (device.connectionDuration != null)
                _buildInfoRow('Duration', _formatDuration(device.connectionDuration!)),
              _buildInfoRow('Services', '${device.services.length}'),
              if (device.services.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...device.services.map((service) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• ${service.displayName}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showConnectedDeviceInfo(BleDeviceModel device) {
    _showDeviceDetails(device);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  // Mobile Layout (Portrait and small screens)
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Control Panel
        _buildControlPanel(),
        
        // Scanning Indicator
        _buildScanningIndicator(),
        
        // Device List
        Expanded(child: _buildDeviceList()),
      ],
    );
  }

  // Tablet Layout (Medium screens)
  Widget _buildTabletLayout() {
    return ResponsiveUtils.isLandscape(context)
        ? _buildTabletLandscapeLayout()
        : _buildTabletPortraitLayout();
  }

  Widget _buildTabletPortraitLayout() {
    return ResponsiveContainer(
      child: Column(
        children: [
          // Control Panel
          _buildControlPanel(),
          
          // Scanning Indicator
          _buildScanningIndicator(),
          
          // Device List with responsive card width
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getCardMaxWidth(context) * 1.5,
                ),
                child: _buildDeviceList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLandscapeLayout() {
    return Row(
      children: [
        // Left Panel - Control and Connected Device Info
        Container(
          width: 320,
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              _buildControlPanel(),
              _buildScanningIndicator(),
              const SizedBox(height: 16),
              // Connected device quick info
              StreamBuilder<BleDeviceModel?>(
                stream: _controller.connectedDeviceStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildConnectedDeviceCard(snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        
        // Divider
        Container(
          width: 1,
          color: AppColors.borderColor(context),
        ),
        
        // Right Panel - Device List
        Expanded(
          child: _buildDeviceList(),
        ),
      ],
    );
  }

  // Desktop Layout (Large screens)
  Widget _buildDesktopLayout() {
    return ResponsiveContainer(
      child: Row(
        children: [
          // Left Sidebar
          Container(
            width: 380,
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              children: [
                _buildControlPanel(),
                _buildScanningIndicator(),
                const SizedBox(height: 20),
                
                // Connected device detailed info
                StreamBuilder<BleDeviceModel?>(
                  stream: _controller.connectedDeviceStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildConnectedDeviceCard(snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                // Quick stats
                const SizedBox(height: 16),
                _buildQuickStats(),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            color: AppColors.borderColor(context),
          ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Header with search functionality (future enhancement)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ResponsiveText(
                        'Available Devices',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                      const Spacer(),
                      // Future: Add search and filter buttons here
                    ],
                  ),
                ),
                
                // Device grid for desktop
                Expanded(
                  child: _buildResponsiveDeviceGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Connected device card for sidebar
  Widget _buildConnectedDeviceCard(BleDeviceModel device) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ResponsiveIcon(
                Icons.bluetooth_connected,
                size: 24,
                color: AppColors.successColor(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResponsiveText(
                  'Connected',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.successColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResponsiveText(
            device.displayName,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            'RSSI: ${device.rssi} dBm',
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
          if (device.services.isNotEmpty) ...[
            const SizedBox(height: 8),
            ResponsiveText(
              'Services: ${device.services.length}',
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CommandInterfaceView(),
                ),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Open Command Interface'),
            ),
          ),
        ],
      ),
    );
  }

  // Quick stats widget
  Widget _buildQuickStats() {
    return StreamBuilder<List<BleDeviceModel>>(
      stream: _controller.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        int deviceCount = snapshot.data?.length ?? 0;
        int connectedCount = snapshot.data?.where((d) => d.connectionState.isConnected).length ?? 0;
        
        return ResponsiveCard(
          child: Column(
            children: [
              ResponsiveText(
                'Quick Stats',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Found', deviceCount.toString(), Icons.devices),
                  _buildStatItem('Connected', connectedCount.toString(), Icons.link),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        ResponsiveIcon(
          icon,
          size: 24,
          color: AppColors.infoColor(context),
        ),
        const SizedBox(height: 8),
        ResponsiveText(
          value,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
        ),
        ResponsiveText(
          label,
          fontSize: 12,
          color: AppColors.textSecondary(context),
        ),
      ],
    );
  }

  // Responsive device grid for larger screens
  Widget _buildResponsiveDeviceGrid() {
    return StreamBuilder<List<BleDeviceModel>>(
      stream: _controller.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        List<BleDeviceModel> devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return _buildEmptyState();
        }

        final crossAxisCount = ResponsiveUtils.getGridColumns(context);
        
        return GridView.builder(
          padding: ResponsiveUtils.getResponsivePadding(context),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: devices.length,
          itemBuilder: (context, index) => _buildDeviceGridCard(devices[index]),
        );
      },
    );
  }

  // Compact device card for grid layout
  Widget _buildDeviceGridCard(BleDeviceModel device) {
    return StreamBuilder<BleDeviceModel?>(
      stream: _controller.connectedDeviceStream,
      builder: (context, connectedSnapshot) {
        bool isConnected = connectedSnapshot.data?.id == device.id;
        
        return ResponsiveCard(
          child: InkWell(
            onTap: () => _showDeviceDetails(device),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveIcon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  size: 32,
                  color: isConnected 
                      ? AppColors.successColor(context)
                      : AppColors.infoColor(context),
                ),
                const SizedBox(height: 12),
                ResponsiveText(
                  device.displayName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                ResponsiveText(
                  '${device.rssi} dBm',
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isConnected 
                        ? _controller.disconnectDevice
                        : () => _controller.connectToDevice(device.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected 
                          ? AppColors.errorColor(context)
                          : AppColors.infoColor(context),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isConnected ? 'Disconnect' : 'Connect'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundGradientStart(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ResponsiveIcon(
              Icons.bluetooth_searching,
              size: 64,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
          ResponsiveText(
            'No BLE devices found',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            'Start scanning to discover nearby devices',
            fontSize: 14,
            color: AppColors.textSecondary(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}