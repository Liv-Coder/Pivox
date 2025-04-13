import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application theme
class ThemeManager extends ChangeNotifier {
  /// Current theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  /// Gets the current theme mode
  ThemeMode get themeMode => _themeMode;
  
  /// Initializes the theme manager
  Future<void> initialize() async {
    await _loadThemePreference();
  }
  
  /// Loads the theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'system';
    _themeMode = _themeStringToMode(themeString);
    notifyListeners();
  }
  
  /// Saves the theme preference to SharedPreferences
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
  }
  
  /// Converts a ThemeMode to a string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  /// Converts a string to a ThemeMode
  ThemeMode _themeStringToMode(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  /// Toggles the theme mode
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    _saveThemePreference(_themeMode);
    notifyListeners();
  }
}
