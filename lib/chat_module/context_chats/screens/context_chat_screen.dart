// screens/context_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trunriproject/chat_module/context_chats/models/context_chats.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';

class ContextChatScreen extends StatefulWidget {
  final String postId;
  final String postType;
  final String posterId;
  final String seekerId;
  final String postTitle;

  const ContextChatScreen({
    required this.postId,
    required this.postType,
    required this.posterId,
    required this.seekerId,
    required this.postTitle,
    super.key,
  });

  @override
  _ContextChatScreenState createState() => _ContextChatScreenState();
}

class _ContextChatScreenState extends State<ContextChatScreen> {
  final ChatServices _chatService = ChatServices();
  late Future<ContextChat> _chatFuture;
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chatFuture = _chatService.openContextChat(
      postId: widget.postId,
      postType: widget.postType,
      posterId: widget.posterId,
      seekerId: widget.seekerId,
    );
  }

  void _sendMessage(String chatId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _chatService.sendContextMessage(
        chatId: chatId,
        senderId: widget.seekerId,
        text: text,
      );
      _controller.clear();
    } catch (e) {
      if (e == 'SUBSCRIPTION_REQUIRED') {
        Get.dialog(
          AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Subscribe to Continue'),
            content: const Text(
                'You have used your 2 free messages. Please subscribe to send more.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => const SubscriptionScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.deepOrange,
                ),
                child: const Text('Subscribe'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContextChat>(
      future: _chatFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Chat…')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final chat = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.postTitle),
                Text(
                  '${widget.postType.capitalize} Chat',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.messagesStream(chat.id),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == widget.seekerId;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(data['text']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type your message…',
                        ),
                      ),
                    ),
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () => _sendMessage(chat.id),
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
