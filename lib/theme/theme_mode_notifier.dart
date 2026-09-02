import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends ChangeNotifier {
  ThemeModeNotifier(this._prefs) {
    final stored = _prefs.getString(_prefsKey);
    if (stored == 'dark') {
      _mode = ThemeMode.dark;
    } else if (stored == 'light') {
      _mode = ThemeMode.light;
    }
  }

  static const _prefsKey = 'food_connect_theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setString(
      _prefsKey,
      _mode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }
}
