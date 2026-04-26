import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class AddPostScreen extends StatefulWidget {
  final VoidCallback onPostComplete;
  const AddPostScreen({super.key, required this.onPostComplete});
  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _loc = TextEditingController();
  final TextEditingController _monthP = TextEditingController();
  final TextEditingController _totalP = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _sqft = TextEditingController();

  String _type = 'Detached';
  bool _isLoading = false;
  int rooms = 0, baths = 0, wetK = 0, dryK = 0, livingR = 0;

  final List<String> _autoPhotos = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=1000',
  ];

  Future<void> _submit() async {
    // 1. Validation: Check if fields are empty
    if (_loc.text.isEmpty || _monthP.text.isEmpty || _totalP.text.isEmpty || _sqft.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all price and location fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      var user = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String name = user.data()?['name'] ?? "Landlord";

      // 2. Save to Firebase
      await FirebaseFirestore.instance.collection('properties').add({
        'houseType': _type,
        'location': _loc.text.trim(),
        'monthlyPrice': double.tryParse(_monthP.text) ?? 0.0,
        'totalPrice': double.tryParse(_totalP.text) ?? 0.0,
        'sqft': int.tryParse(_sqft.text) ?? 0,
        'description': _desc.text.trim(),
        'rooms': rooms,
        'baths': baths,
        'wetKitchen': wetK,
        'dryKitchen': dryK,
        'livingRoom': livingR,
        'sellerId': uid,
        'sellerName': name,
        'sellerPhoto': "https://ui-avatars.com/api/?name=$name&background=0D8ABC&color=fff",
        'imageUrl': _autoPhotos[Random().nextInt(_autoPhotos.length)],
        'virtualTourUrl': 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg',
        'createdAt': Timestamp.now(),
      });

      // 3. Success!
      widget.onPostComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Post New Listing", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        DropdownButtonFormField<String>(value: _type, items: ['Detached', 'Semi-Detached', 'Apartment', 'Terrace', 'Bungalow'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _type = v!), decoration: const InputDecoration(labelText: "Property Type", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _loc, decoration: const InputDecoration(labelText: "Location (City, Country)", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: TextField(controller: _monthP, decoration: const InputDecoration(labelText: "Monthly \$", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _sqft, decoration: const InputDecoration(labelText: "Sqft Area", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 15),
        TextField(controller: _totalP, decoration: const InputDecoration(labelText: "Full Property Price \$", border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 15),
        TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
        const SizedBox(height: 25),
        const Text("Property Features", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        _count("Rooms", rooms, (v) => setState(() => rooms = v)),
        _count("Baths", baths, (v) => setState(() => baths = v)),
        _count("Wet Kitchen", wetK, (v) => setState(() => wetK = v)),
        _count("Dry Kitchen", dryK, (v) => setState(() => dryK = v)),
        _count("Living Room", livingR, (v) => setState(() => livingR = v)),
        const SizedBox(height: 30),
        _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: const Color(0xFF1B263B)), child: const Text("Publish Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ])),
    );
  }

  Widget _count(String l, int v, Function(int) c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Row(children: [IconButton(onPressed: () => c(v > 0 ? v - 1 : 0), icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF1B263B))), Text("$v"), IconButton(onPressed: () => c(v + 1), icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B263B)))])]);
}