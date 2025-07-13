import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/chat_module/screens/chat_screen.dart';
import 'package:trunriproject/chat_module/components/user_tiles.dart';
import 'package:trunriproject/chat_module/screens/group_chat_create_screen.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';
import 'package:trunriproject/widgets/helper.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatServices _chatService = ChatServices();

  final AuthServices _authServices = AuthServices();
  List<Map<String, dynamic>>? cachedUserList = [];

  String? availableEmailInDB;
  String? lastMessage;
  String? lastMessageTime;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserEmailFromDB();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            surfaceTintColor: Colors.orange.shade200,
            elevation: 15,
            borderRadius: BorderRadius.circular(30),
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            color: Colors.white,
            position: PopupMenuPosition.under,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Create New Group',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const GroupChatCreateScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 5),
                    Text('Create New Group'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
        stream: _chatService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return buildChatListScreen();
        });
  }

  void fetchUserEmailFromDB() async {
    dynamic snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (snapshot.exists) {
      availableEmailInDB = snapshot.get('email') ?? '';
      cachedUserList = await buildSortedUserList(availableEmailInDB!);
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildChatListScreen() {
    if (isLoading || cachedUserList == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cachedUserList!.isEmpty) {
      return const Center(child: Text("No chats yet"));
    }
    return RefreshIndicator(
      onRefresh: () async {
        cachedUserList = await buildSortedUserList(availableEmailInDB!);
        setState(() {});
      },
      child: ListView(
        children: cachedUserList!.map((userData) {
          return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(getChatRoomId(availableEmailInDB!, userData['email']))
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, messageSnapshot) {
                String lastMsg = 'No messages yet';
                String lastTime = '';

                if (messageSnapshot.hasData &&
                    messageSnapshot.data!.docs.isNotEmpty) {
                  final doc = messageSnapshot.data!.docs.first;
                  lastMsg = doc['message'];
                  final Timestamp timestamp = doc['timestamp'];
                  lastTime = formatTimestamp(timestamp);
                }

                return UserTiles(
                  text: userData['name'],
                  lastMessage: lastMsg,
                  lastMessageTime: lastTime,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiversName: userData['name'],
                          receiversID: userData['email'],
                        ),
                      ),
                    );
                    setState(() {});
                  },
                );
              });
        }).toList(),
      ),
    );
  }

  String getChatRoomId(String a, String b) {
    List<String> ids = [a, b];
    ids.sort();
    return ids.join('_');
  }

  Future<List<Map<String, dynamic>>> buildSortedUserList(
      String currentUserEmail) async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('User').get();
    List<Map<String, dynamic>> sortedList = [];

    for (var doc in querySnapshot.docs) {
      String userEmail = doc.get('email');
      String userName = doc.get('name');

      if (userEmail == currentUserEmail) continue;

      Map<String, dynamic> lastMsgData = await getLastMessageForUser(userEmail);

      // if (lastMsgData == null) continue;
      try {
        sortedList.add({
          'email': userEmail,
          'name': userName,
          'lastMessage': lastMsgData['message'] ?? 'No messages yet',
          'lastMessageTime': lastMsgData['timestamp'] != null
              ? formatTimestamp(lastMsgData['timestamp'])
              : '',
          'timestamp': lastMsgData['timestamp'],
        });
      } catch (e) {
        log('error 1 = $e');
      }
    }

    // // Sort by timestamp descending
    // sortedList.sort((a, b) =>
    //     (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
    try {
      sortedList.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1; // push a below
        if (bTime == null) return -1; // push b below

        return bTime.compareTo(aTime); // latest on top
      });
    } catch (e) {
      log('error 2 = $e');
    }

    return sortedList;
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null || timestamp.isBlank!) return '';
    final DateTime dt = timestamp.toDate();
    final now = DateTime.now();

    if (now.difference(dt).inDays == 0) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  Future<Map<String, dynamic>> getLastMessageForUser(
      String otherUserEmail) async {
    final String currentUserEmail = availableEmailInDB!;
    log(availableEmailInDB!);
    List<String> ids = [currentUserEmail, otherUserEmail];
    ids.sort();
    String chatRoomId = ids.join('_');

    final QuerySnapshot messageSnapshot = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messageSnapshot.docs.isNotEmpty) {
      final doc = messageSnapshot.docs.first;
      return {
        'message': doc['message'],
        'timestamp': doc['timestamp'],
      };
    } else {
      return {}; // No messages yet
    }
  }
}
