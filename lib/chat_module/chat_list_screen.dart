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

  @override
  void initState() {
    super.initState();
    fetchUserEmailFromDB();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
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

          return ListView(
            children: snapshot.data!
                .map<Widget>(
                  (userdata) => _buildUserListItem(userdata, context),
                )
                .toList(),
          );
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

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    String userEmail = userData['email'] ?? '';
    String userName = userData['name'] ?? '';

    if (userEmail != availableEmailInDB &&
        userEmail != _authServices.getCurrentUser()!.email) {
      return UserTiles(
        text: userName,
        lastMessage: '',
        lastMessageTime: '',
        onTap: () {
          log('user email pppppppp = $userEmail');
          log('user name pppppppp = $userName');

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
    } else {
      return Container();
    }
  }

  void getLastMessages(String userEmail) {
    String lastMessage = '';
    String lastMessageTime = '';
    _chatService
        .getMessages(_authServices.getCurrentUser()!.uid, userEmail)
        .first
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final lastDoc = snapshot.docs.last;
        final data = lastDoc.data() as Map<String, dynamic>;
        lastMessage = data['messages'] ?? '';
        lastMessageTime = data['timestamp'] != null
            ? (data['timestamp'] as Timestamp).toDate().toLocal().toString()
            : 'No time';
      }
    });
  }
}
