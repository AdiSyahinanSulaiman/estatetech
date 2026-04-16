import 'package:flutter/material.dart';
import '../models/property.dart';
import '../data/mock_data.dart';
import 'details_screen.dart';
import 'chat_detail_screen.dart'; // Add this

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EstateTech', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: globalProperties.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = globalProperties[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailsScreen(property: item)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200), // Serious, neutral border
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          item.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Save Button (Bookmark icon)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              item.isSaved = !item.isSaved;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Icon(
                              item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.black, // Neutral black color
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(item.location, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text('\$${item.price} / month', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Quick Message Button
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChatDetailScreen(landlordName: "Seller")),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}