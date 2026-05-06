import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/global_user_dp.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: navyBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: navyBlue, fontWeight: FontWeight.bold),
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
                    "No one here yet",
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
              // The doc ID is the UID of the user to display
              String userUid = snapshot.data!.docs[index].id;

              return UserTile(uid: userUid);
            },
          );
        },
      ),
    );
  }
}

// Sub-widget to fetch individual user details (Name, Photo, Role)
class UserTile extends StatelessWidget {
  final String uid;
  const UserTile({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: userData['photoUrl'] != null
                ? NetworkImage(userData['photoUrl'])
                : null,
            child: userData['photoUrl'] == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          title: Text(
            userData['name'] ?? "EstateTech User",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(userData['role'] ?? "Tenant"),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("View", style: TextStyle(fontSize: 12)),
          ),
          onTap: () {
            // Logic to view this specific user's profile
          },
        );
      },
    );
  }
}