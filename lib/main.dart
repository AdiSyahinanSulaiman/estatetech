import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this
import 'firebase_options.dart'; // This connects to the secret ID file you generated
import 'screens/login_screen.dart';

void main() async {
  // 1. Ensure Flutter is fully loaded
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Start the Firebase Engine
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EstateTechApp());
}

class EstateTechApp extends StatelessWidget {
  const EstateTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EstateTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
    );
  }
}