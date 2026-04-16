import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/property.dart';
import 'details_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This line "filters" the list to only show liked items
    final List<Property> savedItems =
    globalProperties.where((p) => p.isSaved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Properties', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: savedItems.isEmpty
          ? const Center(child: Text('No saved properties yet.'))
          : ListView.builder(
        itemCount: savedItems.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = savedItems[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
            ),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.location),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailsScreen(property: item)),
              );
            },
          );
        },
      ),
    );
  }
}