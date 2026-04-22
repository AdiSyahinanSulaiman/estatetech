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
  bool _isLoading = false;

  final List<String> _autoPhotos = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000',
    'https://images.unsplash.com/photo-1613977257363-707ba9348227?q=80&w=1000',
  ];

  Future<void> _submitData() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      String myUid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      String sName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] : "Landlord";
      String sPhoto = "https://ui-avatars.com/api/?name=$sName&background=random&color=fff";
      String randomHouse = _autoPhotos[Random().nextInt(_autoPhotos.length)];

      await FirebaseFirestore.instance.collection('properties').add({
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': randomHouse,
        'virtualTourUrl': 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg',
        'createdAt': Timestamp.now(),
        'sellerId': myUid,
        'sellerName': sName,
        'sellerPhoto': sPhoto,
      });

      if (mounted) {
        _titleController.clear(); _locationController.clear(); _priceController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted Successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Listing', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 55)),
              child: const Text('Post Listing', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}