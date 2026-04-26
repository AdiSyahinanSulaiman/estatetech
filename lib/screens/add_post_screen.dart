import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class AddPostScreen extends StatefulWidget {
  final VoidCallback onPostComplete; // Function to switch tabs
  const AddPostScreen({super.key, required this.onPostComplete});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _loc = TextEditingController();
  final TextEditingController _monthP = TextEditingController();
  final TextEditingController _totalP = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _imgUrl = TextEditingController();
  final TextEditingController _tourUrl = TextEditingController();

  String _type = 'Detached';
  bool _isLoading = false;
  int rooms = 0, baths = 0, wetK = 0, dryK = 0, livingR = 0;

  final List<String> _autoPhotos = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=1000',
  ];

  Future<void> _submit() async {
    if (_loc.text.isEmpty || _monthP.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      var user = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String name = user.data()?['name'] ?? "Landlord";

      // If empty, use automatic photo
      String finalImg = _imgUrl.text.isNotEmpty ? _imgUrl.text.trim() : _autoPhotos[Random().nextInt(_autoPhotos.length)];
      // If empty, use default 360 tour
      String finalTour = _tourUrl.text.isNotEmpty ? _tourUrl.text.trim() : 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg';

      await FirebaseFirestore.instance.collection('properties').add({
        'houseType': _type,
        'location': _loc.text.trim(),
        'monthlyPrice': double.parse(_monthP.text),
        'totalPrice': double.parse(_totalP.text),
        'description': _desc.text.trim(),
        'imageUrl': finalImg,
        'virtualTourUrl': finalTour,
        'rooms': rooms, 'baths': baths, 'wetKitchen': wetK, 'dryKitchen': dryK, 'livingRoom': livingR,
        'sellerId': uid, 'sellerName': name,
        'sellerPhoto': "https://ui-avatars.com/api/?name=$name&background=0D8ABC&color=fff",
        'createdAt': Timestamp.now(),
      });

      // Clear the form
      _loc.clear(); _monthP.clear(); _totalP.clear(); _desc.clear(); _imgUrl.clear(); _tourUrl.clear();

      // Go back to Home tab instead of closing the app
      widget.onPostComplete();

    } catch (e) { print(e); }
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post New Listing"), elevation: 0),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        DropdownButtonFormField<String>(value: _type, items: ['Detached', 'Semi-Detached', 'Apartment', 'Terrace', 'Bungalow'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _type = v!), decoration: const InputDecoration(labelText: "Property Type", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _loc, decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: TextField(controller: _monthP, decoration: const InputDecoration(labelText: "Monthly \$", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _totalP, decoration: const InputDecoration(labelText: "Total \$", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 15),
        TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: "Short Description", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _imgUrl, decoration: const InputDecoration(labelText: "Custom Photo URL (Optional)", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _tourUrl, decoration: const InputDecoration(labelText: "Custom 360 Tour URL (Optional)", border: OutlineInputBorder())),
        const SizedBox(height: 25),
        const Text("Features", style: TextStyle(fontWeight: FontWeight.bold)),
        _count("Rooms", rooms, (v) => setState(() => rooms = v)),
        _count("Baths", baths, (v) => setState(() => baths = v)),
        _count("Wet Kitchen", wetK, (v) => setState(() => wetK = v)),
        _count("Dry Kitchen", dryK, (v) => setState(() => dryK = v)),
        _count("Living Room", livingR, (v) => setState(() => livingR = v)),
        const SizedBox(height: 30),
        _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.black), child: const Text("Publish Listing", style: TextStyle(color: Colors.white))),
      ])),
    );
  }

  Widget _count(String l, int v, Function(int) c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Row(children: [IconButton(onPressed: () => c(v > 0 ? v - 1 : 0), icon: const Icon(Icons.remove_circle_outline)), Text("$v"), IconButton(onPressed: () => c(v + 1), icon: const Icon(Icons.add_circle_outline))])]);
}