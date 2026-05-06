import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EstateTechApp());
}

class EstateTechApp extends StatelessWidget {
  const EstateTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // This Auth Wrapper determines which screen to show on startup
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // User is logged in, but are they verified?
            if (snapshot.data!.emailVerified) {
              return const MainScreen();
            } else {
              return const VerifyEmailScreen();
            }
          }
          // Not logged in
          return const LoginScreen();
        },
      ),
    );
  }
}