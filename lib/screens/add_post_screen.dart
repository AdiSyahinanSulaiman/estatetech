import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});
  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedType = 'Apartment';

  final List<String> _houseTypes = ['Detached', 'Semi-Detached', 'Apartment', 'Terrace', 'Bungalow', 'Other'];

  Future<void> _submitData() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) return;

    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    final name = userDoc.data()?['name'] ?? "Landlord";

    await FirebaseFirestore.instance.collection('properties').add({
      'title': _titleController.text.trim(),
      'location': _locationController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'houseType': _selectedType, // SAVED FOR AI
      'sellerId': myUid,
      'sellerName': name,
      'sellerPhoto': "https://ui-avatars.com/api/?name=$name&background=0D8ABC&color=fff",
      'imageUrl': 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
      'virtualTourUrl': 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg',
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context); // Go back after posting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post New Listing")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _houseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: const InputDecoration(labelText: "Property Type", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "House Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Monthly Price", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _submitData, child: const Text("Publish Listing")),
          ],
        ),
      ),
    );
  }
}