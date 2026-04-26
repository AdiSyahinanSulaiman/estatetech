import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../models/property.dart';
import 'details_screen.dart';
import 'chat_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, int> _userPrefs = {};

  @override
  void initState() {
    super.initState();
    _loadAI();
  }

  void _loadAI() async {
    var snap = await FirebaseFirestore.instance.collection('users').doc(myId).collection('preferences').get();
    Map<String, int> temp = {};
    for (var doc in snap.docs) {
      temp[doc.id] = doc.data()['views'] ?? 0;
    }
    if (mounted) setState(() => _userPrefs = temp);
  }

  // Cloud Save Logic
  void _toggleSave(String propertyId, bool isCurrentlySaved) async {
    var ref = FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(propertyId);
    if (isCurrentlySaved) {
      await ref.delete();
    } else {
      await ref.set({'savedAt': Timestamp.now()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List<Property> props = snapshot.data!.docs.map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          props.sort((a, b) => (_userPrefs[b.houseType] ?? 0).compareTo(_userPrefs[a.houseType] ?? 0));

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: props.length,
            itemBuilder: (context, i) {
              final item = props[i];
              return Stack(
                children: [
                  SizedBox.expand(child: Image.network(item.imageUrl, fit: BoxFit.cover)),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.8)]))),

                  // Seller Identity
                  Positioned(top: 60, left: 20, child: Row(children: [
                    CircleAvatar(radius: 18, backgroundImage: NetworkImage(item.sellerPhoto)),
                    const SizedBox(width: 10),
                    Text(item.sellerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ])),

                  // Property Information
                  Positioned(
                    bottom: 50, left: 20, right: 90,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.houseType.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      Text(item.location, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 15),
                      Text('Monthly: \$${item.monthlyPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Full Price: \$${(item.totalPrice / 1000).toStringAsFixed(0)}K', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                        child: const Text("Property Details", style: TextStyle(color: Colors.white)),
                      )
                    ]),
                  ),

                  // Sidebar Actions
                  Positioned(
                    bottom: 60, right: 20,
                    child: Column(children: [
                      // SAVE BUTTON: Listens to the Cloud for the "Yellow" state
                      StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(item.id).snapshots(),
                          builder: (context, saveSnap) {
                            bool isSaved = saveSnap.hasData && saveSnap.data!.exists;
                            return _SideBtn(
                                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                                label: "Save",
                                color: isSaved ? Colors.amber : Colors.white,
                                onTap: () => _toggleSave(item.id, isSaved)
                            );
                          }
                      ),
                      const SizedBox(height: 25),
                      _SideBtn(icon: Icons.chat_bubble_outline, label: "Chat", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: item.sellerId)))),
                      const SizedBox(height: 25),
                      _SideBtn(icon: Icons.share_outlined, label: "Share", onTap: () => Share.share('Check out this ${item.houseType} in ${item.location}!')),
                    ]),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color color;
  const _SideBtn({required this.icon, required this.label, required this.onTap, this.color = Colors.white});
  @override
  Widget build(BuildContext context) {
    return Column(children: [IconButton(onPressed: onTap, icon: Icon(icon, color: color, size: 35)), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]);
  }
}