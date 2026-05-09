import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalUserDP extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;
  final String? userId; // Added this property

  const GlobalUserDP({super.key, this.radius = 16, this.onTap, this.userId});

  @override
  Widget build(BuildContext context) {
    // If no userId is passed, it defaults to the logged-in user
    final String targetUid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    if (targetUid.isEmpty) {
      return CircleAvatar(radius: radius, backgroundColor: Colors.grey);
    }

    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(targetUid).snapshots(),
        builder: (context, snapshot) {
          String name = "User";
          String photoUrl = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? "User";
            photoUrl = data['photoUrl'] ?? "";
          }

          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFF1B263B),
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : NetworkImage("https://ui-avatars.com/api/?name=$name&background=1B263B&color=fff") as ImageProvider,
          );
        },
      ),
    );
  }
}