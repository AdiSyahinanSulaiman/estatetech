import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import 'details_screen.dart';

class UserListingsScreen extends StatelessWidget {
  const UserListingsScreen({super.key});

  // --- DELETE CONFIRMATION DIALOG (Preserved) ---
  void _confirmDelete(BuildContext context, String propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this property? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
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
              crossAxisSpacing: 8, // Tighter spacing like Explore
              mainAxisSpacing: 8,
              // --- FIXED: 1.0 or higher makes the box SHORTER ---
              childAspectRatio: 1.0
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
                          child: Image.network(
                              p.imageUrl,
                              height: 65, // Reduced from 100 to 65 to make it "shorter"
                              width: double.infinity,
                              fit: BoxFit.cover
                          ),
                        ),
                        // THE DELETE TRIGGER (RED 'X')
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => _confirmDelete(context, p.id),
                            child: CircleAvatar(
                              radius: 9, // Slightly smaller to match shorter box
                              backgroundColor: Colors.red.withOpacity(0.8),
                              child: const Icon(Icons.close, size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0), // Tightened padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.houseType,
                            style: const TextStyle(color: Colors.grey, fontSize: 8), // Small font like Explore
                            maxLines: 1,
                          ),
                          Text(
                              p.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 8)
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "\$${p.monthlyPrice.toStringAsFixed(0)}/mo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 9, // Smaller to fit the short box
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