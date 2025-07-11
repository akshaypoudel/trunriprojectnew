import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/chat_module/chat_screen.dart';
import 'package:trunriproject/chat_module/components/user_tiles.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatServices _chatService = ChatServices();

  final AuthServices _authServices = AuthServices();

  String? availableEmailInDB;
  String? lastMessage;
  String? lastMessageTime;

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
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () async {},
          ),
        ],
      ),
      body: availableEmailInDB == null
          ? const Center(child: CircularProgressIndicator())
          : _buildUserList(),
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
      setState(() {
        availableEmailInDB = snapshot.get('email') ?? '';
      });
    }
  }

  Widget buildChatListScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: buildSortedUserList(availableEmailInDB!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading chats"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No chats yet"));
        }

        return ListView(
          children: snapshot.data!.map((userData) {
            return UserTiles(
              text: userData['name'],
              lastMessage: userData['lastMessage'],
              lastMessageTime: userData['lastMessageTime'],
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
          }).toList(),
        );
      },
    );
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

      Map<String, dynamic>? lastMsgData =
          await getLastMessageForUser(userEmail);

      // if (lastMsgData == null) continue;

      sortedList.add({
        'email': userEmail,
        'name': userName,
        'lastMessage': lastMsgData?['message'] ?? 'No messages yet',
        'lastMessageTime': lastMsgData?['timestamp'] != null
            ? formatTimestamp(lastMsgData!['timestamp'])
            : '',
        'timestamp': lastMsgData?['timestamp'],
      });
    }

    // // Sort by timestamp descending
    // sortedList.sort((a, b) =>
    //     (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

    sortedList.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1; // push a below
      if (bTime == null) return -1; // push b below

      return bTime.compareTo(aTime); // latest on top
    });

    return sortedList;
  }

  Widget buildUserTile1(String userEmail, String userName) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getLastMessageForUser(userEmail),
      builder: (context, snapshot) {
        String lastMsg = "No messages";
        String time = "";

        if (snapshot.connectionState == ConnectionState.waiting) {
          lastMsg = "Loading...";
        } else if (snapshot.hasError) {
          lastMsg = "Error loading message";
        } else if (snapshot.hasData && snapshot.data != null) {
          lastMsg = snapshot.data!['message'] ?? '';
          Timestamp timestamp = snapshot.data!['timestamp'];
          time = formatTimestamp(timestamp);
        }

        return UserTiles(
          text: userName,
          lastMessage: lastMsg,
          lastMessageTime: time,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  receiversName: userName,
                  receiversID: userEmail,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    final DateTime dt = timestamp.toDate();
    final now = DateTime.now();

    if (now.difference(dt).inDays == 0) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  Future<Map<String, dynamic>?> getLastMessageForUser(
      String otherUserEmail) async {
    final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
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
      return null; // No messages yet
    }
  }
}
