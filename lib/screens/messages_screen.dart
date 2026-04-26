import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Inbox",
            style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          // Top right profile initials
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search conversations...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // 2. CONVERSATIONS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Logic to find unique people and their last message
                Map<String, Map<String, dynamic>> conversations = {};
                for (var doc in snapshot.data!.docs) {
                  var d = doc.data() as Map<String, dynamic>;
                  String partnerId = d['senderId'] == myId ? d['receiverId'] : d['senderId'];

                  if (d['senderId'] == myId || d['receiverId'] == myId) {
                    if (!conversations.containsKey(partnerId)) {
                      conversations[partnerId] = d;
                    }
                  }
                }

                if (conversations.isEmpty) return const Center(child: Text("No messages yet."));

                return ListView(
                  children: conversations.entries.map((entry) {
                    String partnerId = entry.key;
                    var lastMsg = entry.value;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox();
                        var userData = userSnap.data!.data() as Map<String, dynamic>?;
                        String name = userData?['name'] ?? "User";

                        return _buildConversationTile(context, name, partnerId, lastMsg, myId);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, String name, String partnerId, Map<String, dynamic> lastMsg, String myId) {
    bool unread = lastMsg['receiverId'] == myId && lastMsg['isRead'] == false;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: partnerId))),

          // LEFT SIDE: Property Image with Overlaid User Avatar
          leading: SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=200", // Placeholder house
                    width: 60, height: 60, fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$name&background=random"),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MIDDLE: Name, Property, and Message
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text("2h ago", style: TextStyle(color: Colors.grey, fontSize: 12)), // Static time for demo
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Modern Luxury Apartment", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lastMsg['text'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread ? Colors.black : Colors.grey,
                        fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (unread)
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 95), // Separator line
      ],
    );
  }
}