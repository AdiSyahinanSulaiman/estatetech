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
      appBar: AppBar(title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to ALL messages in the cloud
        stream: FirebaseFirestore.instance.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Find unique people who have messaged me or I have messaged
          Set<String> chatPartnerIds = {};
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (data['senderId'] == myId) chatPartnerIds.add(data['receiverId']);
            if (data['receiverId'] == myId) chatPartnerIds.add(data['senderId']);
          }

          if (chatPartnerIds.isEmpty) return const Center(child: Text("No conversations yet."));

          return ListView(
            children: chatPartnerIds.map((partnerId) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  String name = userSnap.data?['name'] ?? "User";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$name&background=0D8ABC&color=fff"),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tap to view messages"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(sellerId: partnerId),
                    )),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}