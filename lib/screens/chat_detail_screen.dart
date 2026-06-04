import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/global_user_dp.dart';
import 'map_picker_screen.dart';

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
  String? _playingUrl;
  Duration _duration = Duration.zero, _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _msgController.addListener(() { if (mounted) setState(() => _isTyping = _msgController.text.isNotEmpty); });
    audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    audioPlayer.onPlayerComplete.listen((_) => setState(() { _playingUrl = null; _position = Duration.zero; }));
    _markAsRead();
  }

  void _markAsRead() async {
    List<String> ids = [myId, widget.sellerId];
    ids.sort();
    await FirebaseFirestore.instance.collection('chats').doc(ids.join("_")).update({'isRead': true});
  }

  @override
  void dispose() { _timer?.cancel(); audioRecorder.dispose(); audioPlayer.dispose(); _msgController.dispose(); super.dispose(); }

  String _formatTimer(int seconds) => "${(seconds ~/ 60)}:${(seconds % 60).toString().padLeft(2, '0')}";

  // --- ATTACHMENT ACTIONS ---

  void _startRecording() async {
    if (await audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordDuration = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordDuration++));
      await audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  void _stopAndSend() async {
    _timer?.cancel();
    final path = await audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) _uploadFile(File(path), 'audio');
  }

  void _pickMedia(bool isCam) async {
    final p = await ImagePicker().pickImage(source: isCam ? ImageSource.camera : ImageSource.gallery, imageQuality: 50);
    if (p != null) _uploadFile(File(p.path), 'image');
  }

  void _pickFile() async {
    final r = await FilePicker.platform.pickFiles();
    if (r != null) _uploadFile(File(r.files.single.path!), 'file');
  }

  // --- UPDATED: VISUAL LOCATION PICKER ---
  void _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null) {
      String url = "https://www.google.com/maps/search/?api=1&query=${result.latitude},${result.longitude}";
      _sendMessage(text: url, type: 'location');
    }
  }

  void _uploadFile(File file, String type) async {
    String name = "${DateTime.now().millisecondsSinceEpoch}";
    var ref = FirebaseStorage.instance.ref('chat/$name');
    await ref.putFile(file);
    String url = await ref.getDownloadURL();
    _sendMessage(text: url, type: type);
  }

  void _sendMessage({required String text, String type = 'text'}) async {
    if (text.isEmpty) return;
    await FirebaseFirestore.instance.collection('messages').add({
      'text': text, 'type': type, 'senderId': myId, 'receiverId': widget.sellerId,
      'isRead': false, 'timestamp': FieldValue.serverTimestamp(),
    });
    List<String> ids = [myId, widget.sellerId];
    ids.sort();
    await FirebaseFirestore.instance.collection('chats').doc(ids.join("_")).set({
      'lastMessage': type == 'text' ? text : (type == 'location' ? "Shared a location" : 'Sent an attachment'),
      'timestamp': FieldValue.serverTimestamp(),
      'lastSenderId': myId,
      'isRead': false,
      'users': ids,
      'propertyId': widget.propertyId,
    }, SetOptions(merge: true));
    _msgController.clear();
  }

  // --- UI COMPONENTS ---

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 25, runSpacing: 20,
          children: [
            _menuIcon(Icons.insert_drive_file, "Document", Colors.deepPurple, () { Navigator.pop(c); _pickFile(); }),
            _menuIcon(Icons.image, "Gallery", Colors.pink, () { Navigator.pop(c); _pickMedia(false); }),
            _menuIcon(Icons.location_on, "Location", Colors.green, () { Navigator.pop(c); _openMapPicker(); }),
          ],
        ),
      ),
    );
  }

  Widget _menuIcon(IconData i, String l, Color c, VoidCallback t) => InkWell(onTap: t, child: Column(children: [CircleAvatar(radius: 30, backgroundColor: c, child: Icon(i, color: Colors.white)), const SizedBox(height: 8), Text(l, style: const TextStyle(fontSize: 12))]));

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F2F5),
      appBar: _buildAppBar(),
      body: Column(children: [
        if (widget.propertyId != null) _buildPropertyHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final msgs = snapshot.data!.docs.where((doc) {
                var d = doc.data() as Map<String, dynamic>;
                return (d['senderId'] == myId && d['receiverId'] == widget.sellerId) || (d['senderId'] == widget.sellerId && d['receiverId'] == myId);
              }).toList();
              return ListView.builder(reverse: true, itemCount: msgs.length, itemBuilder: (context, i) => _buildBubble(msgs[i].data() as Map<String, dynamic>, msgs[i].id));
            },
          ),
        ),
        _buildInputArea(),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B263B), foregroundColor: Colors.white,
      title: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.sellerId).get(),
        builder: (context, snap) {
          String name = "User";
          if (snap.hasData && snap.data!.exists) name = (snap.data!.data() as Map<String, dynamic>)['name'] ?? "User";
          return Row(children: [GlobalUserDP(radius: 18, userId: widget.sellerId), const SizedBox(width: 10), Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]);
        },
      ),
    );
  }

  Widget _buildPropertyHeader() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('properties').doc(widget.propertyId).get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox();
        var d = snap.data!.data() as Map<String, dynamic>;
        return Container(margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200)), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(d['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['houseType'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), Text(d['location'], style: const TextStyle(color: Colors.grey, fontSize: 12)), Text("\$${d['monthlyPrice']}/mo", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))]))]));
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> d, String docId) {
    bool isMe = d['senderId'] == myId;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: GestureDetector(onLongPress: isMe ? () => _showDeleteDialog(docId) : null, child: Container(margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe ? const Color(0xFF1B263B) : (isDark ? const Color(0xFF161B22) : Colors.white), borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_mediaContent(d, isMe), const SizedBox(height: 4), Text(d['timestamp'] != null ? DateFormat('hh:mm a').format((d['timestamp'] as Timestamp).toDate()) : "", style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey))]))));
  }

  Widget _mediaContent(Map<String, dynamic> d, bool isMe) {
    Color tc = isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black);
    if (d['type'] == 'image') return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(d['text'], width: 200));
    if (d['type'] == 'location') return InkWell(onTap: () => launchUrl(Uri.parse(d['text'])), child: const Text("📍 View Map Location", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)));
    if (d['type'] == 'file') return InkWell(onTap: () => launchUrl(Uri.parse(d['text'])), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.description, color: tc), Text(" Document", style: TextStyle(color: tc))]));
    if (d['type'] == 'audio') {
      bool isPlaying = _playingUrl == d['text'];
      return Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: tc, size: 35), onPressed: () { if (isPlaying) { audioPlayer.pause(); setState(() => _playingUrl = null); } else { audioPlayer.play(UrlSource(d['text'])); setState(() => _playingUrl = d['text']); } }), if (isPlaying) SizedBox(width: 100, child: Slider(activeColor: Colors.amber, value: _position.inSeconds.toDouble(), max: _duration.inSeconds.toDouble(), onChanged: (v) => audioPlayer.seek(Duration(seconds: v.toInt())))) else Text("Voice Note", style: TextStyle(color: tc))]);
    }
    return Text(d['text'] ?? "", style: TextStyle(color: tc, fontSize: 16));
  }

  Widget _buildInputArea() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(padding: const EdgeInsets.all(10), color: isDark ? const Color(0xFF161B22) : Colors.white,
        child: Row(children: [
          if (_isRecording) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => _isRecording = false); }),
          Expanded(child: Container(decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(25)),
              child: Row(children: [
                const SizedBox(width: 10),
                Expanded(child: _isRecording ? Text("Recording: ${_formatTimer(_recordDuration)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : TextField(controller: _msgController, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: const InputDecoration(hintText: "Message", border: InputBorder.none, contentPadding: EdgeInsets.only(left: 10)))),
                IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: _showMenu),
                if (!_isRecording && !_isTyping) IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: () => _pickMedia(true)),
              ]))),
          const SizedBox(width: 5),
          GestureDetector(onTap: _isTyping ? () => _sendMessage(text: _msgController.text) : (_isRecording ? _stopAndSend : _startRecording), child: CircleAvatar(backgroundColor: const Color(0xFF1B263B), child: Icon(_isTyping ? Icons.send : (_isRecording ? Icons.stop : Icons.mic), color: Colors.white)))
        ]));
  }

  void _showDeleteDialog(String id) { showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Unsend Message?"), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("No")), TextButton(onPressed: () { FirebaseFirestore.instance.collection('messages').doc(id).delete(); Navigator.pop(c); }, child: const Text("Yes"))])); }
}