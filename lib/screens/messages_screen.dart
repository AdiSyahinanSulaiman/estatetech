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
        stream: FirebaseFirestore.instance.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          Set<String> chatPartnerIds = {};
          Map<String, bool> hasUnread = {}; // Tracks if this conversation has a new message

          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String partnerId = data['senderId'] == myId ? data['receiverId'] : data['senderId'];

            if (data['senderId'] == myId || data['receiverId'] == myId) {
              chatPartnerIds.add(partnerId);
              // If I am the receiver and it is not read, mark as unread
              if (data['receiverId'] == myId && data['isRead'] == false) {
                hasUnread[partnerId] = true;
              }
            }
          }

          return ListView(
            children: chatPartnerIds.map((partnerId) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  String name = userSnap.data?['name'] ?? "User";
                  bool unread = hasUnread[partnerId] ?? false;

                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$name&background=0D8ABC&color=fff")),
                    title: Text(name, style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal)),
                    // THE SIGN: A blue dot if there is an unread message
                    trailing: unread ? const Icon(Icons.brightness_1, color: Colors.blue, size: 12) : const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      // Mark all messages from this person as Read
                      _markAsRead(myId, partnerId);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(sellerId: partnerId)));
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _markAsRead(String myId, String partnerId) async {
    var snap = await FirebaseFirestore.instance.collection('messages')
        .where('receiverId', isEqualTo: myId)
        .where('senderId', isEqualTo: partnerId)
        .get();
    for (var doc in snap.docs) {
      doc.reference.update({'isRead': true});
    }
  }
}