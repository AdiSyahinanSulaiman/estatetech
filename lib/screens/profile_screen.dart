import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
        String name = userData['name'] ?? "User";
        String role = userData['role'] ?? "Tenant";
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
                          if (isLandlord) _buildStat(context, user!.uid, 'properties', 'Posts', isDark),
                          _buildStat(context, user.uid, 'followers', 'Estaters', isDark),
                          _buildStat(context, user.uid, 'following', 'Exploring', isDark),
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
                    const UserListingsScreen(),
                    ContactedLandlordsTab(currentUserId: user!.uid),
                    BookedViewingsTab(currentUserId: user.uid, isLandlord: true)
                  ]
                      : [
                    const SavedScreen(),
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

  Widget _buildStat(BuildContext context, String uid, String collection, String label, bool isDark) {
    Stream<QuerySnapshot> stream = (collection == 'properties') ? FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: uid).snapshots() : FirebaseFirestore.instance.collection('users').doc(uid).collection(collection).snapshots();
    return InkWell(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (c) => UsersListScreen(userId: uid, title: label, collectionName: collection))); }, child: StreamBuilder<QuerySnapshot>(stream: stream, builder: (context, snap) { String value = snap.hasData ? snap.data!.docs.length.toString() : "0"; return Column(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))]); }));
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

  void _confirmAction(BuildContext context, String docId, String actionType) {
    final Color navyBlue = const Color(0xFF1B263B);

    // Determine custom text for deletion vs status update
    String title = actionType == "Delete" ? "Delete Record?" : "$actionType Booking?";
    String content = actionType == "Delete"
        ? "Are you sure you want to permanently remove this record from your history?"
        : "Are you sure you want to $actionType this viewing request?";
    String confirmBtnText = actionType == "Delete" ? "Yes, Delete" : "Yes, $actionType";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (actionType == "Delete") {
                // FIXED: Actually delete the document from Firestore
                await FirebaseFirestore.instance.collection('bookings').doc(docId).delete();
              } else {
                // Update status (Approve/Cancel)
                await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': actionType});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: actionType == "Delete" ? Colors.red : navyBlue),
            child: Text(confirmBtnText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rescheduleBooking(BuildContext context, String docId, String oldDate, String oldTime) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30))
    );
    if (pickedDate == null) return;
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (pickedTime != null) {
      String formattedDate = DateFormat('MMM dd, yyyy').format(pickedDate);
      String formattedTime = pickedTime.format(context);
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
        'status': 'Rescheduled', 'date': formattedDate, 'time': formattedTime, 'previousDate': oldDate, 'previousTime': oldTime,
      });
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
    final Color navyBlue = const Color(0xFF1B263B);
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
            bool isDeletable = status == "Cancelled" || status == "Rejected";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('properties').doc(propertyId).get(),
              builder: (context, pSnap) {
                bool isDeletedListing = pSnap.hasData && !pSnap.data!.exists;
                String propertyName = isDeletedListing ? "Listing Removed" : (booking['propertyName'] ?? "Property");
                String? imageUrl = (pSnap.hasData && pSnap.data!.exists) ? (pSnap.data!.data() as Map<String, dynamic>)['imageUrl'] : null;

                return Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                  child: InkWell(
                    onTap: isDeletedListing ? null : () => _openHouseDetails(context, propertyId),
                    // --- LONG PRESS DELETE (Calls the fixed Logic) ---
                    onLongPress: isDeletable || isDeletedListing ? () => _confirmAction(context, doc.id, "Delete") : null,
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Container(width: 50, height: 50, color: Colors.grey[200], child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.cover) : Icon(isDeletedListing ? Icons.delete_outline : Icons.home, color: Colors.grey))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(propertyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDeletedListing ? Colors.redAccent : null)),
                              if (status == "Rescheduled" && booking['previousDate'] != null) ...[
                                Text("Previous: ${booking['previousDate']} @ ${booking['previousTime']}", style: const TextStyle(color: Colors.grey, fontSize: 10, decoration: TextDecoration.lineThrough)),
                                Text("Requested: ${booking['date']} @ ${booking['time']}", style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                              ] else Text("${booking['date']} @ ${booking['time'] ?? 'TBD'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ])),
                            _statusBadge(status),
                          ]),
                          const Divider(height: 30),
                          Row(children: [
                            GlobalUserDP(radius: 15, userId: isLandlord ? tenantId : booking['landlordId']),
                            const SizedBox(width: 10),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(isLandlord ? tenantId : booking['landlordId']).get(),
                              builder: (context, uSnap) {
                                String uName = uSnap.hasData ? (uSnap.data!.data() as Map<String, dynamic>)['name'] ?? "User" : "Loading...";
                                return Text(isLandlord ? "From: $uName" : "Host: $uName", style: const TextStyle(fontSize: 13, color: Colors.blueGrey));
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.chat_bubble_outline, color: navyBlue, size: 20),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: isLandlord ? tenantId : booking['landlordId'], propertyId: propertyId)));
                              },
                            ),
                            const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                          ]),
                          if (!isDeletedListing) ...[
                            const SizedBox(height: 15),
                            if (isLandlord && status == "Pending")
                              Row(children: [
                                Expanded(child: OutlinedButton(onPressed: () => _rescheduleBooking(context, doc.id, booking['date'], booking['time'] ?? 'TBD'), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)), child: const Text("Reschedule", style: TextStyle(color: Colors.orange)))),
                                const SizedBox(width: 10),
                                Expanded(child: ElevatedButton(onPressed: () => _confirmAction(context, doc.id, "Approved"), style: ElevatedButton.styleFrom(backgroundColor: navyBlue), child: const Text("Approve", style: TextStyle(color: Colors.white)))),
                              ])
                            else if (!isLandlord && status == "Rescheduled")
                              Row(children: [
                                Expanded(child: OutlinedButton(onPressed: () => _confirmAction(context, doc.id, "Cancelled"), child: const Text("Decline", style: TextStyle(color: Colors.red)))),
                                const SizedBox(width: 10),
                                Expanded(child: ElevatedButton(onPressed: () => _confirmAction(context, doc.id, "Approved"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Accept", style: TextStyle(color: Colors.white)))),
                              ])
                            else if (!isLandlord && (status == "Pending" || status == "Approved"))
                                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _confirmAction(context, doc.id, "Cancelled"), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)), child: const Text("Cancel Request", style: TextStyle(color: Colors.red)))),
                          ],
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
    if (status == "Rescheduled") color = Colors.blue;
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