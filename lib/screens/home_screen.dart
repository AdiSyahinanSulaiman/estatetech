import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import 'details_screen.dart';
import 'chat_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String? myId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, int> _userPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadAIPreferences();
  }

  // AI LOGIC: Fetch how many times the user viewed each house type
  void _loadAIPreferences() async {
    if (myId == null) return;
    var prefs = await FirebaseFirestore.instance
        .collection('users')
        .doc(myId)
        .collection('preferences')
        .get();

    Map<String, int> tempPrefs = {};
    for (var doc in prefs.docs) {
      tempPrefs[doc.id] = doc.data()['views'] ?? 0;
    }

    if (mounted) {
      setState(() {
        _userPreferences = tempPrefs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''), // Removed "For You" as requested
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
            onPressed: () {
              _loadAIPreferences(); // Refresh AI ranking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI: Personalizing your feed based on your views...')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

          // 1. Convert Cloud data to List
          List<Property> properties = snapshot.data!.docs.map((doc) {
            return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          // 2. APPLY AI RANKING: Sort by user view counts
          properties.sort((a, b) {
            int viewsA = _userPreferences[a.houseType] ?? 0;
            int viewsB = _userPreferences[b.houseType] ?? 0;
            return viewsB.compareTo(viewsA); // Highest views at the top
          });

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final item = properties[index];
              return Stack(
                children: [
                  // Full Screen Image
                  SizedBox.expand(
                    child: Image.network(item.imageUrl, fit: BoxFit.cover),
                  ),
                  // Dark UI Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),

                  // TOP LEFT: Seller DP and Name
                  Positioned(
                    top: 60,
                    left: 20,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(item.sellerPhoto),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.sellerName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  // BOTTOM INFO
                  Positioned(
                    bottom: 50, left: 20, right: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the house type for clarity
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(5)),
                          child: Text(item.houseType, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),
                        Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        Text(item.location, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 15),
                        Text('\$${item.price} / mo', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(30)),
                            child: const Text('Property Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SIDEBAR ACTIONS
                  Positioned(
                    bottom: 60, right: 20,
                    child: Column(
                      children: [
                        _SidebarIcon(
                          icon: item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          label: 'Save',
                          isActive: item.isSaved,
                          activeColor: Colors.amber,
                          onTap: () {
                            setState(() => item.isSaved = !item.isSaved);
                            // Optional: You could also save this state to Firestore here
                          },
                        ),
                        const SizedBox(height: 25),
                        _SidebarIcon(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: item.sellerId))),
                        ),
                        const SizedBox(height: 25),
                        _SidebarIcon(icon: Icons.share_outlined, label: 'Share', onTap: () {}),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _SidebarIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, color: isActive ? activeColor : Colors.white, size: 35)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}