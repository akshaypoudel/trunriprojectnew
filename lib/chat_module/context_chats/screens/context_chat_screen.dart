import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trunriproject/chat_module/context_chats/models/context_chats.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';

class ContextChatScreen extends StatefulWidget {
  final String postId;
  final String postType;
  final String posterId;
  final String seekerId;
  final String postTitle;
  final String posterName;
  final String city;
  final String state;

  const ContextChatScreen({
    required this.postId,
    required this.postType,
    required this.posterId,
    required this.seekerId,
    required this.postTitle,
    super.key,
    required this.city,
    required this.state,
    required this.posterName,
  });

  @override
  _ContextChatScreenState createState() => _ContextChatScreenState();
}

class _ContextChatScreenState extends State<ContextChatScreen>
    with WidgetsBindingObserver {
  final ChatServices _chatService = ChatServices();
  late Future<ContextChat> _chatFuture;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatFuture = _chatService.openContextChat(
      postId: widget.postId,
      postType: widget.postType,
      posterId: widget.posterId,
      seekerId: widget.seekerId,
      postTitle: widget.postTitle,
      postCity: widget.city,
      postState: widget.state,
      seekerName: AuthServices().getCurrentUserDisplayName()!,
      posterName: widget.posterName,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _sendMessage(String chatId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _chatService.sendContextMessage(
        chatId: chatId,
        senderId: AuthServices().getCurrentUser()!.uid,
        text: text,
        context: context,
      );
      _controller.clear();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return "Today";
    if (msgDate == yesterday) return "Yesterday";
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthServices().getCurrentUser()!.uid;

    return FutureBuilder<ContextChat>(
      future: _chatFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final chat = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.postTitle,
                    style: const TextStyle(color: Colors.black)),
                Text(
                  '${widget.postType.capitalize} Chat',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 1,
          ),
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.messagesStream(chat.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs.reversed.toList();
                    List<Widget> messageWidgets = [];
                    String? lastDateLabel;

                    for (int i = 0; i < docs.length; i++) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] as Timestamp?;
                      if (timestamp == null) continue;
                      final time = timestamp.toDate();
                      final dateLabel = _getDateLabel(time);
                      final isMe = data['senderId'] == currentUserId;

                      if (lastDateLabel != dateLabel) {
                        lastDateLabel = dateLabel;
                        messageWidgets.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  dateLabel,
                                  style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      messageWidgets.add(
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.orange[100] : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isMe ? 12 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['text'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('h:mm a').format(time),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      scrollToBottom();
                    });

                    if (messageWidgets.isEmpty) {
                      return const Center(
                        child: Text(
                          'Ask any question about this post here!!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17),
                        ),
                      );
                    } else {
                      return ListView(
                        // reverse: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 10),
                        children: messageWidgets,
                      );
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Type your message…',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepOrange,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () => _sendMessage(chat.id),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
