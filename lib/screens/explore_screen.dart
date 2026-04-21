import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import 'details_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Properties', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // Explore also listens to the cloud database
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final properties = snapshot.data!.docs.map((doc) {
            return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final item = properties[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(property: item))),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('\$${item.price}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}