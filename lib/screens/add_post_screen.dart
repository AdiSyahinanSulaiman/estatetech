import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'map_picker_screen.dart';

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

  List<File> _pickedImages = [];
  LatLng? _pickedCoordinates;
  String _type = 'Detached';
  String _listingType = 'Rent';
  int rooms = 0, baths = 0, wetK = 0, dryK = 0, livingR = 0;
  final Color navy = const Color(0xFF1B263B);
  bool _isProcessing = false;

  // --- MASTER POOL OF 15 HIGH-QUALITY HOUSE IMAGES ---
  final List<String> _placeholderPool = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=1000',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=1000',
    'https://images.unsplash.com/photo-1600607687940-47a04b629571?q=80&w=1000',
    'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?q=80&w=1000',
    'https://images.unsplash.com/photo-1570129477492-45c003edd2be?q=80&w=1000',
    'https://images.unsplash.com/photo-1598228723793-52759bba239c?q=80&w=1000',
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=1000',
    'https://images.unsplash.com/photo-1572120339559-7f45198a7735?q=80&w=1000',
    'https://images.unsplash.com/photo-1576941089067-2de3c901e126?q=80&w=1000',
    'https://images.unsplash.com/photo-1518780664697-55e3ad937233?q=80&w=1000',
    'https://images.unsplash.com/photo-1448630360428-65456885c650?q=80&w=1000',
    'https://images.unsplash.com/photo-1513584684031-43d10ad60383?q=80&w=1000',
    'https://images.unsplash.com/photo-1516455590571-18256e5bb9ff?q=80&w=1000',
  ];

  Future<void> _pickImages() async {
    if (_isProcessing) return;
    final List<XFile> images = await ImagePicker().pickMultiImage(imageQuality: 50);
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages = [..._pickedImages, ...images.map((x) => File(x.path))];
        if (_pickedImages.length > 10) _pickedImages = _pickedImages.sublist(0, 10);
      });
    }
  }

  void _selectLocationOnMap() async {
    final LatLng? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerScreen()));
    if (result != null) setState(() { _pickedCoordinates = result; });
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

      List<String> imageUrls = [];

      // A. If user picked images, upload them
      if (_pickedImages.isNotEmpty) {
        for (var image in _pickedImages) {
          var ref = FirebaseStorage.instance.ref().child('properties').child('${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}.jpg');
          await ref.putFile(image);
          String url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }
      // B. If NO images picked, generate a dynamic placeholder gallery
      else {
        List<String> pool = List.from(_placeholderPool);
        pool.shuffle(); // Randomize the list
        imageUrls = pool.take(4).toList(); // Take 4 unique images
      }

      await FirebaseFirestore.instance.collection('properties').add({
        'houseType': _type,
        'listingType': _listingType,
        'location': _loc.text.trim(),
        'latitude': _pickedCoordinates?.latitude ?? 4.9031,
        'longitude': _pickedCoordinates?.longitude ?? 114.9149,
        'monthlyPrice': double.parse(_monthP.text),
        'totalPrice': double.parse(_totalP.text),
        'sqft': int.parse(_sqft.text.isEmpty ? "0" : _sqft.text),
        'description': _desc.text.trim(),
        'rooms': rooms, 'baths': baths, 'wetKitchen': wetK, 'dryKitchen': dryK, 'livingRoom': livingR,
        'sellerId': uid, 'sellerName': name, 'sellerPhoto': photo,
        'imageUrl': imageUrls[0],
        'galleryUrls': imageUrls,
        'virtualTourUrl': _tourUrlController.text.trim(),
        'createdAt': Timestamp.now(),
      });
      widget.onPostComplete();
    } catch (e) { setState(() => _isProcessing = false); }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Create Post", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ]),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImages,
              child: CustomPaint(
                painter: DashedRectPainter(color: Colors.grey.shade400),
                child: Container(
                  width: double.infinity, height: 160,
                  child: _pickedImages.isEmpty
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.blueGrey[300]), const SizedBox(height: 10), const Text("Upload property images", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)), Text("Upload the property you want to sell/rent", style: TextStyle(fontSize: 10, color: Colors.grey[400]))])
                      : ListView.builder(scrollDirection: Axis.horizontal, itemCount: _pickedImages.length, itemBuilder: (context, index) => Padding(padding: const EdgeInsets.all(8.0), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_pickedImages[index], width: 120, height: 120, fit: BoxFit.cover)))),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text("Virtual 360° Tour (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            CustomPaint(
              painter: DashedRectPainter(color: Colors.grey.shade300),
              child: Container(padding: const EdgeInsets.all(15), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)), child: Icon(Icons.videocam_outlined, color: navy, size: 28)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Add 360° Virtual Tour", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const Text("Paste link to your virtual tour", style: TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 10), TextField(controller: _tourUrlController, decoration: InputDecoration(hintText: "https://your-link.com", hintStyle: const TextStyle(fontSize: 12), filled: true, fillColor: isDark ? Colors.white10 : Colors.grey[50], isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))]))])),
            ),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _type, dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                items: ['Detached', 'Semi-Detached', 'Apartment', 'Terrace', 'Bungalow'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: _isProcessing ? null : (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: "Property Type", border: OutlineInputBorder()),
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                value: _listingType, dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                items: ['Rent', 'Sale'].map((t) => DropdownMenuItem(value: t, child: Text("For $t"))).toList(),
                onChanged: _isProcessing ? null : (v) => setState(() => _listingType = v!),
                decoration: const InputDecoration(labelText: "Listing For", border: OutlineInputBorder()),
              )),
            ]),
            const SizedBox(height: 15),
            ListTile(onTap: _isProcessing ? null : _selectLocationOnMap, leading: Icon(Icons.map_outlined, color: navy), title: const Text("Select Location on Map", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(_pickedCoordinates == null ? "Not set" : "GPS Captured ✅"), tileColor: isDark ? Colors.white10 : Colors.grey[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            TextField(controller: _loc, decoration: const InputDecoration(labelText: "Location Area Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(children: [Expanded(child: TextField(controller: _monthP, decoration: const InputDecoration(labelText: "Monthly \$", border: OutlineInputBorder()), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: _sqft, decoration: const InputDecoration(labelText: "Sqft Area", border: OutlineInputBorder()), keyboardType: TextInputType.number))]),
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
            ElevatedButton(onPressed: _isProcessing ? null : _submit, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(_isProcessing ? "Publishing..." : "Publish Listing", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
  Widget _count(String l, int v, Function(int) c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Row(children: [IconButton(onPressed: _isProcessing ? null : () => c(v > 0 ? v - 1 : 0), icon: const Icon(Icons.remove_circle_outline)), Text("$v", style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(onPressed: _isProcessing ? null : () => c(v + 1), icon: const Icon(Icons.add_circle_outline))])]);
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  DashedRectPainter({required this.color});
  @override void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3;
    final paint = Paint()..color = color ..strokeWidth = 1 ..style = PaintingStyle.stroke;
    RRect rect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(15));
    Path path = Path()..addRRect(rect);
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}