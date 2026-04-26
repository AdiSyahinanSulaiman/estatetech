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
      appBar: AppBar(title: const Text('Saved Properties'), elevation: 0, backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final savedIds = snapshot.data!.docs.map((doc) => doc.id).toList();
          if (savedIds.isEmpty) return const Center(child: Text("No saved properties."));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('properties').snapshots(),
            builder: (context, propSnapshot) {
              if (!propSnapshot.hasData) return const SizedBox();
              final savedProps = propSnapshot.data!.docs
                  .where((doc) => savedIds.contains(doc.id))
                  .map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .toList();

              return ListView.builder(
                itemCount: savedProps.length,
                itemBuilder: (context, index) {
                  final item = savedProps[index];
                  return ListTile(
                    leading: Image.network(item.imageUrl, width: 50),
                    // FIXED: houseType
                    title: Text(item.houseType, style: const TextStyle(fontWeight: FontWeight.bold)),
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