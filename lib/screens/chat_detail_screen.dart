import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String sellerId;
  final String? propertyId;
  const ChatDetailScreen({super.key, required this.sellerId, this.propertyId});
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool _isTyping = false, _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  void _sendMessage({required String text, String type = 'text'}) async {
    if (text.isEmpty) return;
    await FirebaseFirestore.instance.collection('messages').add({
      'text': text, 'type': type, 'senderId': myId, 'receiverId': widget.sellerId,
      'isRead': false, 'timestamp': Timestamp.now(),
    });
    List<String> ids = [myId, widget.sellerId];
    ids.sort();
    String chatId = ids.join("_");
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': type == 'text' ? text : 'Sent an attachment',
      'timestamp': FieldValue.serverTimestamp(),
      'users': [myId, widget.sellerId],
    }, SetOptions(merge: true));
    _msgController.clear();
  }

  // NOTE: Keep all your existing audio/file methods here... (startRecording, stopAndSend, etc.)
  // I am skipping them for brevity to fit the whole UI structure below.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(backgroundColor: const Color(0xFF1B263B), title: const Text("Chat", style: TextStyle(color: Colors.white))),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final msgs = snapshot.data!.docs.where((doc) {
                var d = doc.data() as Map<String, dynamic>;
                return (d['senderId'] == myId && d['receiverId'] == widget.sellerId) || (d['senderId'] == widget.sellerId && d['receiverId'] == myId);
              }).toList();
              return ListView.builder(
                reverse: true,
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  var d = msgs[i].data() as Map<String, dynamic>;
                  bool isMe = d['senderId'] == myId;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isMe ? const Color(0xFF1B263B) : Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(d['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildInput(),
      ]),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(10), color: Colors.white,
      child: Row(children: [
        Expanded(child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: "Message..."))),
        IconButton(icon: const Icon(Icons.send), onPressed: () => _sendMessage(text: _msgController.text)),
      ]),
    );
  }
}