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
    final Color navy = const Color(0xFF1B263B);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive ratio logic (Preserved)
    double width = MediaQuery.of(context).size.width;
    double responsiveRatio = width < 600 ? 0.65 : 1.2;

    return Scaffold(
      // FIXED: Background is now theme-aware
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        // 1. Listen to your saved IDs collection
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(myId)
            .collection('saved')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final savedIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          if (savedIds.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No saved properties yet.", style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            // 2. Listen to the properties collection
            stream: FirebaseFirestore.instance.collection('properties').snapshots(),
            builder: (context, propSnapshot) {
              if (!propSnapshot.hasData) return const SizedBox();

              // Filter properties locally based on your saved IDs
              final savedProps = propSnapshot.data!.docs
                  .where((doc) => savedIds.contains(doc.id))
                  .map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .toList();

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: responsiveRatio,
                ),
                itemCount: savedProps.length,
                itemBuilder: (context, index) {
                  final item = savedProps[index];
                  return _buildCompactCard(context, item, navy, isDark);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, Property item, Color navy, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => DetailsScreen(property: item)),
      ),
      child: Container(
        decoration: BoxDecoration(
          // FIXED: Card background respects dark mode
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    item.imageUrl,
                    height: 70,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.houseType,
                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            // Text Info
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.location,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: isDark ? Colors.white : Colors.black // FIXED: Visible text
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "\$${item.monthlyPrice.toStringAsFixed(0)}/mo",
                    style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                  Text(
                    "${item.rooms}bd • ${item.sqft}ft",
                    style: const TextStyle(color: Colors.grey, fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}