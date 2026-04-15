import 'package:flutter/material.dart';
import 'screens/main_screen.dart'; // This links the two files

void main() {
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
        // Using white as the seed for a minimalist Airbnb-style look
        colorSchemeSeed: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainScreen(),
    );
  }
}