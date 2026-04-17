import 'package:flutter/material.dart';
import '../models/property.dart';
import '../data/mock_data.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  // These "Controllers" grab the text the user types
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _submitData() {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) return;

    // Create a new property object
    final newProperty = Property(
      id: DateTime.now().toString(), // Generates a unique ID
      title: _titleController.text,
      location: _locationController.text,
      price: double.parse(_priceController.text),
      imageUrl: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=1000&auto=format&fit=crop', // Default house image
      virtualTourUrl: 'https://pannellum.org/images/alma.jpg',
    );

    // Add it to our global list
    setState(() {
      globalProperties.insert(0, newProperty); // Put at the top of the list
    });

    // Clear the fields
    _titleController.clear();
    _locationController.clear();
    _priceController.clear();

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing Posted Successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Listing'), backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Property Title')),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per Month'), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
              child: const Text('Post Listing', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}