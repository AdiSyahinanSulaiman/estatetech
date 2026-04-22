import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import 'details_screen.dart';

class UserListingsScreen extends StatelessWidget {
  const UserListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? myId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Listings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .where('sellerId', isEqualTo: myId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("You haven't posted any listings yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              final item = Property.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);

              return Card(
                color: Colors.white,
                // FIXED THE ERROR HERE:
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200)
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item.imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("\$${item.price} / month"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      FirebaseFirestore.instance.collection('properties').doc(item.id).delete();
                    },
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}