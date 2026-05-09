import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/verify_email_screen.dart';

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
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'EstateTech',
      debugShowCheckedModeBanner: false,

      // --- THEME LOGIC ---
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorSchemeSeed: const Color(0xFF1B263B),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorSchemeSeed: const Color(0xFF1B263B),
      ),

      // --- SESSION LOGIC ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. If Firebase is still checking the session, show a loader
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 2. If the user is logged in
          if (snapshot.hasData) {
            User user = snapshot.data!;
            // CHECK: Is the email verified?
            if (user.emailVerified) {
              return const MainScreen(); // Verified -> Home
            } else {
              return const VerifyEmailScreen(); // Not Verified -> Verification Screen
            }
          }

          // 3. Not logged in -> Show Login Screen
          return const LoginScreen();
        },
      ),
    );
  }
}