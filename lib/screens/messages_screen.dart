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

  // --- MASTER DELETE CHAT LOGIC ---
  void _showDeleteDialog(BuildContext context, String partnerId, String partnerName) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Conversation?"),
        content: Text("Remove all messages with $partnerName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                List<String> ids = [myId, partnerId];
                ids.sort();
                String chatId = ids.join("_");
                await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;
    const Color navyBlue = Color(0xFF1B263B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text("Messages", style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [Padding(padding: const EdgeInsets.only(right: 15), child: GlobalUserDP(radius: 18, onTap: onDPClick))],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: navyBlue,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                child: const TextField(decoration: InputDecoration(icon: Icon(Icons.search, color: Colors.grey), hintText: "Search conversations...", border: InputBorder.none)),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats').where('users', arrayContains: myId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No messages yet."));

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      List users = chatData['users'] ?? [];
                      String partnerId = users.firstWhere((id) => id != myId, orElse: () => "");
                      String? propertyId = chatData['propertyId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) return const SizedBox();
                          var userData = userSnap.data!.data() as Map<String, dynamic>?;
                          String name = userData?['name'] ?? "User";

                          return _buildConversationTile(context, name, partnerId, chatData, propertyId);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, String name, String partnerId, Map<String, dynamic> chatData, String? propertyId) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: partnerId, propertyId: propertyId))),
          onLongPress: () => _showDeleteDialog(context, partnerId, name),

          // --- THE HOUSE BACKGROUND + DP STACK ---
          leading: SizedBox(
            width: 65, height: 60,
            child: Stack(
              children: [
                // 1. Bottom Layer: The actual Property Image the user is interested in
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: propertyId != null
                      ? FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('properties').doc(propertyId).get(),
                    builder: (context, propSnap) {
                      String imgUrl = "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=200"; // Placeholder
                      if (propSnap.hasData && propSnap.data!.exists) {
                        imgUrl = (propSnap.data!.data() as Map<String, dynamic>)['imageUrl'];
                      }
                      return Image.network(imgUrl, width: 55, height: 55, fit: BoxFit.cover);
                    },
                  )
                      : Image.network("https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=200", width: 55, height: 55, fit: BoxFit.cover),
                ),
                // 2. Top Layer: The small Partner DP on the bottom right
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: GlobalUserDP(radius: 12, userId: partnerId),
                  ),
                ),
              ],
            ),
          ),

          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(chatData['lastMessage'] ?? "New message", maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Text("Now", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        const Divider(height: 1, indent: 90),
      ],
    );
  }
}