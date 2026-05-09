import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsProvider extends ChangeNotifier {
  // 1. DARK MODE STATE
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // This tells the whole app to rebuild with new colors
  }

  // 2. LANGUAGE STATE
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLanguage(String langCode) {
    _locale = Locale(langCode);
    notifyListeners(); // This triggers the language swap
  }

  // 3. NOTIFICATION LOGIC
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    if (value) {
      await FirebaseMessaging.instance.subscribeToTopic("all");
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic("all");
    }
    notifyListeners();
  }
}