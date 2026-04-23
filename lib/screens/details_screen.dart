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

  @override
  void initState() {
    super.initState();
    _trackView(); // AI starts learning as soon as the page opens
  }

  // AI LOGIC: Track that the user is interested in this house type
  void _trackView() async {
    String myId = FirebaseAuth.instance.currentUser!.uid;
    // We increment a counter for this specific house type in the user's profile
    await FirebaseFirestore.instance.collection('users').doc(myId).collection('preferences').doc(widget.property.houseType).set({
      'views': FieldValue.increment(1),
      'lastViewed': Timestamp.now(),
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
          IconButton(
            icon: Icon(widget.property.isSaved ? Icons.bookmark : Icons.bookmark_border, size: 28),
            onPressed: () => setState(() => widget.property.isSaved = !widget.property.isSaved),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(widget.property.imageUrl, height: 450, width: double.infinity, fit: BoxFit.cover),
                Positioned(
                  bottom: 30, right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VirtualTourScreen(imageUrl: widget.property.virtualTourUrl))),
                    backgroundColor: Colors.white.withOpacity(0.9),
                    icon: const Icon(Icons.view_in_ar, color: Colors.black),
                    label: const Text('360° Tour', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.property.houseType.toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.property.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                      Text('\$${widget.property.price}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                  Text(widget.property.location, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: widget.property.sellerId))),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Message Landlord', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}