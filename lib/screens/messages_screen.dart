import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/global_user_dp.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  final VoidCallback onDPClick;
  const MessagesScreen({super.key, required this.onDPClick});

  Future<void> _handleRefresh() async => await Future.delayed(const Duration(seconds: 1));

  // --- FIXED: RELATIVE TIME LOGIC ---
  String _getRelativeTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return DateFormat('E').format(date);
    // FIXED: Added .format(date) below
    return DateFormat('dd/MM').format(date);
  }

  void _showDeleteDialog(BuildContext context, String partnerId, String partnerName) {
    final String myId = FirebaseAuth.instance.currentUser!.uid;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Conversation?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                List<String> ids = [myId, partnerId];
                ids.sort();
                await FirebaseFirestore.instance.collection('chats').doc(ids.join("_")).delete();
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text("EstateTech",
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 15), child: GlobalUserDP(radius: 18, onTap: onDPClick)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF1B263B),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
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

                      // --- SAFETY LOGIC FOR SELF-MESSAGING ---
                      String partnerId;
                      if (users.length == 1) {
                        partnerId = users[0]; // It's a chat with yourself
                      } else {
                        partnerId = users.firstWhere((id) => id != myId, orElse: () => myId);
                      }

                      if (partnerId.isEmpty) return const SizedBox.shrink();

                      String? propertyId = chatData['propertyId'];
                      bool isUnread = (chatData['lastSenderId'] != myId) && (chatData['isRead'] == false);

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
                          var userData = userSnap.data!.data() as Map<String, dynamic>?;
                          return _buildConversationTile(context, userData?['name'] ?? "User", partnerId, chatData, propertyId, isUnread);
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

  Widget _buildConversationTile(BuildContext context, String name, String partnerId, Map<String, dynamic> chatData, String? propertyId, bool isUnread) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color navyBlue = Color(0xFF1B263B);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: partnerId, propertyId: propertyId))),
          onLongPress: () => _showDeleteDialog(context, partnerId, name),
          leading: SizedBox(
            width: 65, height: 60,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: propertyId != null && propertyId.isNotEmpty
                      ? FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('properties').doc(propertyId).get(),
                    builder: (context, snap) {
                      String url = "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=200";
                      if (snap.hasData && snap.data!.exists) url = (snap.data!.data() as Map<String, dynamic>)['imageUrl'];
                      return Image.network(url, width: 55, height: 55, fit: BoxFit.cover);
                    },
                  )
                      : Image.network("https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=200", width: 55, height: 55, fit: BoxFit.cover),
                ),
                Positioned(bottom: 0, right: 0, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF0D1117) : Colors.white, width: 2)), child: GlobalUserDP(radius: 12, userId: partnerId))),
              ],
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              Text(_getRelativeTime(chatData['timestamp'] as Timestamp?),
                  style: TextStyle(color: isUnread ? navyBlue : Colors.grey, fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                    chatData['lastMessage'] ?? "New message",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isUnread ? (isDark ? Colors.white : Colors.black) : Colors.grey, fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal)
                ),
              ),
              if (isUnread)
                Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: const BoxDecoration(color: navyBlue, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
        Divider(height: 1, indent: 90, color: isDark ? Colors.white10 : Colors.grey[200]),
      ],
    );
  }
}