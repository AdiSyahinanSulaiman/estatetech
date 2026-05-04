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
    double width = MediaQuery.of(context).size.width;
    double responsiveRatio = width < 600 ? 0.65 : 1.2;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final savedIds = snapshot.data!.docs.map((doc) => doc.id).toList();
        if (savedIds.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No saved items.")));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('properties').snapshots(),
          builder: (context, propSnapshot) {
            if (!propSnapshot.hasData) return const SizedBox();
            final savedProps = propSnapshot.data!.docs.where((doc) => savedIds.contains(doc.id)).map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              physics: const NeverScrollableScrollPhysics(), // ALLOWS PARENT TO SCROLL
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
                childAspectRatio: responsiveRatio,
              ),
              itemCount: savedProps.length,
              itemBuilder: (context, index) {
                final item = savedProps[index];
                return _buildCompactCard(context, item);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context, Property item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: item))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(item.imageUrl, height: 70, width: double.infinity, fit: BoxFit.cover)),
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