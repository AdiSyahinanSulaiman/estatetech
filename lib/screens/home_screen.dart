import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

          final properties = snapshot.data!.docs.map((doc) {
            return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final item = properties[index];
              return Stack(
                children: [
                  SizedBox.expand(child: Image.network(item.imageUrl, fit: BoxFit.cover)),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.8)]))),

                  // NEW: User profile section at the top left (Replaces "For You")
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

                  Positioned(
                    bottom: 50, left: 20, right: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        Text(item.location, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 15),
                        Text('\$${item.price} / mo', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(30)), child: const Text('Property Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 60, right: 20,
                    child: Column(
                      children: [
                        _SidebarIcon(icon: item.isSaved ? Icons.bookmark : Icons.bookmark_border, label: 'Save', isActive: item.isSaved, activeColor: Colors.amber, onTap: () => setState(() => item.isSaved = !item.isSaved)),
                        const SizedBox(height: 25),
                        _SidebarIcon(icon: Icons.chat_bubble_outline, label: 'Chat', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: item.sellerId)))),
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
    return Column(children: [IconButton(onPressed: onTap, icon: Icon(icon, color: isActive ? activeColor : Colors.white, size: 35)), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]);
  }
}