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
    double width = MediaQuery.of(context).size.width;
    double responsiveRatio = width < 600 ? 0.65 : 1.2;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: myId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No listings yet.")));

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          physics: const NeverScrollableScrollPhysics(), // ALLOWS PARENT TO SCROLL
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: responsiveRatio,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final item = Property.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            return _buildCompactCard(context, item, isOwner: true);
          },
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context, Property item, {required bool isOwner}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: item))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(item.imageUrl, height: 70, width: double.infinity, fit: BoxFit.cover)),
              if (isOwner) Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => FirebaseFirestore.instance.collection('properties').doc(item.id).delete(), child: CircleAvatar(radius: 10, backgroundColor: Colors.white.withOpacity(0.8), child: const Icon(Icons.close, color: Colors.red, size: 12)))),
            ]),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.houseType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1),
                  Text(item.location, style: const TextStyle(color: Colors.grey, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("\$${item.monthlyPrice.toStringAsFixed(0)}/mo", style: const TextStyle(color: Color(0xFF1B263B), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}