import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Required for random picking
import 'package:firebase_auth/firebase_auth.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController(); // New field

  bool _isLoading = false;

  // A list of high-end house photos for automatic selection
  final List<String> _autoPhotos = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000',
    'https://images.unsplash.com/photo-1613977257363-707ba9348227?q=80&w=1000',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=1000',
    'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?q=80&w=1000',
  ];

  Future<void> _submitData() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Price are required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Logic: Use user's link, or pick a random one if empty
      String finalImage = _imageController.text.isNotEmpty
          ? _imageController.text.trim()
          : _autoPhotos[Random().nextInt(_autoPhotos.length)];

      await FirebaseFirestore.instance.collection('properties').add({
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': finalImage,
        'virtualTourUrl': 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg',
        'createdAt': Timestamp.now(),
        'sellerId': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        _titleController.clear();
        _locationController.clear();
        _priceController.clear();
        _imageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing Posted!')));
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title (e.g. Modern Villa)', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per Month', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextField(controller: _imageController, decoration: const InputDecoration(labelText: 'Photo URL (Optional)', border: OutlineInputBorder(), hintText: 'Leave empty for automatic photo')),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 55)),
                child: const Text('Post Now', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}