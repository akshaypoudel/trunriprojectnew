import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trunriproject/chat_module/components/chat_bubble.dart';
import 'package:trunriproject/chat_module/components/chat_inputfield.dart';
import 'package:trunriproject/chat_module/components/date_bubble.dart';
import 'package:trunriproject/chat_module/screens/display_group_members.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';
import 'package:trunriproject/widgets/helper.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupImageUrl;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupImageUrl,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ChatServices chatServices = ChatServices();
  final AuthServices authServices = AuthServices();
  bool isKeyboardVisible = false;
  String? currentUserEmail = '';
  String? currentUserName = '';
  final Map<String, String> _nameCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchCurrentUserEmail();

    _messageFocusNode.addListener(() => _onFocusChange());

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
      setState(() => isKeyboardVisible = newKeyboardVisible);
      if (isKeyboardVisible) {
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollToBottom();
        });
      }
    }
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        scrollToBottom();
      });
    }
  }

  Future<void> fetchCurrentUserEmail() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (snapshot.exists) {
      setState(() {
        currentUserEmail = snapshot.get('email');
        currentUserName = snapshot.get('name');
      });
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendGroupMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || currentUserEmail == null) return;

    messageController.clear();
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

    final messageData = {
      'senderID': currentUserEmail,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await groupRef.collection('messages').add(messageData);

    await groupRef.update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    scrollToBottom();
  }

  Stream<QuerySnapshot> getGroupMessages() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  String getDateLabel(DateTime messageDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay =
        DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) return 'Today';
    if (messageDay == yesterday) return 'Yesterday';
    return DateFormat('d MMMM yyyy').format(messageDate);
  }

  // Widget buildMessageItem(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
  //   final time =
  //       timestamp != null ? formatTimestamp(data['timestamp']) : '--:--';
  //   return FutureBuilder<String>(
  //     future: fetchNameByEmail(data['senderID']),
  //     builder: (context, snapshot) {
  //       final senderName = snapshot.data ?? '...';
  //       return GroupChatBubble(
  //         senderID: currentUserEmail!,
  //         userName: senderName,
  //         text: data['message'] ?? '',
  //         time: time,
  //         isMe: data['senderID'] == currentUserEmail,
  //       );
  //     },
  //   );
  // }

  Future<String> fetchNameByEmail(String email) async {
    if (_nameCache.containsKey(email)) return _nameCache[email]!;

    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final name =
        snapshot.docs.isNotEmpty ? snapshot.docs.first.get('name') : '';
    _nameCache[email] = name;
    return name;
  }

  // Widget buildMessageList1() {
  //   String? lastDateLabel = '';
  //   return StreamBuilder(
  //     stream: getGroupMessages(),
  //     builder: (context, snapshot) {
  //       if (snapshot.hasError) {
  //         return const Center(child: Text('Error loading messages'));
  //       }
  //       if (!snapshot.hasData) {
  //         return const Center(child: CircularProgressIndicator());
  //       }
  //       final docs = snapshot.data!.docs;
  //       final List<Widget> messageWidgets = [];
  //       for (var doc in docs) {
  //         final data = doc.data() as Map<String, dynamic>;
  //         final messageDate = (data['timestamp'] as Timestamp?)?.toDate();
  //         if (messageDate != null) {
  //           final currentLabel = getDateLabel(messageDate);
  //           if (lastDateLabel != currentLabel) {
  //             messageWidgets.add(DateBubble(date: currentLabel));
  //             lastDateLabel = currentLabel;
  //           }
  //         }
  //         messageWidgets.add(buildMessageItem(doc));
  //       }
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         scrollToBottom();
  //       });
  //       return ListView(
  //         reverse: true,
  //         controller: scrollController,
  //         padding: const EdgeInsets.only(bottom: 10),
  //         children: messageWidgets.reversed.toList(),
  //       );
  //     },
  //   );
  // }

  Widget buildMessageList() {
    return StreamBuilder(
      stream: getGroupMessages(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading messages'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return FutureBuilder<Map<String, String>>(
          future: prefetchAllNames(docs),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container();

            final nameMap = snapshot.data!;
            final List<Widget> messageWidgets = [];
            String? lastDateLabel;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final messageDate = (data['timestamp'] as Timestamp?)?.toDate();
              if (messageDate == null) continue;
              final currentLabel = getDateLabel(messageDate);
              if (lastDateLabel != currentLabel) {
                messageWidgets.add(DateBubble(date: currentLabel));
                lastDateLabel = currentLabel;
              }

              final senderEmail = data['senderID'];
              final senderName = nameMap[senderEmail] ?? '...';

              final time = messageDate != null
                  ? formatTimestamp(data['timestamp'])
                  : '--:--';

              log('sender name map = $nameMap, sender email = $senderEmail and Sender name = $senderName');

              messageWidgets.add(GroupChatBubble(
                senderID: senderEmail,
                userName: senderName,
                text: data['message'] ?? '',
                time: time,
                isMe: senderEmail == currentUserEmail,
              ));
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToBottom();
            });

            return ListView(
              reverse: true,
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 10),
              children: messageWidgets.reversed.toList(),
            );
          },
        );
      },
    );
  }

  // Future<Map<String, String>> prefetchAllNames1() async {
  //   final Map<String, String> nameMap = {};
  //   for (var doc in docs) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     final email = data['senderID'];
  //     if (_nameCache.containsKey(email)) {
  //       nameMap[email] = _nameCache[email]!;
  //     } else {
  //       final snapshot = await FirebaseFirestore.instance
  //           .collection('User')
  //           .where('email', isEqualTo: email)
  //           .limit(1)
  //           .get();
  //       final name =
  //           snapshot.docs.isNotEmpty ? snapshot.docs.first.get('name') : '';
  //       _nameCache[email] = name;
  //       nameMap[email] = name;
  //     }
  //   }
  //   return nameMap;
  // }

  Future<Map<String, String>> prefetchAllNames(
      List<DocumentSnapshot> docs) async {
    final Map<String, String> nameMap = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final email = data['senderID'];

      if (_nameCache.containsKey(email)) {
        nameMap[email] = _nameCache[email]!;
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('User')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        final name =
            snapshot.docs.isNotEmpty ? snapshot.docs.first.get('name') : '';
        _nameCache[email] = name;
        nameMap[email] = name;
      }
    }

    return nameMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RawMaterialButton(
          splashColor: Colors.transparent,
          onPressed: () {
            // showSnackBar(context, "Appbar clicked");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DisplayGroupMembers(groupId: widget.groupId),
              ),
            );
          },
          child: Row(
            children: [
              if (widget.groupImageUrl != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.groupImageUrl!),
                )
              else
                const CircleAvatar(
                  child: Icon(Icons.group),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.groupName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.orange.shade100,
      ),
      body: Column(
        children: [
          Expanded(child: buildMessageList()),
          ChatInputField(
            focusNode: _messageFocusNode,
            controller: messageController,
            onSend: sendGroupMessage,
          ),
        ],
      ),
    );
  }
}
