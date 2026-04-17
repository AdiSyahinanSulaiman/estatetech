import 'package:flutter/material.dart';
import '../models/property.dart';
import '../data/mock_data.dart';
import 'details_screen.dart';
import 'chat_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // This is our "AI" Recommendation Engine
  void _applyRecommendationEngine() {
    setState(() {
      globalProperties.sort((a, b) {
        // Priority 1: Items the user has already saved (keep them accessible)
        if (a.isSaved && !b.isSaved) return -1;
        if (!a.isSaved && b.isSaved) return 1;

        // Priority 2: Recommend properties in similar price brackets (Premium focus)
        // We put higher value properties first to simulate a "Premium FYP"
        return b.price.compareTo(a.price);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _applyRecommendationEngine(); // Run the "AI" when the screen opens
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark mode makes property photos pop
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
            'For You',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber), // Represents AI
            onPressed: () {
              _applyRecommendationEngine();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI: Feed updated based on your interests')),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical, // Snap-scrolling like TikTok
        itemCount: globalProperties.length,
        itemBuilder: (context, index) {
          final item = globalProperties[index];

          return Stack(
            children: [
              // 1. Full Screen Background Image
              SizedBox.expand(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                ),
              ),

              // 2. Gradient Overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // 3. Property Info (Bottom Left)
              Positioned(
                bottom: 50,
                left: 20,
                right: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        Text(item.location, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '\$${item.price} / mo',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Detail Button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DetailsScreen(property: item)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text('Property Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Interaction Sidebar (Right Side)
              Positioned(
                bottom: 60,
                right: 20,
                child: Column(
                  children: [
                    _SidebarIcon(
                      icon: item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      label: 'Save',
                      activeColor: Colors.amber,
                      isActive: item.isSaved,
                      onTap: () {
                        setState(() {
                          item.isSaved = !item.isSaved;
                          _applyRecommendationEngine(); // Re-rank feed when preferences change
                        });
                      },
                    ),
                    const SizedBox(height: 25),
                    _SidebarIcon(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatDetailScreen(landlordName: "Agent")),
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    _SidebarIcon(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _SidebarIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: isActive ? activeColor : Colors.white, size: 35),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}