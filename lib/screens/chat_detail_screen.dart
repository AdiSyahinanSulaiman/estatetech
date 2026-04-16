import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  final String landlordName;

  const ChatDetailScreen({super.key, required this.landlordName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(landlordName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                _ChatBubble(text: "Hi! Is this property still available?", isMe: true),
                _ChatBubble(text: "Yes, it is! Would you like to schedule a viewing?", isMe: false),
              ],
            ),
          ),
          // Message Input Area
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.send, color: Colors.blueAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const _ChatBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }
}