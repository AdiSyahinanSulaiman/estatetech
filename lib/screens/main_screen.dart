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
  bool _isUploadingListing = false;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (mounted) {
      setState(() {
        userRole = doc.data()?['role'] ?? 'Tenant';
      });
    }
  }

  // Navigation Helpers
  void _goToProfile() => setState(() => _selectedIndex = 4);
  void _handlePostStart() => setState(() => _isUploadingListing = true);
  void _handlePostComplete() {
    setState(() {
      _isUploadingListing = false;
      _selectedIndex = 0; // Go to Home after posting
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == 'Loading') {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1B263B))));
    }

    // REMOVED 'const' from this list to fix your red lines
    final List<Widget> _pages = [
      HomeScreen(isUploading: _isUploadingListing, onDPClick: _goToProfile),
      ExploreScreen(onDPClick: _goToProfile),
      userRole == 'Landlord'
          ? AddPostScreen(onPostStart: _handlePostStart, onPostComplete: _handlePostComplete)
          : CalculatorScreen(onDPClick: _goToProfile),
      MessagesScreen(onDPClick: _goToProfile),
      ProfileScreen(), // No 'const' here because it's dynamic
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B263B),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(userRole == 'Landlord' ? Icons.add_box_outlined : Icons.calculate_outlined),
            label: userRole == 'Landlord' ? 'Add' : 'Calculate',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}