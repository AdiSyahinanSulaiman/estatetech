import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import 'details_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Saved Properties', style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0, backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        // Get my saved list
        stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final savedIds = snapshot.data!.docs.map((doc) => doc.id).toList();
          if (savedIds.isEmpty) return const Center(child: Text("No saved properties yet."));

          return StreamBuilder<QuerySnapshot>(
            // Get the actual property details for those IDs
            stream: FirebaseFirestore.instance.collection('properties').snapshots(),
            builder: (context, propSnapshot) {
              if (!propSnapshot.hasData) return const SizedBox();

              final savedProperties = propSnapshot.data!.docs
                  .where((doc) => savedIds.contains(doc.id))
                  .map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .toList();

              return ListView.builder(
                itemCount: savedProperties.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final item = savedProperties[index];
                  return ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover)),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.location),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}