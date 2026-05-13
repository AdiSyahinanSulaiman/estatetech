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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('saved').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No saved properties yet."));

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.75
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            String propId = snapshot.data!.docs[index].id;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('properties').doc(propId).get(),
              builder: (context, propSnap) {
                if (!propSnap.hasData || !propSnap.data!.exists) return const SizedBox();
                var p = Property.fromMap(propSnap.data!.data() as Map<String, dynamic>, propSnap.data!.id);

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
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(p.imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.location, maxLines: 1, style: TextStyle(color: Colors.grey, fontSize: 10)),
                              Text("\$${p.monthlyPrice.toStringAsFixed(0)}/mo", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
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
      },
    );
  }
}