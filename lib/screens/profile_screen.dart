import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/global_user_dp.dart';
import 'settings_screen.dart';
import 'saved_screen.dart';
import 'user_listings_screen.dart';
import 'edit_profile_screen.dart';
import 'search_users_screen.dart';
import 'users_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color navyBlue = const Color(0xFF1B263B);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = userData['name'] ?? "User";
        String role = userData['role'] ?? "Tenant";
        bool isLandlord = role == "Landlord";

        int tabCount = isLandlord ? 2 : 3;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    title: Text(
                      isLandlord ? 'Business Profile' : 'Tenant Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.person_add_alt_1_outlined, color: navyBlue),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SearchUsersScreen())),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: navyBlue),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen())),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        GlobalUserDP(radius: 60),
                        const SizedBox(height: 15),
                        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(role, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (isLandlord) _buildStat(context, user!.uid, 'properties', 'Posts'),
                            _buildStat(context, user!.uid, 'followers', 'Estaters'),
                            _buildStat(context, user!.uid, 'following', 'Exploring'),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => EditProfileScreen(userData: userData))
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: const Text("Edit Profile", style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        indicatorColor: navyBlue,
                        labelColor: navyBlue,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        tabs: isLandlord
                            ? const [
                          Tab(icon: Icon(Icons.grid_view_rounded), text: "Listings"),
                          Tab(icon: Icon(Icons.bookmark_outline), text: "Saved"),
                        ]
                            : const [
                          Tab(icon: Icon(Icons.bookmark_outline), text: "Saved"),
                          Tab(icon: Icon(Icons.chat_bubble_outline), text: "Contacted"),
                          Tab(icon: Icon(Icons.calendar_month_outlined), text: "Bookings"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: isLandlord
                    ? [
                  const UserListingsScreen(),
                  const SavedScreen(),
                ]
                    : [
                  const SavedScreen(),
                  ContactedLandlordsTab(currentUserId: user!.uid),
                  BookedViewingsTab(currentUserId: user.uid),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, String uid, String collection, String label) {
    Stream<QuerySnapshot> stream = (collection == 'properties')
        ? FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: uid).snapshots()
        : FirebaseFirestore.instance.collection('users').doc(uid).collection(collection).snapshots();

    return InkWell(
      onTap: () {
        if (collection != 'properties') {
          Navigator.push(context, MaterialPageRoute(builder: (c) => UsersListScreen(userId: uid, title: label, collectionName: collection)));
        }
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          String value = snap.hasData ? snap.data!.docs.length.toString() : "0";
          return Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          );
        },
      ),
    );
  }
}

class ContactedLandlordsTab extends StatelessWidget {
  final String currentUserId;
  const ContactedLandlordsTab({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // MENTOR TIP: Removed .orderBy() to prevent buffering.
      // To add it back, check your Debug Console for a link to create an index.
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No landlords contacted yet", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var chat = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF1B263B), child: Icon(Icons.person, color: Colors.white)),
                title: Text(chat['landlordName'] ?? "Landlord"),
                subtitle: Text(chat['lastMessage'] ?? "New Inquiry", maxLines: 1),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}

class BookedViewingsTab extends StatelessWidget {
  final String currentUserId;
  const BookedViewingsTab({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('tenantId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No viewings booked yet", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              color: const Color(0xFFF8F9FA),
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              child: ListTile(
                title: Text(booking['propertyName'] ?? "Property", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Date: ${booking['date']}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1B263B), borderRadius: BorderRadius.circular(20)),
                  child: Text(booking['status'] ?? "Pending", style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            );
          },
        );
      },
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