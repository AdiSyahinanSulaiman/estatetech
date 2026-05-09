import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/settings_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const EstateTechApp(),
    ),
  );
}

class EstateTechApp extends StatelessWidget {
  const EstateTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the settings provider
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'EstateTech',
      debugShowCheckedModeBanner: false,

      // --- DYNAMIC THEME LOGIC ---
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF1B263B),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF1B263B),
        scaffoldBackgroundColor: Colors.black,
      ),

      // --- DYNAMIC LANGUAGE LOGIC ---
      locale: settings.locale,

      home: const LoginScreen(),
    );
  }
}