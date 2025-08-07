import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smart update banner that only shows for truly outdated versions
/// This bypasses the complex update system and provides direct download
class LegacyUpdateBanner extends StatefulWidget {
  const LegacyUpdateBanner({super.key});

  @override
  State<LegacyUpdateBanner> createState() => _LegacyUpdateBannerState();
}

class _LegacyUpdateBannerState extends State<LegacyUpdateBanner> {
  bool _dismissed = false;
  bool _shouldShow = false;
  String _currentVersion = '2.0.0';
  String _targetVersion = '2.0.0';
  
  static const String _dismissedKey = 'legacy_banner_dismissed_2.0.0';
  static const String _targetVersionString = '2.0.0';
  
  @override
  void initState() {
    super.initState();
    _checkIfShouldShow();
  }
  
  Future<void> _checkIfShouldShow() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      
      _currentVersion = packageInfo.version;
      final wasDismissed = prefs.getBool(_dismissedKey) ?? false;
      
      // Only show if current version is older than target version
      final shouldShow = _compareVersions(_currentVersion, _targetVersionString) < 0 && !wasDismissed;
      
      if (mounted) {
        setState(() {
          _shouldShow = shouldShow;
          _targetVersion = _targetVersionString;
        });
      }
    } catch (e) {
      // If there's an error, don't show the banner
      if (mounted) {
        setState(() {
          _shouldShow = false;
        });
      }
    }
  }
  
  /// Compare version strings (returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2)
  int _compareVersions(String version1, String version2) {
    try {
      // Remove build numbers
      String v1Clean = version1.split('+')[0];
      String v2Clean = version2.split('+')[0];
      
      List<int> v1Parts = v1Clean.split('.').map(int.parse).toList();
      List<int> v2Parts = v2Clean.split('.').map(int.parse).toList();
      
      // Ensure both have 3 parts
      while (v1Parts.length < 3) {
        v1Parts.add(0);
      }
      while (v2Parts.length < 3) {
        v2Parts.add(0);
      }
      
      for (int i = 0; i < 3; i++) {
        if (v1Parts[i] < v2Parts[i]) return -1;
        if (v1Parts[i] > v2Parts[i]) return 1;
      }
      return 0;
    } catch (e) {
      return 0; // Treat as equal if error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !_shouldShow) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.system_update_alt,
            color: Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Version Available: $_targetVersion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  'Tap to download manually from GitHub',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openDownload,
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Download'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              setState(() => _dismissed = true);
              // Remember dismissal
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_dismissedKey, true);
            },
            icon: Icon(Icons.close, color: Colors.blue.shade700),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _openDownload() async {
    const url = 'https://github.com/rstltd/cg500_blueteeth_app/releases/latest';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show simple instruction
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Download the APK file and install manually'),
              backgroundColor: Colors.blue.shade600,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visit: $url'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}