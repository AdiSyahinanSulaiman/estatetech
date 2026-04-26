import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import 'details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String selectedCategory = "All";
  final Color navy = const Color(0xFF1B263B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Explore properties", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            Expanded(child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: "Search location...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100]))),
            const SizedBox(width: 10),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.tune, color: Colors.white)),
          ]),
        ),

        // 2. Category Chips
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), child: Row(children: ["All", "Apartment", "House", "Penthouse", "Loft"].map((cat) {
          bool isSel = selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat),
            child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: isSel ? navy : Colors.grey[100], borderRadius: BorderRadius.circular(20)), child: Text(cat, style: TextStyle(color: isSel ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
          );
        }).toList())),

        const Padding(padding: EdgeInsets.all(15), child: Text("Properties found", style: TextStyle(color: Colors.grey))),

        // 3. Grid View
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('properties').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final props = snapshot.data!.docs.map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

              return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.7),
                itemCount: props.length,
                itemBuilder: (context, index) {
                  final item = props[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: item))),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // IMAGE WITH BADGE INSIDE
                        Stack(children: [
                          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network(item.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover)),
                          Positioned(top: 10, left: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)), child: Text(item.houseType, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                        ]),
                        // TEXT SECTION (Location is now the main title)
                        Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text("\$${item.monthlyPrice.toStringAsFixed(0)}/mo", style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text("${item.rooms}bd • ${item.baths}ba • ${item.sqft}sqft", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ])),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        )
      ]),
    );
  }
}