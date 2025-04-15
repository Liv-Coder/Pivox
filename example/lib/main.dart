import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app/app_layout.dart';
import 'core/design/app_theme.dart';
import 'core/services/service_locator.dart';
import 'core/services/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Apply system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Load Google Fonts
  await GoogleFonts.pendingFonts([GoogleFonts.inter()]);

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

    // Update system UI based on theme
    final isDark =
        _themeManager.themeMode == ThemeMode.dark ||
        (_themeManager.themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pivox',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeManager.themeMode,
      home: const AppLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}
