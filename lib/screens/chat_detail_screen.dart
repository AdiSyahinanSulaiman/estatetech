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

  bool _isTyping = false;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _playingUrl;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _msgController.addListener(() {
      if (mounted) setState(() => _isTyping = _msgController.text.isNotEmpty);
    });
    // Listen to audio progress for the slider
    audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    audioPlayer.onPlayerComplete.listen((_) => setState(() { _playingUrl = null; _position = Duration.zero; }));
  }

  @override
  void dispose() {
    _timer?.cancel();
    audioRecorder.dispose();
    audioPlayer.dispose();
    _msgController.dispose();
    super.dispose();
  }

  // --- WHATSAPP TIMER FORMAT ---
  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString();
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  // --- ACTIONS ---
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

  void _cancelRecording() async {
    _timer?.cancel();
    await audioRecorder.stop();
    setState(() => _isRecording = false);
  }

  void _sendLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String url = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
      _sendMessage(text: url, type: 'location');
      Navigator.pop(context);
    }
  }

  void _uploadFile(File file, String type) async {
    String name = "${DateTime.now().millisecondsSinceEpoch}";
    var ref = FirebaseStorage.instance.ref('chat/$name');
    await ref.putFile(file);
    String url = await ref.getDownloadURL();
    _sendMessage(text: url, type: type);
  }

  void _sendMessage({required String text, String type = 'text'}) {
    if (text.isEmpty) return;
    FirebaseFirestore.instance.collection('messages').add({
      'text': text, 'type': type, 'senderId': myId, 'receiverId': widget.sellerId,
      'isRead': false, 'timestamp': Timestamp.now(),
    });
    _msgController.clear();
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: _buildAppBar(),
      body: Column(children: [
        if (widget.propertyId != null) _buildPropertyHeader(),
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
                itemBuilder: (context, i) {
                  var d = msgs[i].data() as Map<String, dynamic>;
                  bool isMe = d['senderId'] == myId;
                  return GestureDetector(
                    onLongPress: isMe ? () => _showDeleteDialog(msgs[i].id) : null,
                    child: _buildBubble(d, isMe),
                  );
                },
              );
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
          return Row(children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$name&background=random")),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Row(children: [
                CircleAvatar(radius: 4, backgroundColor: Colors.green),
                SizedBox(width: 4),
                Text("Online", style: TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
            ]),
          ]);
        },
      ),
    );
  }

  Widget _buildPropertyHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('properties').doc(widget.propertyId).get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox();
        var d = snap.data!.data() as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(d['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['houseType'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(d['location'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text("\$${d['monthlyPrice']}/mo", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ])),
          ]),
        );
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> d, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1B263B) : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _mediaContent(d, isMe),
          const SizedBox(height: 4),
          Text(d['timestamp'] != null ? DateFormat('hh:mm a').format((d['timestamp'] as Timestamp).toDate()) : "", style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _mediaContent(Map<String, dynamic> d, bool isMe) {
    Color tc = isMe ? Colors.white : Colors.black;
    if (d['type'] == 'image') return GestureDetector(onTap: () => _viewImage(d['text']), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(d['text'], width: 200)));

    if (d['type'] == 'audio') {
      bool isPlaying = _playingUrl == d['text'];
      return Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: tc, size: 35), onPressed: () {
          if (isPlaying) { audioPlayer.pause(); setState(() => _playingUrl = null); }
          else { audioPlayer.play(UrlSource(d['text'])); setState(() => _playingUrl = d['text']); }
        }),
        if (isPlaying) SizedBox(width: 100, child: Slider(value: _position.inSeconds.toDouble(), max: _duration.inSeconds.toDouble(), onChanged: (v) => audioPlayer.seek(Duration(seconds: v.toInt()))))
        else Text("Voice Note", style: TextStyle(color: tc)),
      ]);
    }

    if (d['type'] == 'file') return InkWell(onTap: () => launchUrl(Uri.parse(d['text']), mode: LaunchMode.externalApplication), child: Row(children: [Icon(Icons.insert_drive_file, color: tc), const Text(" View Document", style: TextStyle(decoration: TextDecoration.underline))]));
    if (d['type'] == 'location') return InkWell(onTap: () => launchUrl(Uri.parse(d['text']), mode: LaunchMode.externalApplication), child: const Text("📍 View Location", style: TextStyle(color: Colors.blue)));

    return Text(d['text'], style: TextStyle(color: tc, fontSize: 16));
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10), color: Colors.white,
      child: Row(children: [
        if (_isRecording) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _cancelRecording),
        Expanded(child: Container(
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
          child: Row(children: [
            const SizedBox(width: 10),
            Expanded(child: _isRecording
                ? Text("Recording: ${_formatTimer(_recordDuration)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                : TextField(controller: _msgController, decoration: const InputDecoration(hintText: "Message", border: InputBorder.none, contentPadding: EdgeInsets.only(left: 10)))),
            if (!_isRecording) IconButton(icon: const Icon(Icons.attach_file), onPressed: _showMenu),
            if (!_isRecording && !_isTyping) IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _pickMedia(true)),
          ]),
        )),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: _isTyping ? () => _sendMessage(text: _msgController.text) : (_isRecording ? _stopAndSend : _startRecording),
          child: CircleAvatar(backgroundColor: const Color(0xFF1B263B), child: Icon(_isTyping ? Icons.send : (_isRecording ? Icons.stop : Icons.mic), color: Colors.white)),
        ),
      ]),
    );
  }

  void _showMenu() {
    showModalBottomSheet(context: context, builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.image), title: const Text("Gallery"), onTap: () { Navigator.pop(c); _pickMedia(false); }),
      ListTile(leading: const Icon(Icons.file_present), title: const Text("Document"), onTap: () { Navigator.pop(c); _pickFile(); }),
      ListTile(leading: const Icon(Icons.location_on), title: const Text("Location"), onTap: _sendLocation),
    ]));
  }

  void _pickMedia(bool cam) async {
    final p = await ImagePicker().pickImage(source: cam ? ImageSource.camera : ImageSource.gallery, imageQuality: 50);
    if (p != null) _uploadFile(File(p.path), 'image');
  }

  void _pickFile() async {
    final r = await FilePicker.platform.pickFiles();
    if (r != null) _uploadFile(File(r.files.single.path!), 'file');
  }

  void _viewImage(String url) {
    showDialog(context: context, builder: (c) => Dialog.fullscreen(backgroundColor: Colors.black, child: Stack(children: [Center(child: Image.network(url)), Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(c)))])));
  }

  void _showDeleteDialog(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Unsend?"), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("No")), TextButton(onPressed: () { FirebaseFirestore.instance.collection('messages').doc(id).delete(); Navigator.pop(c); }, child: const Text("Yes"))]));
  }
}