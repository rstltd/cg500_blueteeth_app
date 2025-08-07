import 'package:flutter/material.dart';
import 'views/simple_scanner_view.dart';
import 'services/theme_service.dart';
import 'controllers/app_update_manager.dart';
import 'utils/logger.dart';

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
  final AppUpdateManager _updateManager = AppUpdateManager();
  bool _isDarkMode = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _initializeApp();
  }

  /// Initialize all app services including update manager
  Future<void> _initializeApp() async {
    try {
      Logger.info('Initializing CG500 Bluetooth App...');
      
      // Initialize theme service
      _themeService.initialize();
      
      // Listen to theme changes
      _themeService.isDarkModeStream.listen((isDark) {
        if (mounted) {
          setState(() {
            _isDarkMode = isDark;
          });
        }
      });
      
      // Initialize update manager
      final updateInitSuccess = await _updateManager.initialize();
      if (updateInitSuccess) {
        Logger.info('Update manager initialized successfully');
        
        // Enable periodic update checks (every 6 hours)
        _updateManager.startPeriodicUpdateChecks();
      } else {
        Logger.warning('Failed to initialize update manager');
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
      Logger.info('App initialization completed');
    } catch (e) {
      Logger.error('Failed to initialize app', error: e);
      if (mounted) {
        setState(() {
          _isInitialized = true; // Show UI even if some services failed
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeService.dispose();
    _updateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CG500 Bluetooth App v2.0.18',
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _isInitialized 
        ? AppHomeWrapper(updateManager: _updateManager)
        : const AppLoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Loading screen shown during app initialization
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Initializing CG500 Bluetooth App v2.0.18...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading enhanced update system',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper that provides update manager context to the main app
class AppHomeWrapper extends StatefulWidget {
  final AppUpdateManager updateManager;
  
  const AppHomeWrapper({
    super.key,
    required this.updateManager,
  });

  @override
  State<AppHomeWrapper> createState() => _AppHomeWrapperState();
}

class _AppHomeWrapperState extends State<AppHomeWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Set context for update dialogs after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.updateManager.setContext(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Update the context whenever the widget rebuilds
    widget.updateManager.setContext(context);
    
    return const SimpleScannerView();
  }
}

