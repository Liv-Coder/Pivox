import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/app_theme.dart';
import '../di/service_locator.dart';

/// Theme manager for handling theme switching
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeManager()
    : _prefs = ServiceLocator.get<SharedPreferences>(),
      _themeMode = ThemeMode.system {
    _loadTheme();
  }

  /// Get the current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Get the current theme data
  ThemeData getTheme(BuildContext context) {
    final brightness =
        _themeMode == ThemeMode.system
            ? MediaQuery.of(context).platformBrightness
            : _themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;

    return brightness == Brightness.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _saveTheme();
    notifyListeners();
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    await setThemeMode(newMode);
  }

  /// Load the theme from shared preferences
  void _loadTheme() {
    final themeValue = _prefs.getInt(_themeKey);
    if (themeValue != null) {
      _themeMode = ThemeMode.values[themeValue];
    }
  }

  /// Save the theme to shared preferences
  Future<void> _saveTheme() async {
    await _prefs.setInt(_themeKey, _themeMode.index);
  }
}
