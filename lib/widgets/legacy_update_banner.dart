import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple update banner for legacy users
/// This bypasses the complex update system and provides direct download
class LegacyUpdateBanner extends StatefulWidget {
  const LegacyUpdateBanner({super.key});

  @override
  State<LegacyUpdateBanner> createState() => _LegacyUpdateBannerState();
}

class _LegacyUpdateBannerState extends State<LegacyUpdateBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

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
                  'New Version Available: 2.0.0',
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
            onPressed: () => setState(() => _dismissed = true),
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