import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/global_user_dp.dart';
import '../models/property.dart';
import 'settings_screen.dart';
import 'saved_screen.dart';
import 'user_listings_screen.dart';
import 'edit_profile_screen.dart';
import 'search_users_screen.dart';
import 'users_list_screen.dart';
import 'chat_detail_screen.dart';
import 'details_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color navyBlue = const Color(0xFF1B263B);

  Future<void> _handleRefresh() async => await Future.delayed(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = userData['name'] ?? "User", role = userData['role'] ?? "Tenant";
        bool isLandlord = role == "Landlord";

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: navyBlue,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      floating: true, pinned: true, elevation: 0,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : navyBlue)),
                      actions: [
                        IconButton(icon: Icon(Icons.person_add_alt_1_outlined, color: isDark ? Colors.white : navyBlue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SearchUsersScreen()))),
                        IconButton(icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : navyBlue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(children: [
                        const SizedBox(height: 10), const GlobalUserDP(radius: 60), const SizedBox(height: 15),
                        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        Text(role, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 25),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          if (isLandlord) _buildStat(context, user!.uid, 'properties', 'Posts'),
                          _buildStat(context, user.uid, 'followers', 'Estaters'),
                          _buildStat(context, user.uid, 'following', 'Exploring'),
                        ]),
                        const SizedBox(height: 25),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userData: userData))), style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.grey[100], elevation: 0, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Edit Profile", style: TextStyle(color: isDark ? Colors.white : Colors.black)))),
                        const SizedBox(height: 20),
                      ]),
                    ),
                    SliverPersistentHeader(pinned: true, delegate: _SliverAppBarDelegate(
                      TabBar(
                          indicatorColor: navyBlue, labelColor: isDark ? Colors.white : navyBlue, unselectedLabelColor: Colors.grey,
                          tabs: isLandlord
                              ? const [Tab(icon: Icon(Icons.grid_view_rounded), text: "Listings"), Tab(icon: Icon(Icons.chat_bubble_outline), text: "Contacted"), Tab(icon: Icon(Icons.calendar_month_outlined), text: "Bookings")]
                              : const [Tab(icon: Icon(Icons.bookmark_outline), text: "Saved"), Tab(icon: Icon(Icons.chat_bubble_outline), text: "Contacted"), Tab(icon: Icon(Icons.calendar_month_outlined), text: "Bookings")]
                      ),
                      Theme.of(context).scaffoldBackgroundColor,
                    )),
                  ];
                },
                body: TabBarView(
                  children: isLandlord
                      ? [
                    const UserListingsScreen(), // CORRECTED: Landlord Tab 1
                    ContactedLandlordsTab(currentUserId: user!.uid),
                    BookedViewingsTab(currentUserId: user.uid, isLandlord: true)
                  ]
                      : [
                    const SavedScreen(), // CORRECTED: Tenant Tab 1
                    ContactedLandlordsTab(currentUserId: user!.uid),
                    BookedViewingsTab(currentUserId: user.uid, isLandlord: false)
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, String uid, String collection, String label) {
    Stream<QuerySnapshot> stream = (collection == 'properties') ? FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: uid).snapshots() : FirebaseFirestore.instance.collection('users').doc(uid).collection(collection).snapshots();
    return InkWell(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (c) => UsersListScreen(userId: uid, title: label, collectionName: collection))); }, child: StreamBuilder<QuerySnapshot>(stream: stream, builder: (context, snap) { String value = snap.hasData ? snap.data!.docs.length.toString() : "0"; return Column(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))]); }));
  }
}

class ContactedLandlordsTab extends StatelessWidget {
  final String currentUserId;
  const ContactedLandlordsTab({super.key, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').where('users', arrayContains: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No landlords contacted yet", style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(10), itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var chat = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String partnerId = (chat['users'] as List).firstWhere((id) => id != currentUserId, orElse: () => currentUserId);
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();
                var d = userSnap.data!.data() as Map<String, dynamic>?;
                return Card(color: Theme.of(context).cardColor, margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: GlobalUserDP(radius: 20, userId: partnerId), title: Text(d?['name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(chat['lastMessage'] ?? "New Inquiry", maxLines: 1), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: partnerId)))));
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
  final bool isLandlord;
  const BookedViewingsTab({super.key, required this.currentUserId, required this.isLandlord});

  void _confirmAction(BuildContext context, String docId, String status) {
    String actionText = status == "Approved" ? "Approve" : status == "Rejected" ? "Reject" : "Cancel";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$actionText Booking?", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to $actionText this viewing request?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': status});
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B263B)),
            child: Text("Yes, $actionText"),
          ),
        ],
      ),
    );
  }

  void _deleteBookingRecord(BuildContext context, String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record cleared.")));
    }
  }

  void _openHouseDetails(BuildContext context, String propertyId) async {
    var doc = await FirebaseFirestore.instance.collection('properties').doc(propertyId).get();
    if (doc.exists && context.mounted) {
      Property p = Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: p)));
    }
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('bookings');
    query = isLandlord ? query.where('landlordId', isEqualTo: currentUserId) : query.where('tenantId', isEqualTo: currentUserId);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No bookings found", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var booking = doc.data() as Map<String, dynamic>;
            String status = booking['status'] ?? "Pending";
            String propertyId = booking['propertyId'] ?? "";
            String tenantId = booking['tenantId'] ?? "";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('properties').doc(propertyId).get(),
              builder: (context, pSnap) {
                bool isDeleted = pSnap.hasData && !pSnap.data!.exists;
                String propertyName = isDeleted ? "Listing Removed" : (booking['propertyName'] ?? "Property");

                return Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                  child: InkWell(
                    onTap: isDeleted ? null : () => _openHouseDetails(context, propertyId),
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 50, height: 50, color: Colors.grey[200],
                                  child: Icon(isDeleted ? Icons.delete_outline : Icons.home, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(propertyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDeleted ? Colors.redAccent : null)),
                                Text("${booking['date']} @ ${booking['time'] ?? 'TBD'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ])),
                              _statusBadge(status),
                            ],
                          ),
                          const Divider(height: 30),
                          Row(
                            children: [
                              GlobalUserDP(radius: 15, userId: isLandlord ? tenantId : booking['landlordId']),
                              const SizedBox(width: 10),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(isLandlord ? tenantId : booking['landlordId']).get(),
                                builder: (context, uSnap) {
                                  String uName = "User";
                                  if (uSnap.hasData && uSnap.data!.exists) uName = (uSnap.data!.data() as Map<String, dynamic>)['name'] ?? "User";
                                  return Text(isLandlord ? "Requested by: $uName" : "Host: $uName", style: const TextStyle(fontSize: 13, color: Colors.blueGrey));
                                },
                              ),
                              const Spacer(),
                              if (!isDeleted)
                                const Text("View Details", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold))
                              else
                                TextButton.icon(
                                  onPressed: () => _deleteBookingRecord(context, doc.id),
                                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 14),
                                  label: const Text("Clear Record", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),

                          if (isLandlord && status == "Pending" && !isDeleted) ...[
                            const SizedBox(height: 15),
                            Row(children: [
                              Expanded(child: OutlinedButton(onPressed: () => _confirmAction(context, doc.id, "Rejected"), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)), child: const Text("Reject", style: TextStyle(color: Colors.red)))),
                              const SizedBox(width: 10),
                              Expanded(child: ElevatedButton(onPressed: () => _confirmAction(context, doc.id, "Approved"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B263B)), child: const Text("Approve", style: TextStyle(color: Colors.white)))),
                            ]),
                          ] else if (!isLandlord && (status == "Pending" || status == "Approved") && !isDeleted)
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                    onPressed: () => _confirmAction(context, doc.id, "Cancelled"),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                                    child: const Text("Cancel Request", style: TextStyle(color: Colors.red))),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    if (status == "Approved") color = Colors.green;
    if (status == "Rejected" || status == "Cancelled") color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);
  final TabBar _tabBar;
  final Color backgroundColor;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Material(color: backgroundColor, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}