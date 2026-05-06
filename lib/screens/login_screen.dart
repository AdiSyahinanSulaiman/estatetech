import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Color navyBlue = const Color(0xFF1B263B);
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // 1. Authenticate the user
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      // 2. THE GATEKEEPER: Check if verified
      if (user != null) {
        if (user.emailVerified) {
          // YES: Go to Main App
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainScreen()));
          }
        } else {
          // NO: Send to Verification Screen
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const VerifyEmailScreen()));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Icon(Icons.apartment, size: 80, color: navyBlue),
              const SizedBox(height: 10),
              Text('EstateTech', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: navyBlue)),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 30),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(backgroundColor: navyBlue, minimumSize: const Size(double.infinity, 55)),
                child: const Text('Login', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterScreen())),
                child: Text('Don\'t have an account? Register', style: TextStyle(color: navyBlue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}