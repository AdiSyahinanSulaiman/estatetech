import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variables to hold error messages
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // Reset errors before checking again
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // 1. Validation Logic
    bool hasError = false;

    if (_emailController.text.isEmpty) {
      setState(() => _emailError = "Email is required");
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = "Please enter your password");
      hasError = true;
    }

    if (hasError) return; // Stop here if there are empty fields

    // 2. Firebase Logic
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login Failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EstateTech\nLogin',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 10),
                const Text('Enter your credentials to continue', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                // Email Field with Error Text
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    errorText: _emailError, // Shows error if email is empty
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field with Error Text
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: _passwordError, // Shows error if password is empty
                  ),
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text("Don't have an account? Register", style: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}