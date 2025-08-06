import 'package:flutter/material.dart';
import 'views/simple_scanner_view.dart';
import 'services/theme_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _themeService.initialize();
    _themeService.isDarkModeStream.listen((isDark) {
      if (mounted) {
        setState(() {
          _isDarkMode = isDark;
        });
      }
    });
  }

  @override
  void dispose() {
    _themeService.dispose();
    super.dispose();
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

