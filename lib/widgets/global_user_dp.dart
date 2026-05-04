import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalUserDP extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;

  const GlobalUserDP({super.key, this.radius = 16, this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          String name = "User";
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? "User";
            photoUrl = data['photoUrl']; // Real uploaded photo
          }

          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFF1B263B),
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : NetworkImage("https://ui-avatars.com/api/?name=$name&background=0D8ABC&color=fff") as ImageProvider,
          );
        },
      ),
    );
  }
}