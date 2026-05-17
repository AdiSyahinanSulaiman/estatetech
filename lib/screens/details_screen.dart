import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/property.dart';
import 'chat_detail_screen.dart';
import 'virtual_tour_screen.dart';
import 'view_profile_screen.dart'; // Added this one import
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
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _trackAI();
  }

  void _trackAI() async {
    await FirebaseFirestore.instance.collection('users').doc(myId).collection('preferences').doc(widget.property.houseType).set({'views': FieldValue.increment(1)}, SetOptions(merge: true));
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(myId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snap = await transaction.get(userRef);
      if (!snap.exists) return;
      Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
      double oldP = (data['avgPrice'] ?? widget.property.monthlyPrice).toDouble();
      double oldR = (data['avgRooms'] ?? widget.property.rooms).toDouble();
      double oldS = (data['avgSqft'] ?? widget.property.sqft).toDouble();
      int count = data['interactionCount'] ?? 0;
      transaction.update(userRef, {
        'avgPrice': (oldP * count + widget.property.monthlyPrice) / (count + 1),
        'avgRooms': (oldR * count + widget.property.rooms) / (count + 1),
        'avgSqft': (oldS * count + widget.property.sqft) / (count + 1),
        'interactionCount': count + 1,
      });
    });
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
      'propertyId': widget.property.id,
      'lastSenderId': myId,
      'isRead': false,
    }, SetOptions(merge: true));
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) =>
          ChatDetailScreen(sellerId: widget.property.sellerId, propertyId: widget.property.id)));
    }
  }

  void _bookViewing() async {
    DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (pickedDate == null) return;
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (pickedTime != null) {
      String formattedDate = DateFormat('MMM dd, yyyy').format(pickedDate);
      String formattedTime = pickedTime.format(context);
      await FirebaseFirestore.instance.collection('bookings').add({
        'tenantId': myId, 'tenantName': FirebaseAuth.instance.currentUser?.displayName ?? "Tenant",
        'landlordId': widget.property.sellerId, 'propertyId': widget.property.id, 'propertyName': widget.property.houseType,
        'location': widget.property.location, 'date': formattedDate, 'time': formattedTime, 'status': 'Pending', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request sent for $formattedDate at $formattedTime!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<String> images = widget.property.galleryUrls.isNotEmpty ? widget.property.galleryUrls : [widget.property.imageUrl];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black)),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // --- IMAGE SLIDER ---
          Stack(children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _activeImageIndex = i),
                itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover),
              ),
            ),
            // Slider Indicator
            Positioned(bottom: 25, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: _activeImageIndex == i ? Colors.white : Colors.white30))))),
            Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(backgroundColor: navyBlue, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VirtualTourScreen(imageUrl: widget.property.virtualTourUrl))), label: const Text("360° Tour", style: TextStyle(color: Colors.white)), icon: const Icon(Icons.view_in_ar, color: Colors.white)))
          ]),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.property.houseType.toUpperCase(), style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 5),
              Text(widget.property.houseType, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text(widget.property.location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 25),
              Text('\$${widget.property.monthlyPrice.toStringAsFixed(0)} / mo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 30),

              // 6-icon grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_feat(Icons.king_bed_outlined, "${widget.property.rooms} Rooms"), _feat(Icons.bathtub_outlined, "${widget.property.baths} Baths"), _feat(Icons.square_foot, "${widget.property.sqft} Sqft")]),
                  const SizedBox(height: 25),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_feat(Icons.chair_outlined, "${widget.property.livingRoom} Living"), _feat(Icons.countertops_outlined, "${widget.property.wetKitchen} Wet Kit"), _feat(Icons.kitchen_outlined, "${widget.property.dryKitchen} Dry Kit")]),
                ]),
              ),

              const SizedBox(height: 30),

              // --- ADDED: CLICKABLE SELLER SECTION (Stalking) ---
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ViewProfileScreen(userId: widget.property.sellerId))),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(widget.property.sellerPhoto.isNotEmpty ? widget.property.sellerPhoto : "https://ui-avatars.com/api/?name=${widget.property.sellerName}"),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.property.sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text("View Landlord Profile", style: TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 10),
              Text(widget.property.description.isNotEmpty ? widget.property.description : "No description provided.", style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),

              const SizedBox(height: 30),
              // --- GOOGLE MAP CARD ---
              Text("Location on Map", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 15),
              Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.2))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(widget.property.latitude, widget.property.longitude), zoom: 15),
                    markers: { Marker(markerId: const MarkerId("loc"), position: LatLng(widget.property.latitude, widget.property.longitude)) },
                    liteModeEnabled: true,
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: _startChat, style: ElevatedButton.styleFrom(backgroundColor: navyBlue, minimumSize: const Size(0, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Message Landlord", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: _bookViewing, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 55), side: BorderSide(color: navyBlue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Book Viewing", style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)))),
              ]),
              const SizedBox(height: 40),
            ]),
          )
        ]),
      ),
    );
  }
  Widget _feat(IconData icon, String label) => Column(children: [Icon(icon, color: Colors.grey, size: 24), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))]);
}