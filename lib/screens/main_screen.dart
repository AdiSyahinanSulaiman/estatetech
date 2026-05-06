import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'add_post_screen.dart';
import 'calculator_screen.dart';
import 'messages_screen.dart'; // Ensure this matches your file name
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
      setState(() => userRole = doc.data()?['role'] ?? 'Tenant');
    }
  }

  void _goToProfile() => setState(() => _selectedIndex = 4);

  // Triggered the moment 'Publish' is clicked
  void _handlePostStart() {
    setState(() {
      _selectedIndex = 0; // Jump to Home Screen immediately
      _isUploadingListing = true; // Show the publishing bar
    });
  }

  // Triggered after Firebase upload finishes
  void _handlePostComplete() async {
    // Keep the loading bar visible for 3 seconds for the lecturer to see
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isUploadingListing = false; // Hide the publishing bar
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == 'Loading') {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B263B))),
      );
    }

    final List<Widget> _pages = [
      HomeScreen(isUploading: _isUploadingListing, onDPClick: _goToProfile),
      ExploreScreen(onDPClick: _goToProfile),
      userRole == 'Landlord'
          ? AddPostScreen(onPostStart: _handlePostStart, onPostComplete: _handlePostComplete)
          : CalculatorScreen(onDPClick: _goToProfile),
      MessagesScreen(onDPClick: _goToProfile), // FIXED: Corrected class name
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Prevent navigation while the upload bar is active
          if (_isUploadingListing) return;
          setState(() => _selectedIndex = index);
        },
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