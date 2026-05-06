import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import 'chat_detail_screen.dart';
import 'virtual_tour_screen.dart';
import 'package:intl/intl.dart';

class DetailsScreen extends StatefulWidget {
  final Property property;
  const DetailsScreen({super.key, required this.property});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  final Color navyBlue = const Color(0xFF1B263B);

  @override
  void initState() {
    super.initState();
    _trackAI();
  }

  void _trackAI() async {
    await FirebaseFirestore.instance.collection('users').doc(myId).collection('preferences').doc(widget.property.houseType).set({'views': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  void _startChat() async {
    List<String> ids = [myId, widget.property.sellerId];
    ids.sort();
    String chatId = ids.join("_");

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'users': [myId, widget.property.sellerId],
      'lastMessage': 'Interested in ${widget.property.houseType}',
      'landlordName': widget.property.sellerName,
      'landlordId': widget.property.sellerId,
      'tenantId': myId,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) =>
          ChatDetailScreen(sellerId: widget.property.sellerId, propertyId: widget.property.id)));
    }
  }

  void _bookViewing() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      await FirebaseFirestore.instance.collection('bookings').add({
        'tenantId': myId,
        'landlordId': widget.property.sellerId,
        'propertyId': widget.property.id,
        'propertyName': widget.property.houseType,
        'location': widget.property.location,
        'date': DateFormat('MMM dd, yyyy').format(pickedDate),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Viewing Booked!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Image.network(widget.property.imageUrl, height: 400, width: double.infinity, fit: BoxFit.cover),
            Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(
              backgroundColor: navyBlue,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VirtualTourScreen(imageUrl: widget.property.virtualTourUrl))),
              label: const Text("360° Tour", style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.view_in_ar, color: Colors.white),
            ))
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.property.houseType.toUpperCase(), style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(widget.property.houseType, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text(widget.property.location, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Text('\$${widget.property.monthlyPrice.toStringAsFixed(0)} / mo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navyBlue)),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _feat(Icons.king_bed_outlined, "${widget.property.rooms} Rooms"),
                _feat(Icons.bathtub_outlined, "${widget.property.baths} Baths"),
                _feat(Icons.square_foot, "${widget.property.sqft} Sqft"),
              ]),
              const SizedBox(height: 40),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: _startChat, style: ElevatedButton.styleFrom(backgroundColor: navyBlue, minimumSize: const Size(0, 55)), child: const Text("Message Landlord", style: TextStyle(color: Colors.white)))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: _bookViewing, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 55), side: BorderSide(color: navyBlue)), child: Text("Book Viewing", style: TextStyle(color: navyBlue)))),
              ]),
            ]),
          )
        ]),
      ),
    );
  }
  Widget _feat(IconData icon, String label) => Column(children: [Icon(icon, color: navyBlue), Text(label, style: const TextStyle(color: Colors.grey))]);
}