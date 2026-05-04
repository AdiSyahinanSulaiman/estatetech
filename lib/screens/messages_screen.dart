import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/global_user_dp.dart'; // Add this
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  final VoidCallback onDPClick;
  const MessagesScreen({super.key, required this.onDPClick});

  @override
  Widget build(BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("EstateTech", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        actions: [
          // UPDATED: Global DP
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GlobalUserDP(radius: 16, onTap: onDPClick),
          ),
        ],
      ),
      body: Column(children: [
        // Search Bar
        Padding(padding: const EdgeInsets.all(15), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)), child: const TextField(decoration: InputDecoration(icon: Icon(Icons.search), hintText: "Search conversations...", border: InputBorder.none)))),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              Map<String, Map<String, dynamic>> conversations = {};
              for (var doc in snapshot.data!.docs) {
                var d = doc.data() as Map<String, dynamic>;
                String partnerId = d['senderId'] == myId ? d['receiverId'] : d['senderId'];
                if (d['senderId'] == myId || d['receiverId'] == myId) {
                  if (!conversations.containsKey(partnerId)) conversations[partnerId] = d;
                }
              }

              if (conversations.isEmpty) return const Center(child: Text("No messages yet."));

              return ListView(
                children: conversations.entries.map((entry) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(entry.key).get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();
                      var userData = userSnap.data!.data() as Map<String, dynamic>?;
                      String name = userData?['name'] ?? "User";
                      String photo = userData?['photoUrl'] ?? "";
                      bool unread = entry.value['receiverId'] == myId && entry.value['isRead'] == false;

                      return Column(children: [
                        ListTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: entry.key))),
                          leading: SizedBox(width: 60, height: 60, child: Stack(children: [
                            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network("https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=200", width: 50, height: 50, fit: BoxFit.cover)),
                            Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: CircleAvatar(radius: 10, backgroundImage: NetworkImage(photo.isNotEmpty ? photo : "https://ui-avatars.com/api/?name=$name&background=random")))),
                          ])),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(entry.value['text'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal)),
                          trailing: unread ? const Icon(Icons.brightness_1, color: Colors.blue, size: 10) : const Text("2h ago", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                        const Divider(indent: 80),
                      ]);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ]),
    );
  }
}