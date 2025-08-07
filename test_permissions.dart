// Permission Diagnosis Test Tool
// Run with: flutter run -t test_permissions.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/services/update_service.dart';
import 'lib/utils/logger.dart';

void main() {
  runApp(PermissionTestApp());
}

class PermissionTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permission Diagnosis',
      home: PermissionTestScreen(),
    );
  }
}

class PermissionTestScreen extends StatefulWidget {
  @override
  _PermissionTestScreenState createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen> {
  final UpdateService _updateService = UpdateService();
  Map<String, dynamic>? _diagnosisResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateService.initialize();
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _isLoading = true;
      _diagnosisResult = null;
    });

    try {
      final result = await _updateService.diagnosePermissions();
      setState(() {
        _diagnosisResult = result;
      });
    } catch (e) {
      Logger.error('Diagnosis failed', error: e);
      setState(() {
        _diagnosisResult = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCanInstall() async {
    try {
      final canInstall = await _updateService.canInstallApks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Can install APKs: $canInstall')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _requestPermission() async {
    try {
      await _updateService.requestInstallPermission();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission request sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permission Diagnosis'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runDiagnosis,
              child: _isLoading 
                  ? CircularProgressIndicator() 
                  : Text('Run Full Diagnosis'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testCanInstall,
              child: Text('Test Can Install'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestPermission,
              child: Text('Request Permission'),
            ),
            SizedBox(height: 24),
            if (_diagnosisResult != null) ...[
              Text(
                'Diagnosis Result:',
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
                      _formatDiagnosis(_diagnosisResult!),
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

  String _formatDiagnosis(Map<String, dynamic> diagnosis) {
    final buffer = StringBuffer();
    diagnosis.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }
}