import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/chat_module/screens/chat_screen.dart';
import 'package:trunriproject/chat_module/screens/group_chat_screen.dart';
import 'package:trunriproject/chat_module/screens/group_chat_create_screen.dart';
import 'package:trunriproject/chat_module/components/user_tiles.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';
import 'package:trunriproject/notifications/notification_services.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatServices _chatService = ChatServices();
  List<Map<String, dynamic>>? cachedChatList;
  String? currentEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // listenToAllMessages();
  }

  // Future<void> listenToAllMessages() async {
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   if (currentUser == null) {
  //     log('user is null');
  //     return;
  //   }
  //   log('user is not null');
  //   final myUID = currentUser.uid;
  //   final myEmail = currentUser.email;
  //   // final chatRoomsQuery = await _firestore
  //   //     .collection('chat_rooms')
  //   //     .where('senderID', isEqualTo: myEmail)
  //   //     .get();
  //   final chatroomid = chatRoomId(a, myEmail!);
  //   // final chatRoomsQuery =
  //   //     await FirebaseFirestore.instance.collection('chat_rooms').get();
  //   // final user = await FirebaseFirestore.instance.collection('User').get();
  //   // log('printing.....');
  //   // log('Total chat rooms fetched: ${chatRoomsQuery.docs.length}');
  //   // log('Total user fetched: ${user.docs.length}');
  //   for (var roomDoc in chatRoomsQuery.docs) {
  //     final roomId = roomDoc.id;
  //     log('outside if');
  //     if (roomId.contains(myEmail)) {
  //       log('coming inside if');
  //       FirebaseFirestore.instance
  //           .collection('chat_rooms')
  //           .doc(roomId)
  //           .collection('messages')
  //           .orderBy('timestamp', descending: true)
  //           .snapshots()
  //           .listen((querySnapshot) {
  //         for (final doc in querySnapshot.docChanges) {
  //           if (doc.type == DocumentChangeType.added) {
  //             final data = doc.doc.data() as Map<String, dynamic>;
  //             if (data['senderID'] != myUID) {
  //               // 🔔 Trigger local notification
  //               NotificationService.showNotification(
  //                 'You Have New Message From ${data['senderName']}',
  //                 data['message'] ?? '',
  //               );
  //               _saveNotificationToFirestore(data);
  //             }
  //           }
  //         }
  //       });
  //     }
  //   }
  // }
  // Future<void> _saveNotificationToFirestore(Map<String, dynamic> data) async {
  //   try {
  //     await FirebaseFirestore.instance.collection('notifications').add({
  //       'receiverID': data['receiverID'],
  //       'senderID': data['senderID'],
  //       'senderName': data['senderName'] ?? 'Unknown',
  //       'message': data['message'] ?? '',
  //       'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
  //       'read': false,
  //     });
  //   } catch (e) {
  //     log('Failed to save notification: $e');
  //   }
  // }

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
    return Scaffold(
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

  Widget _buildChatList1() {
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
            // —— one‑on‑one

            final otherEmail = chat['email'] as String;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(chatRoomId(currentEmail!, otherEmail))
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (ctx, snap) {
                String lastMsg = 'No messages yet';
                String lastTime = '';
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  final d = snap.data!.docs.first;
                  lastMsg = d['message'] as String;
                  lastTime = _formatTime(d['timestamp'] as Timestamp);
                }
                return UserTiles(
                  chatType: 'user',
                  text: chat['name'] as String,
                  lastMessage: lastMsg,
                  lastMessageTime: lastTime,
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
