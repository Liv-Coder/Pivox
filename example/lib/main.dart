import 'package:flutter/material.dart';

import 'core/design/app_theme.dart';
import 'core/services/service_locator.dart';
import 'core/services/theme_manager.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize service locator
  await setupServiceLocator();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeManager = serviceLocator<ThemeManager>();
  
  @override
  void initState() {
    super.initState();
    
    // Listen for theme changes
    _themeManager.addListener(_themeListener);
  }
  
  @override
  void dispose() {
    _themeManager.removeListener(_themeListener);
    super.dispose();
  }
  
  void _themeListener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pivox Demo',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeManager.themeMode,
      home: const HomeScreen(title: 'Pivox - Free Proxy Rotator'),
      debugShowCheckedModeBanner: false,
    );
  }
}
