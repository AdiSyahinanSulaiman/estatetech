import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the inbox list
    final List<Map<String, String>> chats = [
      {
        'name': 'John Doe',
        'lastMessage': 'The viewing is scheduled for 10 AM.',
        'time': '2m ago',
        'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=1000'
      },
      {
        'name': 'Sarah Smith',
        'lastMessage': 'Is the deposit refundable?',
        'time': '1h ago',
        'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=1000'
      },
      {
        'name': 'Urban Realty',
        'lastMessage': 'We received your application.',
        'time': 'Yesterday',
        'image': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=1000'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(chat['image']!),
            ),
            title: Text(chat['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              chat['lastMessage']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Text(chat['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(sellerId: chat['name']!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}