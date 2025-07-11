import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ChatServices chatServices = ChatServices();
  final AuthServices authServices = AuthServices();
  String? availableEmailInDB;
  bool isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchUserEmailFromDB();

    _messageFocusNode.addListener(() {
      _onFocusChange();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messageController.dispose();
    scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0;

    if (newKeyboardVisible != isKeyboardVisible) {
      setState(() {
        isKeyboardVisible = newKeyboardVisible;
      });

      if (isKeyboardVisible) {
        // Keyboard appeared, scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollToBottom();
        });
      }
    }
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus) {
      // Use a slight delay to ensure keyboard is visible
      Future.delayed(const Duration(milliseconds: 300), () {
        scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.receiversName),
        backgroundColor: Colors.orange.shade100,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: buildMessageList()),
            ChatInputField(
              focusNode: _messageFocusNode,
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

  void sendMessages() async {
    if (messageController.text.isNotEmpty) {
      String messageText = messageController.text;
      messageController.clear();
      await chatServices.sendMessage(
        widget.receiversID,
        messageText,
      );
    }
    scrollToBottom();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
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

        final docs = snapshot.data!.docs;
        final List<Widget> messageWidgets = [];

        String? lastDateLabel;

        for (var doc in docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime messageDate = (data['timestamp'] as Timestamp).toDate();

          String currentDateLabel = getDateLabel(messageDate);

          if (lastDateLabel != currentDateLabel) {
            messageWidgets.add(DateBubble(date: currentDateLabel));
            lastDateLabel = currentDateLabel;
          }

          messageWidgets.add(buildMessageItem(doc));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });

        return ListView(
          controller: scrollController,
          reverse: true,
          children: messageWidgets.reversed.toList(),
        );
      },
    );
  }

  Widget buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String formattedTime = formatTimestamp(data['timestamp']);
    return ChatBubble(
      text: data['message'] ?? 'no message',
      time: formattedTime,
      isMe: data['senderID'] == availableEmailInDB,
    );
  }

  String getDateLabel(DateTime messageDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay =
        DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) {
      return 'Today';
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMMM yyyy')
          .format(messageDate); // e.g., "16 September 2024"
    }
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

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime); // e.g., "04:35 PM"
  }
}

class DateBubble extends StatelessWidget {
  final String date;
  const DateBubble({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          date,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;

  const ChatBubble(
      {super.key, required this.text, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(10),
        // padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 7, bottom: 5, top: 5),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
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
    required this.focusNode,
  });

  final VoidCallback onSend;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
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
          ),
        ],
      ),
    );
  }
}
