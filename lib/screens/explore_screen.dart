import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import '../widgets/global_user_dp.dart';
import '../services/ai_engine.dart'; // IMPORT AI ENGINE
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

  // AI COMPONENTS
  final AIEngine _ai = AIEngine();
  Map<String, dynamic>? _userVector;
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadAI(); // Load preferences when opening explore
  }

  // Fetch the user's preference vector (Price, Rooms, Sqft averages)
  Future<void> _loadAI() async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(myId).get();
      if (mounted && userDoc.exists) {
        setState(() => _userVector = userDoc.data());
      }
    } catch (e) {
      print("Explore AI Load Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    double width = MediaQuery.of(context).size.width;
    // PRESERVED: Your exact responsive ratio logic
    double responsiveRatio = width < 600 ? 0.65 : 1.2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Explore", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white, elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GlobalUserDP(radius: 16, onTap: widget.onDPClick),
          ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 1. SEARCH BAR (UI Preserved)
        Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
                onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "Search location...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey[100]
                )
            )
        ),

        // 2. CATEGORY FILTERS (UI Preserved)
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: ["All", "Detached", "Semi-Detached", "Apartment", "Terrace", "Bungalow"].map((cat) {
              bool isSel = selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = cat),
                child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(color: isSel ? navy : (isDark ? Colors.white10 : Colors.grey[100]), borderRadius: BorderRadius.circular(20)),
                    child: Text(cat, style: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black54), fontWeight: FontWeight.bold, fontSize: 12))
                ),
              );
            }).toList())
        ),

        const SizedBox(height: 10),

        // 3. AI-POWERED GRID
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAI, // Pull down to refresh AI profile
            color: navy,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('properties').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // --- STEP 1: CONVERT DATA ---
                List<Property> props = snapshot.data!.docs.map((doc) =>
                    Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

                // --- STEP 2: FILTER BY USER INPUT ---
                var filteredProps = props.where((p) {
                  bool matchesCat = selectedCategory == "All" || p.houseType == selectedCategory;
                  bool matchesSearch = p.location.toLowerCase().contains(searchQuery) || p.houseType.toLowerCase().contains(searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                // --- STEP 3: APPLY AI RANKING (The Magic) ---
                // Even within search results, the "best matches" appear first
                List<Property> rankedProps = _ai.rankFeed(filteredProps, _userVector);

                if (rankedProps.isEmpty) return const Center(child: Text("No listings found."));

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: responsiveRatio
                  ),
                  itemCount: rankedProps.length,
                  itemBuilder: (context, index) {
                    final item = rankedProps[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: item))),
                      child: Container(
                        decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100)
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Stack(children: [
                            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(item.imageUrl, height: 70, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 70, color: Colors.grey))),
                            Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text(item.houseType, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)))),
                          ]),
                          Padding(padding: const EdgeInsets.all(5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.location, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text("\$${item.monthlyPrice.toStringAsFixed(0)}/mo", style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 10)),
                            // PRESERVED: Your exact bd/sqft line and font size
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