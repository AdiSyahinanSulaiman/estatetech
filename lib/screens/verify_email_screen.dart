import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Check if already verified
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      sendVerificationEmail();

      // Check status every 3 seconds
      timer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) setState(() => canResendEmail = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future checkEmailVerified() async {
    // CRITICAL: You must reload the user to get the latest status from Firebase
    await FirebaseAuth.instance.currentUser?.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      if (mounted) {
        // SUCCESS: Move to the main app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email"), backgroundColor: const Color(0xFF1B263B), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Color(0xFF1B263B)),
            const SizedBox(height: 24),
            const Text(
              'A verification email has been sent. Please check your inbox.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF1B263B),
              ),
              icon: const Icon(Icons.email, color: Colors.white),
              label: const Text('Resend Email', style: TextStyle(color: Colors.white)),
              onPressed: canResendEmail ? sendVerificationEmail : null,
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Color(0xFF1B263B))),
            ),
          ],
        ),
      ),
    );
  }
}