import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String sellerId;
  const ChatDetailScreen({super.key, required this.sellerId});
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  final AudioRecorder audioRecorder = AudioRecorder();
  bool _isUploading = false;
  bool _isRecording = false;

  // 1. PICK MEDIA (Image or Video)
  void _pickMedia(String type) async {
    final picker = ImagePicker();
    XFile? picked;
    if (type == 'image') picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (type == 'video') picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) _uploadFile(File(picked.path), type);
  }

  // 2. VOICE NOTE LOGIC
  void _toggleRecording() async {
    if (_isRecording) {
      final path = await audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) _uploadFile(File(path), 'audio');
    } else {
      if (await audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  // 3. LOCATION LOGIC
  void _sendLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    String url = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
    _sendMessage(text: url, type: 'location');
    Navigator.pop(context);
  }

  // MASTER UPLOAD
  void _uploadFile(File file, String type) async {
    setState(() => _isUploading = true);
    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}";
      var ref = FirebaseStorage.instance.ref().child('chat').child(fileName);
      await ref.putFile(file); // Wait for upload
      String url = await ref.getDownloadURL();
      _sendMessage(text: url, type: type);
    } catch (e) {
      print("Upload Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _sendMessage({required String text, String type = 'text'}) {
    FirebaseFirestore.instance.collection('messages').add({
      'text': text, 'type': type, 'senderId': myId, 'receiverId': widget.sellerId,
      'isRead': false, 'timestamp': Timestamp.now(),
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Estate Chat")),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final msgs = snapshot.data!.docs.where((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  return (d['senderId'] == myId && d['receiverId'] == widget.sellerId) || (d['senderId'] == widget.sellerId && d['receiverId'] == myId);
                }).toList();
                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, i) => _buildBubble(msgs[i].data() as Map<String, dynamic>),
                );
              },
            ),
          ),
          _inputArea(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> d) {
    bool isMe = d['senderId'] == myId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isMe ? Colors.black : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
        child: _mediaContent(d, isMe),
      ),
    );
  }

  Widget _mediaContent(Map<String, dynamic> d, bool isMe) {
    Color tc = isMe ? Colors.white : Colors.black;
    if (d['type'] == 'image') return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(d['text'], width: 200));
    if (d['type'] == 'video') return Column(children: [Icon(Icons.play_circle, color: tc, size: 40), Text("Video Note", style: TextStyle(color: tc))]);
    if (d['type'] == 'audio') return Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mic, color: tc), Text(" Voice Note", style: TextStyle(color: tc))]);
    if (d['type'] == 'location') return InkWell(onTap: () => launchUrl(Uri.parse(d['text'])), child: const Text("📍 View Location", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)));
    return Text(d['text'], style: TextStyle(color: tc));
  }

  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _showMenu),
        Expanded(child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: "Message...", border: InputBorder.none))),
        // MIC BUTTON
        IconButton(
          icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Colors.red : Colors.black),
          onPressed: _toggleRecording,
        ),
        IconButton(icon: const Icon(Icons.send), onPressed: () => _sendMessage(text: _msgController.text)),
      ]),
    );
  }

  void _showMenu() {
    showModalBottomSheet(context: context, builder: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(leading: const Icon(Icons.image), title: const Text("Send Photo"), onTap: () { Navigator.pop(c); _pickMedia('image'); }),
        ListTile(leading: const Icon(Icons.videocam), title: const Text("Send Video Note"), onTap: () { Navigator.pop(c); _pickMedia('video'); }),
        ListTile(leading: const Icon(Icons.location_on), title: const Text("Send Location"), onTap: _sendLocation),
      ],
    ));
  }
}