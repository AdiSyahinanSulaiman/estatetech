import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/global_user_dp.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  final VoidCallback onDPClick;
  const MessagesScreen({super.key, required this.onDPClick});

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;
    const Color navyBlue = Color(0xFF1B263B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("EstateTech",
            style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GlobalUserDP(radius: 18, onTap: onDPClick),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: navyBlue,
        child: Column(
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: conversations.entries.map((entry) {
                      String partnerId = entry.key;
                      var lastMsg = entry.value;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox();
                          var userData = userSnap.data!.data() as Map<String, dynamic>?;
                          String name = userData?['name'] ?? "User";
                          String photo = userData?['photoUrl'] ?? "";

                          return _buildConversationTile(context, name, partnerId, lastMsg, myId, photo);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, String name, String partnerId, Map<String, dynamic> lastMsg, String myId, String photo) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: partnerId))),
          leading: SizedBox(
            width: 65, height: 60,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network("https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=200", width: 55, height: 55, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: CircleAvatar(
                    radius: 12, backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundImage: photo.isNotEmpty
                          ? NetworkImage(photo)
                          : NetworkImage("https://ui-avatars.com/api/?name=$name&background=1B263B&color=fff") as ImageProvider,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(
            lastMsg['type'] == 'text' ? lastMsg['text'] : "Sent an attachment",
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          trailing: const Text("Now", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        const Divider(height: 1, indent: 90),
      ],
    );
  }
}