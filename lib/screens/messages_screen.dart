import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? myId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 1. Find all unique IDs of people I have messaged
          final List<String> chatPartners = [];
          for (var doc in snapshot.data!.docs) {
            var d = doc.data() as Map<String, dynamic>;
            if (d['senderId'] == myId) chatPartners.add(d['receiverId']);
            if (d['receiverId'] == myId) chatPartners.add(d['senderId']);
          }
          final uniquePartners = chatPartners.toSet().toList();

          if (uniquePartners.isEmpty) {
            return const Center(child: Text("No messages yet."));
          }

          return ListView.builder(
            itemCount: uniquePartners.length,
            itemBuilder: (context, index) {
              final partnerId = uniquePartners[index];

              // 2. This sub-widget looks up the Real Name for each ID
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                builder: (context, userSnapshot) {
                  // While waiting for name, show a loading line
                  if (!userSnapshot.hasData) return const ListTile(title: Text("Loading..."));

                  // Grab the name and initials from the user's document
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  String name = userData?['name'] ?? "User";
                  String photo = "https://ui-avatars.com/api/?name=$name&background=random";

                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(photo)),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tap to view conversation"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(sellerId: partnerId),
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}