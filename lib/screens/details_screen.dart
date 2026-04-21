import 'package:flutter/material.dart';
import '../models/property.dart';
import 'chat_detail_screen.dart';
import 'virtual_tour_screen.dart'; // Links to our 360 viewer

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
      extendBodyBehindAppBar: true, // Image goes under the status bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Bookmark button for the serious real estate look
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
            // Image Section with 360 Button
            Stack(
              children: [
                Image.network(
                  widget.property.imageUrl,
                  height: 450,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // The floating button to launch 360 Tour
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VirtualTourScreen(
                            imageUrl: widget.property.virtualTourUrl,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Colors.white.withOpacity(0.9),
                    elevation: 4,
                    icon: const Icon(Icons.view_in_ar, color: Colors.black),
                    label: const Text(
                      '360° Tour',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
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
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent
                        ),
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
                    'Experience luxury living with this exclusive listing. This property features premium finishes and is available for immediate viewing via our interactive 360° virtual tour.',
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 40),
                  // Message Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatDetailScreen(sellerId: "Listing Agent"),
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
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}