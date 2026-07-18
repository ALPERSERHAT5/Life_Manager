import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePrefKey = 'is_dark_mode';

/// Uygulama genelinde tema modunu yönetir (varsayılan: Dark Mode).
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(true) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_themePrefKey) ?? true;
  }

  Future<void> toggleTheme() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, state);
  }

  Future<void> setDark(bool isDark) async {
    state = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>(
  (ref) => ThemeModeNotifier(),
);
