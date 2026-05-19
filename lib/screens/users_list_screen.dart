import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/global_user_dp.dart';
import 'view_profile_screen.dart'; // FIXED: Added this import to enable stalking

class UsersListScreen extends StatelessWidget {
  final String userId;
  final String title; // "Estaters" or "Exploring"
  final String collectionName; // "followers" or "following"

  const UsersListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.collectionName,
  });

  @override
  Widget build(BuildContext context) {
    const Color navyBlue = Color(0xFF1B263B);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : navyBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(color: isDark ? Colors.white : navyBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(collectionName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No $title yet",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              String userUid = snapshot.data!.docs[index].id;
              return UserTile(uid: userUid);
            },
          );
        },
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final String uid;
  const UserTile({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();

        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        String name = userData['name'] ?? "User";
        String role = userData['role'] ?? "Tenant";

        return ListTile(
          // FIXED: Using GlobalUserDP with userId for live sync
          leading: GlobalUserDP(radius: 22, userId: uid),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(role, style: const TextStyle(color: Colors.grey)),
          trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          // --- THE STALK LOGIC: TAP TO VIEW PROFILE ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProfileScreen(userId: uid),
              ),
            );
          },
        );
      },
    );
  }
}