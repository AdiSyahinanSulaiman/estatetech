import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/global_user_dp.dart';
import '../models/property.dart';
import 'chat_detail_screen.dart';
import 'details_screen.dart';
import 'users_list_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;
  const ViewProfileScreen({super.key, required this.userId});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  final Color navyBlue = const Color(0xFF1B263B);
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  void _checkFollowStatus() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(myId).collection('following').doc(widget.userId).get();
    if (mounted) setState(() => isFollowing = doc.exists);
  }

  void _toggleFollow() async {
    var followingRef = FirebaseFirestore.instance.collection('users').doc(myId).collection('following').doc(widget.userId);
    var followersRef = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('followers').doc(myId);

    if (isFollowing) {
      await followingRef.delete();
      await followersRef.delete();
    } else {
      await followingRef.set({'timestamp': Timestamp.now()});
      await followersRef.set({'timestamp': Timestamp.now()});
    }
    setState(() => isFollowing = !isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = userData['name'] ?? "User";
        String role = userData['role'] ?? "Tenant";
        bool isLandlord = role == "Landlord";

        return DefaultTabController(
          length: isLandlord ? 1 : 0,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true, floating: true, elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    leading: IconButton(icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : navyBlue), onPressed: () => Navigator.pop(context)),
                    title: Text(name, style: TextStyle(color: isDark ? Colors.white : navyBlue, fontWeight: FontWeight.bold)),
                  ),
                  SliverToBoxAdapter(
                    child: Column(children: [
                      const SizedBox(height: 10),
                      GlobalUserDP(radius: 60, userId: widget.userId),
                      const SizedBox(height: 15),
                      Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      Text(role, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 25),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        if (isLandlord) _buildStat(context, widget.userId, 'properties', 'Posts'),
                        _buildStat(context, widget.userId, 'followers', 'Estaters'),
                        _buildStat(context, widget.userId, 'following', 'Exploring'),
                      ]),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing ? Colors.grey[200] : navyBlue,
                                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              child: Text(isFollowing ? "Following" : "Follow", style: TextStyle(color: isFollowing ? Colors.black : Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(sellerId: widget.userId))),
                              style: OutlinedButton.styleFrom(side: BorderSide(color: navyBlue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text("Message", style: TextStyle(color: navyBlue)),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
                  if (isLandlord)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          indicatorColor: navyBlue, labelColor: isDark ? Colors.white : navyBlue,
                          tabs: const [Tab(icon: Icon(Icons.grid_view_rounded), text: "Listings")],
                        ),
                        Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                ];
              },
              body: isLandlord
                  ? _buildLandlordListings()
                  : Center(child: Text("No public listings available.", style: TextStyle(color: Colors.grey))),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandlordListings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var props = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.75),
          itemCount: props.length,
          itemBuilder: (context, index) {
            var p = Property.fromMap(props[index].data() as Map<String, dynamic>, props[index].id);
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(property: p))),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(p.imageUrl, fit: BoxFit.cover)),
            );
          },
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, String uid, String collection, String label) {
    Stream<QuerySnapshot> stream = (collection == 'properties')
        ? FirebaseFirestore.instance.collection('properties').where('sellerId', isEqualTo: uid).snapshots()
        : FirebaseFirestore.instance.collection('users').doc(uid).collection(collection).snapshots();

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UsersListScreen(userId: uid, title: label, collectionName: collection))),
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          String value = snap.hasData ? snap.data!.docs.length.toString() : "0";
          return Column(children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]);
        },
      ),
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