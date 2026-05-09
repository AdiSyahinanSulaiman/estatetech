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
import 'chat_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color navyBlue = const Color(0xFF1B263B);

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = userData['name'] ?? "User";
        String role = userData['role'] ?? "Tenant";
        bool isLandlord = role == "Landlord";

        return DefaultTabController(
          length: isLandlord ? 2 : 3,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: navyBlue,
              edgeOffset: 80,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      floating: true, pinned: true, elevation: 0,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      title: Text(isLandlord ? 'Business Profile' : 'Tenant Profile',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : navyBlue)),
                      actions: [
                        IconButton(icon: Icon(Icons.person_add_alt_1_outlined, color: isDark ? Colors.white : navyBlue),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SearchUsersScreen()))),
                        IconButton(icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : navyBlue),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const GlobalUserDP(radius: 60),
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
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userData: userData))),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text("Edit Profile", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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
                          tabs: isLandlord
                              ? const [Tab(icon: Icon(Icons.grid_view_rounded), text: "Listings"), Tab(icon: Icon(Icons.bookmark_outline), text: "Saved")]
                              : const [Tab(icon: Icon(Icons.bookmark_outline), text: "Saved"), Tab(icon: Icon(Icons.chat_bubble_outline), text: "Contacted"), Tab(icon: Icon(Icons.calendar_month_outlined), text: "Bookings")],
                        ),
                        // Background color is handled here inside the delegate
                        Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: isLandlord
                      ? [const UserListingsScreen(), const SavedScreen()]
                      : [const SavedScreen(), ContactedLandlordsTab(currentUserId: user!.uid), BookedViewingsTab(currentUserId: user.uid)],
                ),
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
          return Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))]);
        },
      ),
    );
  }
}

class ContactedLandlordsTab extends StatelessWidget {
  final String currentUserId;
  const ContactedLandlordsTab({super.key, required this.currentUserId});

  void _deleteChat(BuildContext context, String partnerId) async {
    List<String> ids = [currentUserId, partnerId];
    ids.sort();
    await FirebaseFirestore.instance.collection('chats').doc(ids.join("_")).delete();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact removed")));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').where('users', arrayContains: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No landlords contacted yet", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var chat = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            List users = chat['users'];
            String partnerId = users.firstWhere((id) => id != currentUserId);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();
                var d = userSnap.data!.data() as Map<String, dynamic>?;
                String name = d?['name'] ?? "User";

                return Card(
                  margin: const EdgeInsets.only(bottom: 10), elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200.withOpacity(0.1))),
                  child: ListTile(
                    leading: GlobalUserDP(radius: 20, userId: partnerId),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(chat['lastMessage'] ?? "New Inquiry", maxLines: 1),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: partnerId))),
                    onLongPress: () => _deleteChat(context, partnerId),
                  ),
                );
              },
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
      stream: FirebaseFirestore.instance.collection('bookings').where('tenantId', isEqualTo: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No viewings booked yet", style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10), itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              color: Theme.of(context).cardColor, margin: const EdgeInsets.only(bottom: 10), elevation: 0,
              child: ListTile(
                title: Text(booking['propertyName'] ?? "Property", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Date: ${booking['date']}"),
                trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF1B263B), borderRadius: BorderRadius.circular(20)), child: Text(booking['status'] ?? "Pending", style: const TextStyle(color: Colors.white, fontSize: 10))),
              ),
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor); // Added backgroundColor to constructor
  final TabBar _tabBar;
  final Color backgroundColor;

  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;

  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material( // This Material widget handles the background color for the TabBar
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}