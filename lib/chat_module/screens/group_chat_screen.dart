import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUser.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          currentUserEmail = snapshot.get('email');
          currentUserName = currentUser.displayName ?? 'Unknown User';
        });
      }
    }
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

  void sendGroupMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || currentUserEmail == null) return;

    HapticFeedback.lightImpact();
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

  Future<Map<String, String>> prefetchAllNames(
      List<DocumentSnapshot> docs) async {
    final Map<String, String> nameMap = {};
    final currentUser = FirebaseAuth.instance.currentUser;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final email = data['senderID'];

      if (_nameCache.containsKey(email)) {
        nameMap[email] = _nameCache[email]!;
      } else {
        String name;

        // Use Firebase Auth displayName for current user
        if (email == currentUser?.email) {
          name = currentUser?.displayName ?? 'You';
        } else {
          // For other users, get from Firestore
          final snapshot = await FirebaseFirestore.instance
              .collection('User')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          name = snapshot.docs.isNotEmpty
              ? (snapshot.docs.first.get('name') ?? 'Unknown User')
              : 'Unknown User';
        }

        _nameCache[email] = name;
        nameMap[email] = name;
      }
    }

    // Handle group members and creator
    for (final email in [...groupMembers, groupCreatorEmail]) {
      if (email != null && !_nameCache.containsKey(email)) {
        String name;

        if (email == currentUser?.email) {
          name = currentUser?.displayName ?? 'You';
        } else {
          final snapshot = await FirebaseFirestore.instance
              .collection('User')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          name = snapshot.docs.isNotEmpty
              ? (snapshot.docs.first.get('name') ?? 'Unknown User')
              : 'Unknown User';
        }

        _nameCache[email] = name;
        nameMap[email] = name;
      }
    }

    return nameMap;
  }

  Future<Map<String, String>> prefetchAllNames1(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _buildProfileSection(),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/chat_background.jpg'),
              fit: BoxFit.cover,
              opacity: 0.6,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF), // Pure white
                Color(0xFFFFF8F0), // Very light orange tint
                Color(0xFFFFF0E6), // Light orange
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: currentUserEmail == null
                    ? _buildLoadingState()
                    : _buildMessageListView(),
              ),
              _buildModernInputSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayGroupMembers(groupId: widget.groupId),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color.fromARGB(255, 255, 145, 76)],
              ),
            ),
            child: widget.groupImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.groupImageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${groupMembers.length} members',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageListView() {
    return StreamBuilder(
      stream: getGroupMessages(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final docs = snapshot.data!.docs;

        return FutureBuilder<Map<String, String>>(
          future: prefetchAllNames(docs),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildLoadingState();

            final nameMap = snapshot.data!;
            final List<Widget> messageWidgets = [];
            String? lastDateLabel;

            // Add group creation bubble first
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
              messageWidgets.add(
                _buildGroupCreatedBubble(
                  createdBy: creatorName,
                  groupCreatedDate: groupCreatedDate,
                  members: memberNames,
                ),
              );
            }

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final messageDate = (data['timestamp'] as Timestamp?)?.toDate();
              if (messageDate == null) continue;

              final currentLabel = getDateLabel(messageDate);
              if (lastDateLabel != currentLabel) {
                messageWidgets.add(_buildGlassmorphicDateBubble(currentLabel));
                lastDateLabel = currentLabel;
              }

              final senderEmail = data['senderID'];
              final senderName = nameMap[senderEmail] ?? '...';
              final time = formatTimestamp(data['timestamp']);
              final isMe = senderEmail == currentUserEmail;

              messageWidgets.add(
                _buildGroupMessageItem(
                  senderEmail: senderEmail,
                  userName: senderName,
                  text: data['message'] ?? '',
                  time: time,
                  isMe: isMe,
                ),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToBottom();
            });

            if (messageWidgets.length <= 1) {
              // Only group creation bubble
              return _buildEmptyState();
            }

            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: messageWidgets.length,
              itemBuilder: (context, index) => messageWidgets[index],
            );
          },
        );
      },
    );
  }

  Widget _buildGroupMessageItem({
    required String senderEmail,
    required String userName,
    required String text,
    required String time,
    required bool isMe,
  }) {
    if (!isMe) {
      return GestureDetector(
        onLongPress: () async {
          final selected = await showModalBottomSheet<String>(
            backgroundColor: Colors.white,
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.flag, color: Colors.red),
                    title: const Text('Report this message'),
                    onTap: () => Navigator.pop(ctx, 'report'),
                  ),
                ],
              ),
            ),
          );
          if (selected == 'report') {
            bool confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Report Message'),
                    content: const Text(
                        'Do you really want to report this message?'),
                    actions: [
                      TextButton(
                        child: const Text('No'),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                      TextButton(
                        child: const Text('Yes'),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (confirmed) {
              try {
                // Compose correct chatRoomID as in your ChatServices

                final query = await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection("messages")
                    .where('senderID', isNotEqualTo: userName)
                    .get();

                for (var doc in query.docs) {
                  await doc.reference.update({'isReported': true});
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message reported Successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to report: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: _buildGlassmorphicGroupMessageBubble(
              userName: userName,
              text: text,
              time: time,
              isMe: isMe,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: _buildGlassmorphicGroupMessageBubble(
          userName: userName,
          text: text,
          time: time,
          isMe: isMe,
        ),
      ),
    );
  }

  Widget _buildGlassmorphicGroupMessageBubble({
    required String userName,
    required String text,
    required String time,
    required bool isMe,
  }) {
    return IntrinsicWidth(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMe
                    ? [
                        const Color(0xFFFF6B35).withValues(alpha: 0.8),
                        const Color.fromARGB(255, 255, 125, 44)
                            .withValues(alpha: 0.7),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.8),
                      ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 20),
              ),
              border: Border.all(
                color: isMe
                    ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                    : Colors.orange.shade300,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.white : const Color(0xFF333333),
                      height: 1.4,
                      fontWeight: isMe ? FontWeight.w400 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white : Colors.grey[600],
                        fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicDateBubble(String date) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
                width: 1,
              ),
            ),
            child: Text(
              date,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCreatedBubble({
    required String createdBy,
    required String groupCreatedDate,
    required List<String> members,
  }) {
    final others = members.where((m) => m != createdBy).toList();

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B35).withValues(alpha: 0.2),
                        const Color(0xFFFF8C42).withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.group,
                    size: 28,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$createdBy created this group',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Group · ${members.length + 1} members',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: others
                        .map((m) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF6B35)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInputSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: TextField(
                        controller: messageController,
                        focusNode: _messageFocusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message to ${widget.groupName}...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSendButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: GestureDetector(
        onTap: sendGroupMessage,
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading group chat...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Something went wrong. Please try again later.',
        style: TextStyle(color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_outlined,
            size: 55,
            color: Color(0xFFFF6B35),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to ${widget.groupName}!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the group conversation',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
