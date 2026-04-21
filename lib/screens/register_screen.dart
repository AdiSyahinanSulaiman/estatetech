import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers to grab the text from the boxes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // The function that talks to the Cloud
  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Tell Firebase to create the user
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Success! Show a message and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created! Please Login.')),
        );
        Navigator.pop(context); // Go back to login screen
      }
    } on FirebaseAuthException catch (e) {
      // 3. If it fails (e.g. email already exists), show the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration Failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Register', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}