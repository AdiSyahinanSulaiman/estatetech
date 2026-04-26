import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import 'chat_detail_screen.dart';
import 'virtual_tour_screen.dart';

class DetailsScreen extends StatefulWidget {
  final Property property;
  const DetailsScreen({super.key, required this.property});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _teachAI(); // User looked at this type, update AI score
  }

  void _teachAI() async {
    await FirebaseFirestore.instance.collection('users').doc(myId).collection('preferences').doc(widget.property.houseType).set({
      'views': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(widget.property.id).snapshots(),
            builder: (context, snapshot) {
              bool isSaved = snapshot.hasData && snapshot.data!.exists;
              return IconButton(
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Colors.amber : Colors.white, size: 28),
                onPressed: () async {
                  var ref = FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').doc(widget.property.id);
                  isSaved ? await ref.delete() : await ref.set({'savedAt': Timestamp.now()});
                },
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Stack(children: [
            Image.network(widget.property.imageUrl, height: 400, width: double.infinity, fit: BoxFit.cover),
            Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VirtualTourScreen(imageUrl: widget.property.virtualTourUrl))),
              label: const Text("360° Tour"), icon: const Icon(Icons.view_in_ar),
            ))
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.property.houseType.toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(widget.property.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(widget.property.location, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Text('\$${widget.property.price}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: widget.property.sellerId))),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 55)),
                child: const Text("Message Landlord", style: TextStyle(color: Colors.white)),
              )
            ]),
          )
        ]),
      ),
    );
  }
}