import 'package:flutter/material.dart';
import '../models/property.dart';
import 'chat_detail_screen.dart';

class DetailsScreen extends StatefulWidget {
  final Property property;

  const DetailsScreen({super.key, required this.property});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Extends the image behind the status bar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Serious bookmark button instead of a heart
          IconButton(
            icon: Icon(
              widget.property.isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                widget.property.isSaved = !widget.property.isSaved;
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Image.network(
              widget.property.imageUrl,
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.property.title,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '\$${widget.property.price}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.location,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    'Listing Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This professional listing offers premium amenities and a highly desirable location. Suitable for individuals looking for a long-term, high-quality residence.',
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 40),
                  // Contact Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatDetailScreen(landlordName: "Listing Agent"),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Message Landlord',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 50), // Extra space for scrolling
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}