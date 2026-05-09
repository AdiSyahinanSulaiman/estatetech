import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_provider.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final Color navyBlue = const Color(0xFF1B263B);
  final Color estateRed = const Color(0xFFE63946);

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
    final user = FirebaseAuth.instance.currentUser;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String name = userData['name'] ?? "User";
          String email = user?.email ?? "";
          String photo = userData['photoUrl'] ?? "";

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PROFILE HEADER
                ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userData: userData))),
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.blue, Colors.orange])),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : NetworkImage("https://ui-avatars.com/api/?name=$name") as ImageProvider,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),

                _buildSectionHeader("ACCOUNT"),
                _buildSettingTile(Icons.person_outline, "Edit Profile", () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userData: userData)))),

                // NOTIFICATIONS TOGGLE
                _buildSettingTile(Icons.notifications_none, "Notifications", () {},
                    trailing: Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (v) => settings.toggleNotifications(v),
                      activeColor: navyBlue,
                    )),

                _buildSectionHeader("PREFERENCES"),

                // LANGUAGE SELECTOR
                _buildSettingTile(Icons.language, "Language", () => _showLanguageDialog(context, settings),
                    subtitle: settings.locale.languageCode == 'en' ? "English" : "Malay (Brunei)"),

                // DARK MODE TOGGLE
                _buildSettingTile(Icons.dark_mode_outlined, "Dark Mode", () {},
                    trailing: Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (v) => settings.toggleTheme(v),
                      activeColor: navyBlue,
                    )),

                _buildSectionHeader("SUPPORT"),
                _buildSettingTile(Icons.help_outline, "Help Center", () => launchUrl(Uri.parse("https://google.com"))),
                _buildSettingTile(Icons.description_outlined, "Terms of Service", () => launchUrl(Uri.parse("https://google.com"))),

                const SizedBox(height: 50),

                // LOG OUT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton(
                    onPressed: () => _handleLogout(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: estateRed),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text("Log Out", style: TextStyle(color: estateRed, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select Language"),
        children: [
          SimpleDialogOption(onPressed: () { settings.setLanguage('en'); Navigator.pop(context); }, child: const Text("English")),
          SimpleDialogOption(onPressed: () { settings.setLanguage('ms'); Navigator.pop(context); }, child: const Text("Malay (Brunei)")),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.grey[50],
      child: Text(title, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap, {String? subtitle, Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: navyBlue),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }
}