import 'dart:developer';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';

import '../../widgets/helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.receiversName,
    required this.receiversID,
    required this.imageUrl,
  });
  final String receiversName;
  final String receiversID;
  final String imageUrl;

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
  String? otherUserEmail;
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

// In your ChatScreen's initState or message sending method
  Future<bool> _isUserBlocked(String userEmail) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final myDoc =
          await FirebaseFirestore.instance.collection('User').doc(uid).get();

      final blockedUsers =
          List<String>.from(myDoc.data()?['blockedUsers'] ?? []);

      // Check if I blocked them
      if (blockedUsers.contains(userEmail)) return true;

      // Check if they blocked me
      final theirDoc = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (theirDoc.docs.isNotEmpty) {
        final theirBlockedUsers =
            List<String>.from(theirDoc.docs.first.data()['blockedUsers'] ?? []);
        if (theirBlockedUsers
            .contains(FirebaseAuth.instance.currentUser!.email)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _buildProfileSection(),
        actions: const [],
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
              // const SizedBox(height: 100), // Space for app bar
              Expanded(
                child: availableEmailInDB == null
                    ? _buildLoadingState()
                    : MessageListView(
                        senderID: availableEmailInDB!,
                        receiverID: widget.receiversID,
                        chatServices: chatServices,
                        scrollController: scrollController,
                        receiversName: widget.receiversName,
                        scrollToBottom: scrollToBottom,
                      ),
              ),
              // Expanded(child: buildMessageList()),
              _buildModernInputSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6B35),
                Color.fromARGB(255, 255, 145, 76)
              ], // Orange gradient
            ),
          ),
          child: (widget.imageUrl.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 23,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : const Icon(
                  Icons.person,
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
                widget.receiversName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
                          hintText: 'Type a message...',
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
                  // Removed attachment and camera icons
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
        onTap: sendMessages,
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)], // Orange gradient
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

  void sendMessages() async {
    if (await _isUserBlocked(widget.receiversID)) {
      showSnackBar(context, 'Cannot send message to this user');
      return;
    }
    if (messageController.text.isNotEmpty) {
      HapticFeedback.lightImpact();
      String messageText = messageController.text;
      messageController.clear();
      await chatServices.sendMessage(
        widget.receiversID,
        messageText,
      );
      scrollToBottom();
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
              'Loading messages...',
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
    return DateFormat('hh:mm a').format(dateTime);
  }
}

class MessageListView extends StatelessWidget {
  final String senderID;
  final String receiverID;
  final ChatServices chatServices;
  final ScrollController scrollController;
  final String receiversName;
  final VoidCallback scrollToBottom;

  const MessageListView({
    super.key,
    required this.senderID,
    required this.receiverID,
    required this.chatServices,
    required this.scrollController,
    required this.receiversName,
    required this.scrollToBottom,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: chatServices.getMessages(senderID, receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        final docs = snapshot.data!.docs;
        final List<Widget> messageWidgets = [];
        String? lastDateLabel;

        for (var doc in docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime messageDate = (data['timestamp'] as Timestamp).toDate();
          String currentDateLabel = getDateLabel(messageDate);

          if (lastDateLabel != currentDateLabel) {
            messageWidgets.add(_buildGlassmorphicDateBubble(currentDateLabel));
            lastDateLabel = currentDateLabel;
          }
          messageWidgets.add(
            buildMessageItem(
              context,
              doc,
              senderID,
              receiverID,
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });

        if (messageWidgets.isEmpty) {
          return _buildEmptyState(receiversName);
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: messageWidgets.length,
          itemBuilder: (context, index) => messageWidgets[index],
        );
      },
    );
  }

  Widget _buildErrorState() => Center(
        child: Text('Something went wrong. Please try again later.',
            style: TextStyle(color: Colors.grey[800])),
      );
  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());
  Widget _buildEmptyState(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 55, color: Color(0xFFFF6B35)),
          const SizedBox(height: 24),
          Text('Start the conversation',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Text('Send your first message to $name',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]))
        ],
      ),
    );
  }

  Widget _buildGlassmorphicDateBubble(String date) => Container(
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

  Widget buildMessageItem(
    BuildContext context,
    DocumentSnapshot doc,
    String senderID,
    String receiverID,
  ) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String formattedTime = formatTimestamp(data['timestamp']);
    bool isMe = data['senderID'] == senderID;

    // Only allow reporting other user's messages
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
                List<String> ids = [senderID, receiverID];
                ids.sort();
                String chatRoomId = ids.join('_');

                await FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(chatRoomId)
                    .set({'isReported': true});

                await FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(chatRoomId)
                    .collection("chat_messages")
                    .doc(doc.id)
                    .update({'isReported': true});
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
            child: _buildGlassmorphicMessageBubble(
              text: data['message'] ?? 'no message',
              time: formattedTime,
              isMe: isMe,
            ),
          ),
        ),
      );
    }

    // Original message bubble for own messages
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: _buildGlassmorphicMessageBubble(
          text: data['message'] ?? 'no message',
          time: formattedTime,
          isMe: isMe,
        ),
      ),
    );
  }

  Widget _buildGlassmorphicMessageBubble({
    required String text,
    required String time,
    required bool isMe,
  }) {
    return IntrinsicWidth(
      child: GestureDetector(
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
                  bottomLeft: Radius.circular(isMe ? 20 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 20),
                ),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                      : Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
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
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white : Colors.grey[600],
                          fontWeight:
                              isMe ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String getDateLabel(DateTime messageDate) {
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
      return DateFormat('d MMMM yyyy').format(messageDate);
    }
  }

  static String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }
}
