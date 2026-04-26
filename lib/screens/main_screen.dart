import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'add_post_screen.dart';
import 'calculator_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String userRole = 'Loading';

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get();
    if (mounted) setState(() => userRole = doc.data()?['role'] ?? 'Tenant');
  }

  // Function to switch tabs programmatically
  void _jumpToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == 'Loading') return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> _pages = [
      const HomeScreen(),
      const ExploreScreen(),
      // We pass the jump function to the Add screen here
      userRole == 'Landlord'
          ? AddPostScreen(onPostComplete: _jumpToHome)
          : const CalculatorScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
              icon: Icon(userRole == 'Landlord' ? Icons.add_box : Icons.calculate),
              label: userRole == 'Landlord' ? 'Add' : 'Calculate'
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}