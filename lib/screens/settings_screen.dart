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
    final bool isDark = settings.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : navyBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          settings.getText('settings'),
          style: TextStyle(color: isDark ? Colors.white : navyBlue, fontWeight: FontWeight.bold),
        ),
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
                // --- 1. PROFILE HEADER ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Colors.blue, Colors.purple, Colors.orange]),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : NetworkImage("https://ui-avatars.com/api/?name=$name&background=random") as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            Text(email, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader(context, settings.getText('account')),

                _buildSettingTile(
                  context,
                  Icons.person_outline,
                  settings.getText('edit_profile'),
                      () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userData: userData))),
                ),

                // NOTIFICATIONS TOGGLE
                ListTile(
                  leading: _iconBox(context, Icons.notifications_none),
                  title: Text(settings.getText('notifications'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (v) => settings.toggleNotifications(v),
                    activeColor: navyBlue,
                  ),
                ),

                _buildSectionHeader(context, settings.getText('preferences')),

                // LANGUAGE SELECTOR
                _buildSettingTile(
                  context,
                  Icons.language,
                  settings.getText('language'),
                      () => _showLanguageDialog(context, settings),
                  subtitle: settings.locale.languageCode == 'en' ? "English" : "Malay",
                ),

                // DARK MODE TOGGLE
                ListTile(
                  leading: _iconBox(context, Icons.dark_mode_outlined),
                  title: Text(settings.getText('dark_mode'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (v) => settings.toggleTheme(v),
                    activeColor: navyBlue,
                  ),
                ),

                // --- NEW: RESET AI BUDGET TILE ---
                _buildSettingTile(
                  context,
                  Icons.restart_alt,
                  "Reset Budget Filter",
                      () async {
                    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                      'budgetModeActive': false,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("AI feed reset to general browsing."))
                      );
                    }
                  },
                  subtitle: "Disable the rent budget priority",
                ),

                _buildSectionHeader(context, settings.getText('support')),
                _buildSettingTile(context, Icons.help_outline, "Help Center", () => launchUrl(Uri.parse("https://google.com"))),
                _buildSettingTile(context, Icons.description_outlined, "Terms of Service", () => launchUrl(Uri.parse("https://google.com"))),

                const SizedBox(height: 30),
                const Center(
                  child: Text("EstateTech Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),

                // LOG OUT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: OutlinedButton(
                    onPressed: () => _handleLogout(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: estateRed, width: 1.5),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: estateRed),
                        const SizedBox(width: 10),
                        Text(settings.getText('logout'),
                            style: TextStyle(color: estateRed, fontWeight: FontWeight.bold)),
                      ],
                    ),
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

  Widget _iconBox(BuildContext context, IconData icon) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(10)
      ),
      child: Icon(icon, color: isDark ? Colors.white70 : navyBlue, size: 22),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select Language"),
        children: [
          ListTile(
              title: const Text("English"),
              onTap: () { settings.setLanguage('en'); Navigator.pop(context); }
          ),
          ListTile(
              title: const Text("Malay"),
              onTap: () { settings.setLanguage('ms'); Navigator.pop(context); }
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {String? subtitle}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: _iconBox(context, icon),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}