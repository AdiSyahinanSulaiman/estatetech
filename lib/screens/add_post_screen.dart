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
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _tourController = TextEditingController();

  bool _isLoading = false;

  final List<String> _autoPhotos = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=1000',
  ];

  Future<void> _submitData() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Price are required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String myUid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Get user name from Firestore
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      String sName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] : "Landlord";

      // 2. FIXED: This line ensures the DP is always the same professional Blue
      String sPhoto = "https://ui-avatars.com/api/?name=$sName&background=0D8ABC&color=fff";

      // 3. Image Logic
      String finalImage = _imageController.text.isNotEmpty
          ? _imageController.text.trim()
          : _autoPhotos[Random().nextInt(_autoPhotos.length)];

      String finalTour = _tourController.text.isNotEmpty
          ? _tourController.text.trim()
          : 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg';

      // 4. Save everything to the Cloud
      await FirebaseFirestore.instance.collection('properties').add({
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': finalImage,
        'virtualTourUrl': finalTour,
        'createdAt': Timestamp.now(),
        'sellerId': myUid,
        'sellerName': sName,
        'sellerPhoto': sPhoto, // Saves the permanent blue photo link
      });

      if (mounted) {
        _titleController.clear(); _locationController.clear(); _priceController.clear();
        _imageController.clear(); _tourController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing Published!')));
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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Post New Listing', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'House Name or Type', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location Name', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per Month', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            TextField(controller: _imageController, decoration: const InputDecoration(labelText: 'Cover Photo URL (Optional)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _tourController, decoration: const InputDecoration(labelText: '360 Tour URL (Optional)', border: OutlineInputBorder())),
            const SizedBox(height: 30),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 55)),
              child: const Text('Publish Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}