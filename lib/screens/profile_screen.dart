import 'package:flutter/material.dart';
import 'saved_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=1000&auto=format&fit=crop'),
          ),
          const SizedBox(height: 15),
          const Text('John Doe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Verified Landlord', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _ProfileOption(icon: Icons.home_work_outlined, label: 'My Listings', onTap: () {}),

                // Clicking this now opens our Saved Properties page!
                _ProfileOption(
                    icon: Icons.favorite_border,
                    label: 'Saved Properties',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SavedScreen()),
                      );
                    }
                ),

                _ProfileOption(icon: Icons.payment_outlined, label: 'Payments', onTap: () {}),
                _ProfileOption(icon: Icons.logout, label: 'Logout', color: Colors.red, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap; // Added this

  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap, // Added this
    );
  }
}