import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import 'details_screen.dart';

class UserListingsScreen extends StatelessWidget {
  const UserListingsScreen({super.key});

  // --- DELETE CONFIRMATION DIALOG ---
  void _confirmDelete(BuildContext context, String propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this property? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close without deleting
            child: const Text("No", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseFirestore.instance.collection('properties').doc(propertyId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Listing deleted successfully")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B263B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('sellerId', isEqualTo: myId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No listings yet."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var p = Property.fromMap(data, snapshot.data!.docs[index].id);

            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: p))),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(p.imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover),
                        ),
                        // THE DELETE TRIGGER (RED 'X')
                        Positioned(
                          top: 5, right: 5,
                          child: GestureDetector(
                            onTap: () => _confirmDelete(context, p.id), // Open the Yes/No warning
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red.withOpacity(0.8),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.houseType, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(p.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            "\$${p.monthlyPrice.toStringAsFixed(0)}/mo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}