#!/usr/bin/env python3
"""
創建一個簡化的更新指引頁面
"""

simple_update_dialog = '''
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';

/// 簡化的更新對話框，直接導向GitHub下載
class SimpleUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  const SimpleUpdateDialog({
    super.key,
    required this.updateInfo,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: Colors.blue),
          SizedBox(width: 8),
          Text('New Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version ${updateInfo.latestVersion} is now available.'),
          SizedBox(height: 16),
          Text('Current: ${updateInfo.currentVersion}'),
          Text('Latest: ${updateInfo.latestVersion}'),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📱 Download Instructions:', 
                     style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('1. Click "Download" to open GitHub'),
                Text('2. Download the APK file'),
                Text('3. Install the APK manually'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!updateInfo.isForced)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: Text('Later'),
          ),
        ElevatedButton(
          onPressed: () => _openDownloadPage(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('Download'),
        ),
      ],
    );
  }

  Future<void> _openDownloadPage() async {
    final url = 'https://github.com/rstltd/cg500_blueteeth_app/releases/latest';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open download URL: $e');
    }
  }
}
'''

print("簡化的更新對話框代碼已生成")
print("這個版本直接導向GitHub下載頁面，避免應用內下載問題")