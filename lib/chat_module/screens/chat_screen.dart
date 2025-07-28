import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:intl/intl.dart';
import 'package:trunriproject/chat_module/components/chat_bubble.dart';
import 'package:trunriproject/chat_module/components/chat_inputfield.dart';
import 'package:trunriproject/chat_module/components/date_bubble.dart';
import 'package:trunriproject/chat_module/components/useronline_status_title.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';
import 'package:trunriproject/notifications/notification_services.dart';
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
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: UserOnlineStatusTitle(
          userId: widget.receiversID,
          userName: widget.receiversName,
        ),
        backgroundColor: Colors.orange.shade50,
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
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Widget buildMessageList() {
    String? lastNotifiedMessageId;

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

        if (docs.isNotEmpty) {
          final latestDoc = docs.last; // last because messages are reversed
          final latest = latestDoc.data() as Map<String, dynamic>;
          final latestId = latestDoc.id;
          if (latest['senderID'] != availableEmailInDB &&
              lastNotifiedMessageId != latestId) {
            NotificationService.showNotification(
              widget.receiversName,
              latest['message'] ?? 'New message',
            );
            lastNotifiedMessageId = latestId;
          }
        }

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

        if (messageWidgets.isEmpty) {
          return const Center(
            child: Text(
              'You haven\'t messaged this person yet!\nStart messaging now to build connections!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17),
            ),
          );
        } else {
          return ListView(
            controller: scrollController,
            // reverse: true,
            children: messageWidgets,
          );
        }
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
