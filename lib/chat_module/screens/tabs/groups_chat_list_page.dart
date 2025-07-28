import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/screens/group_chat_create_screen.dart';
import 'package:trunriproject/chat_module/screens/group_chat_screen.dart';
import 'package:trunriproject/chat_module/components/user_tiles.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';

class GroupsChatPage extends StatefulWidget {
  const GroupsChatPage({super.key});

  @override
  State<GroupsChatPage> createState() => _GroupsChatPageState();
}

class _GroupsChatPageState extends State<GroupsChatPage>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? cachedChatList;
  String? currentEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Icon or Image
              const Icon(Icons.lock_outline_rounded,
                  size: 48, color: Colors.deepOrange),

              const SizedBox(height: 12),

              // Title
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              const Text(
                'Creating Group is a premium feature.\nSubscribe now to unlock this and more!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),

              const SizedBox(height: 16),

              // Feature Highlights
              const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Send Friend Requests'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.group_add_sharp,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Create Groups with your friends'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Post & Promote Listings'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.stars_sharp, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('And More...'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
                  // const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.workspace_premium, size: 20),
                    label: const Text('Subscribe Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.to(() => const SubscriptionScreen());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadChats() async {
    final meDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    currentEmail = meDoc.data()?['email'] as String?;

    if (currentEmail == null) return;

    final List<Map<String, dynamic>> combined = [];

    // 🔥 Only fetch groups user belongs to
    final groupsSnap = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: currentEmail)
        .get();

    for (var g in groupsSnap.docs) {
      final data = g.data();
      final lastMessageTime = data['lastMessageTime'] as Timestamp?;

      combined.add({
        'type': 'group',
        'groupId': g.id,
        'name': data['groupName']?.toString() ?? 'No Name',
        'imageUrl': data['imageUrl']?.toString(),
        'timestamp': lastMessageTime,
      });
    }

    combined.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.toDate().compareTo(aTime.toDate());
    });

    setState(() {
      cachedChatList = combined;
      isLoading = false;
    });
  }

  void sortList() {
    List<Map<String, dynamic>> combined = [];
    combined = cachedChatList!.toList();

    combined.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.toDate().compareTo(aTime.toDate());
    });

    setState(() {
      cachedChatList = combined;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    return Consumer<SubscriptionData>(
      builder: (context, subscriptionProvider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: _buildChatList(),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.orange.shade50,
            onPressed: () {
              if (provider.isUserSubscribed) {
                Get.to(() => const GroupChatCreateScreen());
              } else {
                _showSubscriptionDialog();
              }
            },
            child: const Icon(
              Icons.add,
              size: 30,
              color: Colors.orange,
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildChatList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (cachedChatList == null || cachedChatList!.isEmpty) {
      return const Center(child: Text("No groups yet!!"));
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      backgroundColor: Colors.white,
      color: Colors.deepOrange,
      child: ListView.builder(
          itemCount: cachedChatList!.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return const SizedBox(height: 8);
            }

            final chat = cachedChatList![i - 1];
            final groupId = chat['groupId'] as String;
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupId)
                  .snapshots(),
              builder: (ctx, snap) {
                String lastMsg = 'No messages yet';
                String lastTime = '';
                String? imageUrl = chat['imageUrl'] as String?;
                if (snap.hasData && snap.data!.exists) {
                  final data = snap.data!.data() as Map<String, dynamic>;
                  lastMsg = (data['lastMessage'] as String?) ?? lastMsg;
                  final t = data['lastMessageTime'] as Timestamp?;
                  if (t != null) lastTime = _formatTime(t);
                  imageUrl = data['imageUrl'] as String?;
                }
                return UserTiles(
                  chatType: 'group',
                  userName: chat['name'] as String,
                  lastMessage: lastMsg,
                  lastMessageTime: lastTime,
                  imageUrl: imageUrl,
                  status: 'friend',
                  onOpenChat: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          groupId: groupId,
                          groupName: chat['name'] as String,
                          groupImageUrl: imageUrl,
                        ),
                      ),
                    ).then((_) => _loadChats());
                  },
                );
              },
            );
          }),
    );
  }

  String chatRoomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  @override
  bool get wantKeepAlive => true;
}
