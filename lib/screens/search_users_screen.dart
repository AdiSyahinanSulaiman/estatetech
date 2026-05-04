import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});
  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  String query = "";
  final myId = FirebaseAuth.instance.currentUser!.uid;

  void _toggleFollow(String targetUserId, bool isFollowing) async {
    var myFollowing = FirebaseFirestore.instance.collection('users').doc(myId).collection('following').doc(targetUserId);
    var theirFollowers = FirebaseFirestore.instance.collection('users').doc(targetUserId).collection('followers').doc(myId);

    if (isFollowing) {
      await myFollowing.delete();
      await theirFollowers.delete();
    } else {
      await myFollowing.set({'timestamp': Timestamp.now()});
      await theirFollowers.set({'timestamp': Timestamp.now()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Find Connections"), backgroundColor: Colors.white, elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (v) => setState(() => query = v.toLowerCase()),
              decoration: const InputDecoration(hintText: "Search by name...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var users = snapshot.data!.docs.where((doc) => doc.id != myId && doc['name'].toString().toLowerCase().contains(query)).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    var userData = users[i].data() as Map<String, dynamic>;
                    var userId = users[i].id;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(myId).collection('following').doc(userId).snapshots(),
                      builder: (context, followSnap) {
                        bool isFollowing = followSnap.hasData && followSnap.data!.exists;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=${userData['name']}&background=random")),
                          title: Text(userData['name']),
                          trailing: ElevatedButton(
                            onPressed: () => _toggleFollow(userId, isFollowing),
                            style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? Colors.grey : const Color(0xFF1B263B)),
                            child: Text(isFollowing ? "Connected" : "Connect", style: const TextStyle(color: Colors.white)),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}