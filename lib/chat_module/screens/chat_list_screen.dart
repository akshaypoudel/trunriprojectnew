import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/screens/chat_screen.dart';
import 'package:trunriproject/chat_module/screens/group_chat_screen.dart';
import 'package:trunriproject/chat_module/screens/group_chat_create_screen.dart';
import 'package:trunriproject/chat_module/components/user_tiles.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // final ChatServices _chatService = ChatServices();
  List<Map<String, dynamic>>? cachedChatList;
  String? currentEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // listenToAllMessages();
  }

  Future<void> _loadChats() async {
    final meDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    currentEmail = meDoc.get('email') as String?;

    if (currentEmail == null) return;

    final List<Map<String, dynamic>> combined = [];

    final usersSnap = await FirebaseFirestore.instance.collection('User').get();
    for (var u in usersSnap.docs) {
      final email = u['email'] as String;
      final name = u['name'] as String;
      if (email == currentEmail) continue;

////////////////////////////////////////
      final roomId = chatRoomId(currentEmail!, email);
      final msgSnap = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      Timestamp? lastTime;
      if (msgSnap.docs.isNotEmpty) {
        lastTime = msgSnap.docs.first['timestamp'] as Timestamp?;
      }
//////////////////////////////////
      combined.add({
        'type': 'user',
        'email': email,
        'name': name,
        'timestamp': lastTime,
      });
    }

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
        'name': data['groupName'] as String,
        'imageUrl': data['imageUrl'] as String?,
        'timestamp': lastMessageTime
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
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    if (!provider.isUserSubscribed) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.5),
          elevation: 0,
          title: const Text('Messages'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/chatbackground.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),

            // Foreground content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 100, color: Colors.orangeAccent),
                    const SizedBox(height: 24),
                    Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subscribe to unlock one-on-one and group chat features,\nalong with other premium tools!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigator.pushNamed(context, '/subscriptionScreen');
                          Get.to(() => const SubscriptionScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ).copyWith(
                          backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            return null; // Gradient handled below
                          }),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Text(
                              'Subscribe Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (v) {
                if (v == 'new_group') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GroupChatCreateScreen(),
                    ),
                  ).then((_) => _loadChats());
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'new_group',
                  child: Row(
                    children: [
                      Icon(Icons.group_add),
                      SizedBox(width: 8),
                      Text('Create New Group'),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
        body: _buildChatList(),
      );
    }
  }

  Widget _buildChatList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (cachedChatList == null || cachedChatList!.isEmpty) {
      return const Center(child: Text("No chats yet!!"));
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        itemCount: cachedChatList!.length,
        itemBuilder: (context, i) {
          final chat = cachedChatList![i];

          if (chat['type'] == 'user') {
            final otherEmail = chat['email'] as String;
            // Stream for the last message
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(chatRoomId(currentEmail!, otherEmail))
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (ctx, msgSnap) {
                String lastMsg = 'No messages yet';
                String lastTime = '';
                if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                  final d = msgSnap.data!.docs.first;
                  lastMsg = d['message'] as String;
                  lastTime = _formatTime(d['timestamp'] as Timestamp);
                }
                // Stream for user's profile image
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('User')
                      .where('email', isEqualTo: otherEmail)
                      .limit(1)
                      .get(),
                  builder: (ctx, userSnap) {
                    String? imageUrl;
                    if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
                      final userData = userSnap.data!.docs.first.data()
                          as Map<String, dynamic>;
                      imageUrl = userData['profile'] as String?;
                    }
                    return UserTiles(
                      chatType: 'user',
                      text: chat['name'] as String,
                      lastMessage: lastMsg,
                      lastMessageTime: lastTime,
                      imageUrl: imageUrl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              receiversName: chat['name'] as String,
                              receiversID: otherEmail,
                            ),
                          ),
                        ).then((_) => _loadChats());
                      },
                    );
                  },
                );
              },
            );
          } else {
            // —— group
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
                  text: chat['name'] as String,
                  lastMessage: lastMsg,
                  lastMessageTime: lastTime,
                  imageUrl: imageUrl,
                  onTap: () {
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
          }
        },
      ),
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
}
