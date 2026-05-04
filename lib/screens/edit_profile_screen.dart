import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locController;
  late TextEditingController _agencyController;
  late TextEditingController _bioController;

  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? "");
    _locController = TextEditingController(text: widget.userData['location'] ?? "");
    _agencyController = TextEditingController(text: widget.userData['agency'] ?? "");
    _bioController = TextEditingController(text: widget.userData['bio'] ?? "");
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? finalPhotoUrl = widget.userData['photoUrl'];

    try {
      // 1. If a new image was picked, upload it to Storage
      if (_imageFile != null) {
        var ref = FirebaseStorage.instance.ref().child('user_dps').child('$uid.jpg');
        await ref.putFile(_imageFile!);
        finalPhotoUrl = await ref.getDownloadURL();
      }

      // 2. Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locController.text.trim(),
        'agency': _agencyController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': finalPhotoUrl, // Save the real URL
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [TextButton(onPressed: _saveProfile, child: const Text("Save", style: TextStyle(color: Color(0xFF1B263B), fontWeight: FontWeight.bold)))],
      ),
      body: _isSaving ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.userData['photoUrl'] != null
                          ? NetworkImage(widget.userData['photoUrl'])
                          : NetworkImage("https://ui-avatars.com/api/?name=${_nameController.text}&background=0D8ABC&color=fff")) as ImageProvider,
                    ),
                    const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Color(0xFF1B263B), child: Icon(Icons.camera_alt, size: 15, color: Colors.white))),
                  ]),
                ),
                const SizedBox(height: 10),
                const Text("Tap to Change Photo", style: TextStyle(color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 30),
            _inputField("Full Name", Icons.person_outline, _nameController),
            _inputField("Phone Number", Icons.phone_outlined, _phoneController),
            _inputField("Location", Icons.location_on_outlined, _locController),
            _inputField("Company/Agency", Icons.business_outlined, _agencyController),
            _inputField("Bio", Icons.info_outline, _bioController, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)))),
      ]),
    );
  }
}