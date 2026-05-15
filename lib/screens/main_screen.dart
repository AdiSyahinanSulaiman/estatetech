import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_notification_service.dart';
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
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _startGlobalNotificationListener() {
    // 1. Message Listener
    FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: myId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          LocalNotificationService.showNotification(
            "New Message",
            data['text'] ?? "You have a new inquiry!",
          );
        }
      }
    });

    // 2. Booking Listener
    FirebaseFirestore.instance
        .collection('bookings')
        .where(userRole == 'Landlord' ? 'landlordId' : 'tenantId', isEqualTo: myId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        var data = change.doc.data() as Map<String, dynamic>;
        if (userRole == 'Landlord' && change.type == DocumentChangeType.added) {
          LocalNotificationService.showNotification("New Booking", "New viewing request received!");
        }
        if (userRole == 'Tenant' && change.type == DocumentChangeType.modified) {
          LocalNotificationService.showNotification("Booking Update", "Status: ${data['status']}");
        }
      }
    });
  }

  void _getUserRole() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(myId).get();
    if (mounted) {
      setState(() { userRole = doc.data()?['role'] ?? 'Tenant'; });
      _startGlobalNotificationListener();
    }
  }

  void _goToProfile() => setState(() => _selectedIndex = 4);
  void _handlePostStart() => setState(() { _selectedIndex = 0; _isUploadingListing = true; });
  void _handlePostComplete() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _isUploadingListing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == 'Loading') return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> _pages = [
      HomeScreen(isUploading: _isUploadingListing, onDPClick: _goToProfile),
      ExploreScreen(onDPClick: _goToProfile),
      userRole == 'Landlord'
          ? AddPostScreen(onPostStart: _handlePostStart, onPostComplete: _handlePostComplete)
          : CalculatorScreen(onDPClick: _goToProfile),
      MessagesScreen(onDPClick: _goToProfile),
      ProfileScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
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