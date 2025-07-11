import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';
import 'package:trunriproject/widgets/helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.receiversName,
    required this.receiversID,
  });
  final String receiversName;
  final String receiversID;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ChatServices chatServices = ChatServices();
  final AuthServices authServices = AuthServices();
  String? availableEmailInDB;

  @override
  void initState() {
    super.initState();
    fetchUserEmailFromDB();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessages() async {
    if (messageController.text.isNotEmpty) {
      await chatServices.sendMessage(
        widget.receiversID,
        messageController.text,
      );
      messageController.clear();
    }
  }

  Widget buildMessageList() {
    String senderID = availableEmailInDB ?? '';
    return StreamBuilder(
      stream: chatServices.getMessages(senderID, widget.receiversID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return Expanded(
          child: ListView(
            children: snapshot.data!.docs
                .map(
                  (doc) => buildMessageItem(doc),
                )
                .toList(),
          ),
        );
      },
    );
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

  Widget buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatBubble(
      text: data['message'] ?? 'no message',
      isMe: data['senderID'] == availableEmailInDB,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiversName),
        backgroundColor: Colors.orange.shade100,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            buildMessageList(),
            ChatInputField(
              controller: messageController,
              onSend: () {
                sendMessages();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatBubble({super.key, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.orange.shade400 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  const ChatInputField({
    super.key,
    required this.onSend,
    required this.controller,
  });

  final VoidCallback onSend;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Colors.orange,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          RawMaterialButton(
            onPressed: onSend,
            shape: const CircleBorder(),
            fillColor: Colors.orange.shade300,
            elevation: 10,
            constraints: const BoxConstraints.tightFor(
              width: 52,
              height: 52,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 30,
            ),
          )
        ],
      ),
    );
  }
}
