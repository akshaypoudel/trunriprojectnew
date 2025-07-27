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

  String? groupCreatorEmail;
  Timestamp? groupCreatedAt;
  List<String> groupMembers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchCurrentUserEmail();
    fetchGroupInfo();

    _messageFocusNode.addListener(() => _onFocusChange());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  Future<void> fetchGroupInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      groupCreatorEmail = data['createdBy'];
      groupCreatedAt = data['createdAt'];
      groupMembers = List<String>.from(data['members'] ?? []);
    }
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
        scrollController.position.maxScrollExtent,
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
    // .get();
    // .get();
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

  String formatFullDateWithSuffixFromString(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';

    final day = date.day;
    final suffix = getDaySuffix(day);
    final month = DateFormat('MMMM').format(date);
    final year = date.year;

    return '$day$suffix $month, $year';
  }

  String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

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

              messageWidgets.add(
                GroupChatBubble(
                  senderID: senderEmail,
                  userName: senderName,
                  text: data['message'] ?? '',
                  time: time,
                  isMe: senderEmail == currentUserEmail,
                ),
              );
            }

            if (groupCreatorEmail != null && groupCreatedAt != null) {
              final groupCreatedDate = formatFullDateWithSuffixFromString(
                groupCreatedAt!.toDate().toString(),
              );
              final creatorName =
                  nameMap[groupCreatorEmail] ?? groupCreatorEmail!;
              final memberNames = groupMembers
                  .where((e) => e != groupCreatorEmail)
                  .map((e) => nameMap[e] ?? e)
                  .toList();
              messageWidgets.insert(
                0,
                _buildGroupCreatedBubble(
                  createdBy: creatorName,
                  groupCreatedDate: groupCreatedDate,
                  members: memberNames,
                ),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToBottom();
            });

            return ListView(
              // reverse: true,
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 10),
              children: messageWidgets,
            );
          },
        );
      },
    );
  }

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

    for (final email in [...groupMembers, groupCreatorEmail]) {
      if (email != null && !_nameCache.containsKey(email)) {
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

  Widget _buildGroupCreatedBubble({
    required String createdBy,
    required String groupCreatedDate,
    required List<String> members,
  }) {
    final others = members.where((m) => m != createdBy).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              '$createdBy created this group',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Group · ${members.length} members',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            if (others.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: others
                    .map((m) => Chip(
                          label: Text(m, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.orange.shade50,
                        ))
                    .toList(),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RawMaterialButton(
          splashColor: Colors.transparent,
          onPressed: () {
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
