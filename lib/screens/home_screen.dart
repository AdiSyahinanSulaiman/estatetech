import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../models/property.dart';
import '../widgets/global_user_dp.dart';
import '../services/ai_engine.dart';
import 'details_screen.dart';
import 'chat_detail_screen.dart';
import 'view_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isUploading;
  final VoidCallback onDPClick;
  const HomeScreen({super.key, this.isUploading = false, required this.onDPClick});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  final AIEngine _ai = AIEngine();
  Map<String, dynamic>? _userVector;

  @override
  void initState() {
    super.initState();
    _loadAI();
  }

  Future<void> _loadAI() async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(myId).get();
      if (mounted && userDoc.exists) setState(() => _userVector = userDoc.data());
    } catch (e) { print("AI Load Error: $e"); }
  }

  void _toggleSave(String propertyId, bool isCurrentlySaved) async {
    var ref = FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(propertyId);
    isCurrentlySaved ? await ref.delete() : await ref.set({'savedAt': Timestamp.now()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text("EstateTech", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
          Padding(padding: const EdgeInsets.only(right: 15, left: 10), child: GlobalUserDP(radius: 16, onTap: widget.onDPClick)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAI,
        color: const Color(0xFF1B263B),
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('properties').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                List<Property> props = snapshot.data!.docs.map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                List<Property> sortedList = _ai.rankFeed(props, _userVector);

                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sortedList.length,
                  itemBuilder: (context, i) {
                    final item = sortedList[i];
                    return Stack(children: [
                      SizedBox.expand(child: Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.black))),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.8)]))),

                      Positioned(top: 120, left: 20, child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ViewProfileScreen(userId: item.sellerId))),
                        child: Row(children: [GlobalUserDP(radius: 18, userId: item.sellerId), const SizedBox(width: 10), Text(item.sellerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]),
                      )),

                      Positioned(bottom: 50, left: 20, right: 90, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.houseType.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        Text(item.location, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.king_bed_outlined, color: Colors.white70, size: 18),
                          Text(" ${item.rooms}bd  •  ", style: const TextStyle(color: Colors.white70)),
                          const Icon(Icons.square_foot, color: Colors.white70, size: 18),
                          Text(" ${item.sqft} sqft", style: const TextStyle(color: Colors.white70)),
                        ]),
                        const SizedBox(height: 15),
                        Text('Monthly: \$${item.monthlyPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Full Price: \$${(item.totalPrice / 1000).toStringAsFixed(0)}K', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300)),
                        // --- ADDED LISTING TYPE TAG ---
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF1B263B).withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                          child: Text("FOR ${item.listingType.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Property Details", style: TextStyle(color: Colors.white))),
                      ])),

                      Positioned(bottom: 60, right: 20, child: Column(children: [
                        StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(item.id).snapshots(),
                            builder: (context, saveSnap) {
                              bool isSaved = saveSnap.hasData && saveSnap.data!.exists;
                              return _side(isSaved ? Icons.bookmark : Icons.bookmark_border, "Save", () => _toggleSave(item.id, isSaved), isSaved ? Colors.amber : Colors.white);
                            }
                        ),
                        const SizedBox(height: 25),
                        _side(Icons.chat_bubble_outline, "Chat", () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: item.sellerId, propertyId: item.id))), Colors.white),
                        const SizedBox(height: 25),
                        _side(Icons.share_outlined, "Share", () => Share.share('Check out this ${item.houseType}!'), Colors.white),
                      ]))
                    ]);
                  },
                );
              },
            ),
            if (widget.isUploading) Positioned(top: 0, left: 0, right: 0, child: Container(color: Colors.black.withOpacity(0.8), padding: const EdgeInsets.only(top: 50, bottom: 10), child: const Column(children: [LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.blueAccent), SizedBox(height: 5), Text("Publishing listing...", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))])))
          ],
        ),
      ),
    );
  }
  Widget _side(IconData i, String l, VoidCallback t, Color c) => Column(children: [IconButton(onPressed: t, icon: Icon(i, color: c, size: 35)), Text(l, style: const TextStyle(color: Colors.white, fontSize: 12))]);
}