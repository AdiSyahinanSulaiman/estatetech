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
      appBar: AppBar(title: const Text("My Listings"), elevation: 0, backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: myId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              final item = Property.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                  // FIXED: houseType and monthlyPrice
                  title: Text(item.houseType, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("\$${item.monthlyPrice} / mo"),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('properties').doc(item.id).delete()),
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