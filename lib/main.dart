import 'package:flutter/material.dart';
import 'views/simple_scanner_view.dart';
import 'services/theme_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ThemeService _themeService = ThemeService();
  final UpdateService _updateService = UpdateService();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize services
    _themeService.initialize();
    _updateService.initialize().then((_) {
      // Check for updates after initialization
      _checkForUpdates();
    });
    
    // Listen to theme changes
    _themeService.isDarkModeStream.listen((isDark) {
      if (mounted) {
        setState(() {
          _isDarkMode = isDark;
        });
      }
    });
    
    // Listen to update notifications
    _updateService.updateStream.listen((updateInfo) {
      if (mounted) {
        _showUpdateDialog(updateInfo);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.dispose();
    _updateService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check for updates when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates(showNotification: false);
    }
  }

  /// Check for app updates
  Future<void> _checkForUpdates({bool showNotification = true}) async {
    try {
      await _updateService.checkForUpdates(showNotification: showNotification);
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  /// Show update dialog to user
  void _showUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForced,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onDismiss: () {
          // User dismissed the update dialog
          debugPrint('Update dismissed by user');
        },
        onUpdateComplete: () {
          // Update completed, app will restart
          debugPrint('Update completed');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CG500 Bluetooth App',
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SimpleScannerView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

