import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/global_user_dp.dart';
import 'view_profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  String _searchQuery = "";
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  final Color navyBlue = const Color(0xFF1B263B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : navyBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Find Connections", style: TextStyle(color: isDark ? Colors.white : navyBlue, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase().trim()),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey),
                  hintText: "Type a name to search...",
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(child: Icon(Icons.person_search_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey[200]))
                : _buildSearchResults(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var users = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery) && doc.id != myId;
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            String userId = users[index].id;
            String name = users[index]['name'] ?? "User";
            return ListTile(
              leading: GlobalUserDP(radius: 20, userId: userId),
              title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ViewProfileScreen(userId: userId))),
            );
          },
        );
      },
    );
  }
}