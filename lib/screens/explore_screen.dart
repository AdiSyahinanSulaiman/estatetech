import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../widgets/global_user_dp.dart';
import 'details_screen.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback onDPClick;
  const ExploreScreen({super.key, required this.onDPClick});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String selectedCategory = "All";
  String searchQuery = "";
  final Color navy = const Color(0xFF1B263B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    double width = MediaQuery.of(context).size.width;
    double responsiveRatio = width < 600 ? 0.65 : 1.2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("EstateTech", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, elevation: 0,
        actions: [Padding(padding: const EdgeInsets.only(right: 15), child: GlobalUserDP(radius: 16, onTap: widget.onDPClick))],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(onChanged: (v) => setState(() => searchQuery = v.toLowerCase()), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: "Search location...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), filled: true, fillColor: isDark ? Colors.white10 : Colors.grey[100]))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), child: Row(children: ["All", "Detached", "Semi-Detached", "Apartment", "Terrace", "Bungalow"].map((cat) {
          bool isSel = selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat),
            child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(color: isSel ? navy : (isDark ? Colors.white10 : Colors.grey[100]), borderRadius: BorderRadius.circular(20)), child: Text(cat, style: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black54), fontWeight: FontWeight.bold, fontSize: 12))),
          );
        }).toList())),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            color: navy,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('properties').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final props = snapshot.data!.docs.map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)).where((p) {
                  bool matchesCat = selectedCategory == "All" || p.houseType == selectedCategory;
                  bool matchesSearch = p.location.toLowerCase().contains(searchQuery) || p.houseType.toLowerCase().contains(searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();
                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: responsiveRatio),
                  itemCount: props.length,
                  itemBuilder: (context, index) {
                    final item = props[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: item))),
                      child: Container(
                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Stack(children: [
                            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(item.imageUrl, height: 70, width: double.infinity, fit: BoxFit.cover)),
                            Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text(item.houseType, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)))),
                          ]),
                          Padding(padding: const EdgeInsets.all(5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.location, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text("\$${item.monthlyPrice.toStringAsFixed(0)}/mo", style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 10)),
                            Text("${item.rooms}bd • ${item.sqft}ft", style: const TextStyle(color: Colors.grey, fontSize: 8)),
                          ])),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        )
      ]),
    );
  }
}