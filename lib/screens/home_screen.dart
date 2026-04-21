import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import '../models/property.dart';
import 'details_screen.dart';
import 'chat_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''), // Removed "For You" text as requested
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // AI Sparkle Icon
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI: Refreshing recommendations...')),
              );
            },
          ),
        ],
      ),
      // StreamBuilder "listens" to the properties collection in the cloud
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .orderBy('createdAt', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading data", style: TextStyle(color: Colors.white)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));

          // Convert the Cloud data into our Property list
          final properties = snapshot.data!.docs.map((doc) {
            return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          if (properties.isEmpty) {
            return const Center(child: Text("No listings found", style: TextStyle(color: Colors.white)));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final item = properties[index];
              return Stack(
                children: [
                  // 1. Background Image
                  SizedBox.expand(
                    child: Image.network(item.imageUrl, fit: BoxFit.cover),
                  ),
                  // 2. Dark Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  // 3. Info (Bottom Left)
                  Positioned(
                    bottom: 50,
                    left: 20,
                    right: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
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
                  // 4. Interaction Sidebar
                  Positioned(
                    bottom: 60,
                    right: 20,
                    child: Column(
                      children: [
                        _SidebarIcon(
                          icon: item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          label: 'Save',
                          isActive: item.isSaved,
                          activeColor: Colors.amber,
                          onTap: () {
                            setState(() => item.isSaved = !item.isSaved);
                          },
                        ),
                        const SizedBox(height: 25),
                        _SidebarIcon(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatDetailScreen(sellerId: "Agent"))),
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

  const _SidebarIcon({required this.icon, required this.label, required this.onTap, this.isActive = false, this.activeColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, color: isActive ? activeColor : Colors.white, size: 35)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}