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
    for (var doc in snap.docs) { temp[doc.id] = doc.data()['views'] ?? 0; }
    if (mounted) setState(() => _userPrefs = temp);
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
          List<Property> props = snapshot.data!.docs.map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
          props.sort((a, b) => (_userPrefs[b.houseType] ?? 0).compareTo(_userPrefs[a.houseType] ?? 0));

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: props.length,
            itemBuilder: (context, i) {
              final item = props[i];
              return Stack(children: [
                SizedBox.expand(child: Image.network(item.imageUrl, fit: BoxFit.cover)),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.8)]))),

                Positioned(top: 60, left: 20, child: Row(children: [
                  CircleAvatar(radius: 18, backgroundImage: NetworkImage(item.sellerPhoto)),
                  const SizedBox(width: 10),
                  Text(item.sellerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ])),

                Positioned(
                  bottom: 50, left: 20, right: 90,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)), child: const Text("Property Details", style: TextStyle(color: Colors.white))),
                  ]),
                ),

                Positioned(
                  bottom: 60, right: 20,
                  child: Column(children: [
                    StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(item.id).snapshots(),
                        builder: (context, saveSnap) {
                          bool isSaved = saveSnap.hasData && saveSnap.data!.exists;
                          return _side(isSaved ? Icons.bookmark : Icons.bookmark_border, "Save", () async {
                            var ref = FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(item.id);
                            isSaved ? await ref.delete() : await ref.set({'savedAt': Timestamp.now()});
                          }, isSaved ? Colors.amber : Colors.white);
                        }
                    ),
                    const SizedBox(height: 25),
                    _side(Icons.chat_bubble_outline, "Chat", () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: item.sellerId, propertyId: item.id))), Colors.white),
                    const SizedBox(height: 25),
                    _side(Icons.share_outlined, "Share", () => Share.share('Check out this ${item.houseType}!'), Colors.white),
                  ]),
                )
              ]);
            },
          );
        },
      ),
    );
  }
  Widget _side(IconData i, String l, VoidCallback t, Color c) => Column(children: [IconButton(onPressed: t, icon: Icon(i, color: c, size: 35)), Text(l, style: const TextStyle(color: Colors.white, fontSize: 12))]);
}