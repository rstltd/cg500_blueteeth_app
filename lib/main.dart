import 'dart:async';
import 'package:flutter/material.dart';
import 'views/simple_scanner_view.dart';
import 'services/theme_service.dart';
import 'controllers/app_update_manager.dart';
import 'core/interfaces/command_parameter_storage_interface.dart';
import 'core/service_locator.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the service locator (dependency injection)
  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final ThemeService _themeService;
  late final AppUpdateManager _updateManager;
  bool _isDarkMode = false;
  bool _isInitialized = false;

  // StreamSubscription management
  StreamSubscription<bool>? _themeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Get services from service locator
    _themeService = getIt<ThemeService>();
    _updateManager = getIt<AppUpdateManager>();

    _initializeApp();
  }

  /// Initialize all app services including update manager
  Future<void> _initializeApp() async {
    try {
      Logger.info('Initializing CG500 Bluetooth App...');
      
      // Initialize theme service
      _themeService.initialize();

      // Initialize command parameter storage service
      try {
        final commandStorageService = getIt<CommandParameterStorageInterface>();
        await commandStorageService.initialize();
        Logger.info('Command parameter storage initialized');
      } catch (e) {
        Logger.warning('Failed to initialize command parameter storage: $e');
      }

      // Listen to theme changes
      _themeSubscription = _themeService.isDarkModeStream.listen((isDark) {
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
    // Cancel stream subscription to prevent memory leaks
    _themeSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Note: _themeService and _updateManager are managed by service locator
    // and should not be manually disposed here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CG500 Bluetooth App',
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
              'Initializing CG500 Bluetooth App...',
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

