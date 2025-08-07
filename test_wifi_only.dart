// WiFi Only Setting Test Tool
// Run with: flutter run -t test_wifi_only.dart

import 'package:flutter/material.dart';
import 'lib/services/update_service.dart';
import 'lib/services/network_service.dart';
import 'lib/models/update_preferences.dart';
import 'lib/utils/logger.dart';

void main() {
  runApp(WifiOnlyTestApp());
}

class WifiOnlyTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Only Test',
      home: WifiOnlyTestScreen(),
    );
  }
}

class WifiOnlyTestScreen extends StatefulWidget {
  @override
  _WifiOnlyTestScreenState createState() => _WifiOnlyTestScreenState();
}

class _WifiOnlyTestScreenState extends State<WifiOnlyTestScreen> {
  final UpdateService _updateService = UpdateService();
  final NetworkService _networkService = NetworkService();
  
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _updateService.initialize();
    await _networkService.initialize();
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
    });

    try {
      final results = <String, dynamic>{};
      
      // Test 1: Check current preferences
      final preferences = _updateService.preferences;
      results['preferences_loaded'] = preferences != null;
      if (preferences != null) {
        results['wifi_only_setting'] = preferences.wifiOnlyDownload;
      }
      
      // Test 2: Check network status
      final networkStatus = _networkService.currentStatus;
      results['network_status'] = networkStatus.name;
      
      // Test 3: Test with WiFi only = true
      final wifiOnlyTrue = _networkService.isSuitableForDownload(wifiOnly: true);
      results['suitable_with_wifi_only_true'] = wifiOnlyTrue;
      
      // Test 4: Test with WiFi only = false
      final wifiOnlyFalse = _networkService.isSuitableForDownload(wifiOnly: false);
      results['suitable_with_wifi_only_false'] = wifiOnlyFalse;
      
      // Test 5: Test actual setting
      if (preferences != null) {
        final actualSetting = _networkService.isSuitableForDownload(
          wifiOnly: preferences.wifiOnlyDownload
        );
        results['suitable_with_actual_setting'] = actualSetting;
      }
      
      // Test 6: Toggle setting and test
      if (preferences != null) {
        // Create new preferences with opposite setting
        final toggledPrefs = preferences.copyWith(
          wifiOnlyDownload: !preferences.wifiOnlyDownload
        );
        await _updateService.updatePreferences(toggledPrefs);
        
        final afterToggle = _networkService.isSuitableForDownload(
          wifiOnly: toggledPrefs.wifiOnlyDownload
        );
        results['suitable_after_toggle'] = afterToggle;
        results['setting_after_toggle'] = toggledPrefs.wifiOnlyDownload;
        
        // Restore original setting
        await _updateService.updatePreferences(preferences);
      }
      
      setState(() {
        _testResults = results;
      });
    } catch (e) {
      Logger.error('Test failed', error: e);
      setState(() {
        _testResults = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleWifiOnly() async {
    final preferences = _updateService.preferences;
    if (preferences != null) {
      final newPrefs = preferences.copyWith(
        wifiOnlyDownload: !preferences.wifiOnlyDownload
      );
      await newPrefs.save();
      await _updateService.updatePreferences(newPrefs);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WiFi Only set to: ${newPrefs.wifiOnlyDownload}')
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WiFi Only Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runFullTest,
              child: _isLoading 
                  ? CircularProgressIndicator() 
                  : Text('Run Full Test'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleWifiOnly,
              child: Text('Toggle WiFi Only Setting'),
            ),
            SizedBox(height: 24),
            if (_testResults != null) ...[
              Text(
                'Test Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _formatResults(_testResults!),
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    results.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }
}