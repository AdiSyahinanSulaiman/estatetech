import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/global_user_dp.dart';
import 'settings_screen.dart';
import 'saved_screen.dart';
import 'user_listings_screen.dart';
import 'edit_profile_screen.dart';
import 'search_users_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. THE APP BAR
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                actions: [
                  IconButton(icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.black),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SearchUsersScreen()))),
                  IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))),
                ],
              ),

              // 2. THE SCROLLABLE HEADER (Avatar, Stats, Edit Button)
              SliverToBoxAdapter(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    var userData = snapshot.data!.data() as Map<String, dynamic>;
                    String name = userData['name'] ?? "User";
                    String role = userData['role'] ?? "Tenant";

                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        // Large Profile Photo
                        GlobalUserDP(radius: 60),
                        const SizedBox(height: 15),
                        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(role, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 25),

                        // STATS (Estaters & Exploring)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(user!.uid, 'properties', 'Posts'),
                            _buildStat(user.uid, 'followers', 'Estaters'),
                            _buildStat(user.uid, 'following', 'Exploring'),
                          ],
                        ),

                        const SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userData: userData))),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], elevation: 0, minimumSize: const Size(double.infinity, 50)),
                            child: const Text("Edit Profile", style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),

              // 3. THE STICKY TAB BAR
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    indicatorColor: Color(0xFF1B263B),
                    labelColor: Color(0xFF1B263B),
                    unselectedLabelColor: Colors.grey,
                    tabs: [Tab(icon: Icon(Icons.grid_view_rounded)), Tab(icon: Icon(Icons.bookmark_outline))],
                  ),
                ),
              ),
            ];
          },
          // 4. THE TAB CONTENT
          body: const TabBarView(
            children: [
              UserListingsScreen(),
              SavedScreen(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String uid, String collection, String label) {
    Stream<QuerySnapshot> stream = (collection == 'properties')
        ? FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: uid).snapshots()
        : FirebaseFirestore.instance.collection('users').doc(uid).collection(collection).snapshots();

    return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          String value = snap.hasData ? snap.data!.docs.length.toString() : "0";
          return Column(children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ]);
        }
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}