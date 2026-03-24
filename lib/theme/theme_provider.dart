

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  
  ThemeProvider() {
    _loadTheme();
  }

  
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return View.of(context).platformDispatcher.platformBrightness == Brightness.dark;
      
    }
    return _themeMode == ThemeMode.dark;
  }

  
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeMode.toString());
  }

  
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyThemeMode);

      if (saved != null) {
        _themeMode = ThemeMode.values.firstWhere(
              (e) => e.toString() == saved,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      debugPrint('Theme load error: $e');
      _themeMode = ThemeMode.system;
    }

    notifyListeners(); 
  }

  
  Future<void> resetToSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyThemeMode);
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}