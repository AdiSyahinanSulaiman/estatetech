import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');
  bool _notificationsEnabled = true; // Added Notification state

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLanguage(String langCode) {
    _locale = Locale(langCode);
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings', 'edit_profile': 'Edit Profile', 'language': 'Language',
      'dark_mode': 'Dark Mode', 'logout': 'Log Out', 'account': 'ACCOUNT',
      'preferences': 'PREFERENCES', 'notifications': 'Notifications'
    },
    'ms': {
      'settings': 'Tetapan', 'edit_profile': 'Sunting Profil', 'language': 'Bahasa',
      'dark_mode': 'Mod Gelap', 'logout': 'Log Keluar', 'account': 'AKAUN',
      'preferences': 'PILIHAN', 'notifications': 'Pemberitahuan'
    }
  };

  String getText(String key) => _localizedValues[_locale.languageCode]?[key] ?? key;
}