import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';
import 'app_layout.dart';

/// Main application widget
class PivoxApp extends StatelessWidget {
  const PivoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, _) {
          return MaterialApp(
            title: 'Pivox Demo',
            debugShowCheckedModeBanner: false,
            theme: themeManager.getTheme(context),
            themeMode: themeManager.themeMode,
            home: const AppLayout(),
          );
        },
      ),
    );
  }
}
