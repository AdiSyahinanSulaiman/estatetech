import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text("Account Security", style: TextStyle(fontWeight: FontWeight.w500)),
            leading: Icon(Icons.security),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
          ),
          const ListTile(
            title: Text("Notifications", style: TextStyle(fontWeight: FontWeight.w500)),
            leading: Icon(Icons.notifications_none),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
          ),
          const Divider(),
          ListTile(
            title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}