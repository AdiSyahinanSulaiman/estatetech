import 'package:flutter/material.dart';

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
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.black)),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Header
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=1000&auto=format&fit=crop'),
          ),
          const SizedBox(height: 15),
          const Text(
            'John Doe',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Verified Landlord',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 25),
          // Stats Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(label: 'Listings', value: '12'),
              _ProfileStat(label: 'Followers', value: '1.2k'),
              _ProfileStat(label: 'Rating', value: '4.9'),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(),
          // Profile Options
          Expanded(
            child: ListView(
              children: [
                _ProfileOption(icon: Icons.home_work_outlined, label: 'My Listings'),
                _ProfileOption(icon: Icons.favorite_border, label: 'Saved Properties'),
                _ProfileOption(icon: Icons.payment_outlined, label: 'Payments'),
                _ProfileOption(icon: Icons.help_outline, label: 'Support'),
                const _ProfileOption(icon: Icons.logout, label: 'Logout', color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for Stats
class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

// Helper widget for Menu Options
class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ProfileOption({required this.icon, required this.label, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}