import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailScreen extends StatefulWidget {
  final String sellerId; // Now we pass the ID of the person we are talking to
  const ChatDetailScreen({super.key, required this.sellerId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String? myId = FirebaseAuth.instance.currentUser?.uid;

  void _sendMessage() async {
    if (_msgController.text.isEmpty) return;

    // Save message to a global messages collection
    await FirebaseFirestore.instance.collection('messages').add({
      'text': _msgController.text.trim(),
      'senderId': myId,
      'receiverId': widget.sellerId,
      'timestamp': Timestamp.now(),
    });

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat with Seller"), backgroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // This query finds messages between ME and the SELLER
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final msgs = snapshot.data!.docs.where((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  // Only show messages if they belong to this specific conversation
                  return (d['senderId'] == myId && d['receiverId'] == widget.sellerId) ||
                      (d['senderId'] == widget.sellerId && d['receiverId'] == myId);
                }).toList();

                return ListView.builder(
                  reverse: true, // Newest messages at the bottom
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    var d = msgs[index].data() as Map<String, dynamic>;
                    bool isMe = d['senderId'] == myId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.black : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(d['text'], style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: "Type message..."))),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}