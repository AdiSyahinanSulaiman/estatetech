import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

class AddPostScreen extends StatefulWidget {
  final VoidCallback onPostStart;
  final VoidCallback onPostComplete;
  const AddPostScreen({super.key, required this.onPostStart, required this.onPostComplete});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _loc = TextEditingController();
  final TextEditingController _monthP = TextEditingController();
  final TextEditingController _totalP = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _sqft = TextEditingController();
  final TextEditingController _tourUrlController = TextEditingController();

  File? _pickedImage;
  String _type = 'Detached';
  int rooms = 0, baths = 0, wetK = 0, dryK = 0, livingR = 0;
  final Color navy = const Color(0xFF1B263B);
  bool _isProcessing = false;

  final List<String> _autoPhotos = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=1000',
  ];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) setState(() => _pickedImage = File(pickedFile.path));
  }

  Future<void> _submit() async {
    if (_loc.text.isEmpty || _monthP.text.isEmpty) return;
    setState(() => _isProcessing = true);
    widget.onPostStart();

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      var user = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String name = user.data()?['name'] ?? "Landlord";
      String photo = user.data()?['photoUrl'] ?? "";

      String finalImg = _autoPhotos[Random().nextInt(_autoPhotos.length)];
      if (_pickedImage != null) {
        var ref = FirebaseStorage.instance.ref().child('properties').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_pickedImage!);
        finalImg = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('properties').add({
        'houseType': _type,
        'location': _loc.text.trim(),
        'monthlyPrice': double.parse(_monthP.text),
        'totalPrice': double.parse(_totalP.text),
        'sqft': int.parse(_sqft.text.isEmpty ? "0" : _sqft.text),
        'description': _desc.text.trim(),
        'rooms': rooms,
        'baths': baths,
        'wetKitchen': wetK,
        'dryKitchen': dryK,
        'livingRoom': livingR,
        'sellerId': uid,
        'sellerName': name,
        'sellerPhoto': photo,
        'imageUrl': finalImg,
        'virtualTourUrl': _tourUrlController.text.isNotEmpty ? _tourUrlController.text.trim() : 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg',
        'createdAt': Timestamp.now(),
      });
      widget.onPostComplete();
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Post New Listing", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity, height: 180,
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!)),
              child: _pickedImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_pickedImage!, fit: BoxFit.cover))
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 50, color: navy.withOpacity(0.5)), const Text("Upload property images", style: TextStyle(fontWeight: FontWeight.bold))]),
            ),
          ),
          const SizedBox(height: 25),

          const Text("Virtual 360° Tour (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: navy.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Icon(Icons.view_in_ar, color: navy, size: 30),
              const SizedBox(width: 15),
              Expanded(child: TextField(controller: _tourUrlController, decoration: const InputDecoration(hintText: "Paste 360 link here", border: InputBorder.none))),
            ]),
          ),
          const SizedBox(height: 30),

          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
            items: ['Detached', 'Semi-Detached', 'Apartment', 'Terrace', 'Bungalow'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v!),
            decoration: const InputDecoration(labelText: "Property Type", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),
          TextField(controller: _loc, decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: TextField(controller: _monthP, decoration: const InputDecoration(labelText: "Monthly \$", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _sqft, decoration: const InputDecoration(labelText: "Sqft Area", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 15),
          TextField(controller: _totalP, decoration: const InputDecoration(labelText: "Full Property Price \$", border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 15),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
          const SizedBox(height: 25),

          const Text("Property Features", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          _count("Rooms", rooms, (v) => setState(() => rooms = v)),
          _count("Baths", baths, (v) => setState(() => baths = v)),
          _count("Wet Kitchen", wetK, (v) => setState(() => wetK = v)),
          _count("Dry Kitchen", dryK, (v) => setState(() => dryK = v)),
          _count("Living Room", livingR, (v) => setState(() => livingR = v)),
          const SizedBox(height: 30),

          ElevatedButton(onPressed: _isProcessing ? null : _submit, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: navy), child: Text(_isProcessing ? "Publishing..." : "Publish Listing", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _count(String l, int v, Function(int) c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Row(children: [IconButton(onPressed: () => c(v > 0 ? v - 1 : 0), icon: const Icon(Icons.remove_circle_outline)), Text("$v", style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(onPressed: () => c(v + 1), icon: const Icon(Icons.add_circle_outline))])]);
}