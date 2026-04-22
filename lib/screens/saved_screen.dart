import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import 'details_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saved Properties', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // We get all properties from the cloud
        stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // We filter them LOCALLY to show only the ones you clicked "Save" on
          final savedItems = snapshot.data!.docs
              .map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((p) => p.isSaved) // This checks our local "isSaved" memory
              .toList();

          if (savedItems.isEmpty) {
            return const Center(child: Text("No saved properties in this session."));
          }

          return ListView.builder(
            itemCount: savedItems.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = savedItems[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.location),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))),
              );
            },
          );
        },
      ),
    );
  }
}