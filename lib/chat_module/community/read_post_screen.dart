import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/community/components/chat_provider.dart';

class ReadPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;

  const ReadPostScreen({super.key, required this.post, required this.postId});

  @override
  State<ReadPostScreen> createState() => _ReadPostScreenState();
}

class _ReadPostScreenState extends State<ReadPostScreen> {
  late TextEditingController _messageController;
  final FocusNode _focusNode = FocusNode();
  bool editing = false;
  String? _originalMessage;

  @override
  void initState() {
    super.initState();
    _originalMessage = widget.post['content'] ?? '';
    _messageController = TextEditingController(text: _originalMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final tags = List<String>.from(widget.post['tags'] ?? []);
    final repliesRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId)
        .collection('replies');

    final userName = widget.post['username'] ?? 'Unknown';
    final userImage = widget.post['profileUrl'] ?? '';
    final message = widget.post['content'] ?? '';
    final timestamp = (widget.post['timestamp'] as Timestamp?)?.toDate();

    final postUserId = widget.post['uid'] ?? '';
    final isOwner = firebaseAuth.currentUser?.uid == postUserId;
    final isEdited = widget.post['isEdited'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Post Details",
          style: TextStyle(color: Colors.black),
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        actions: isOwner
            ? editing
                ? [
                    IconButton(
                      icon: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 30,
                      ),
                      tooltip: "Save",
                      onPressed: _saveEdit,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 30,
                      ),
                      tooltip: "Cancel",
                      onPressed: _cancelEdit,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.deepOrange),
                      tooltip: "Edit",
                      onPressed: () {
                        setState(() {
                          editing = true;
                        });
                        // _focusNode.requestFocus();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _focusNode.requestFocus();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Delete",
                      onPressed: _showDeleteDialog,
                    ),
                  ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          userImage.isNotEmpty ? NetworkImage(userImage) : null,
                      child:
                          userImage.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (timestamp != null)
                          Row(
                            children: [
                              Text(
                                '${timestamp.toLocal()}'.split('.')[0],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (isEdited)
                                const Text(
                                  ' · Edited',
                                  style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: editing,
                  maxLines: null,
                  readOnly: !editing,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          elevation: 10,
                        ),
                      )
                      .toList(),
                ),
                const Divider(height: 32),
                const Text(
                  "Replies",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: repliesRef
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final replies = snapshot.data!.docs;

                      if (replies.isEmpty) {
                        return const Text("No replies yet.");
                      }

                      return ListView.builder(
                        itemCount: replies.length,
                        itemBuilder: (context, index) {
                          final reply =
                              replies[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: reply['userImage'] != null &&
                                      reply['userImage'].isNotEmpty
                                  ? NetworkImage(reply['userImage'])
                                  : null,
                              child: reply['userImage'] == null ||
                                      reply['userImage'].isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(reply['userName'] ?? 'Anonymous'),
                            subtitle: Text(reply['reply'] ?? ''),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReplyDialog(context, widget.postId),
        label: const Text(
          "Reply",
          style: TextStyle(color: Colors.deepOrange),
        ),
        backgroundColor: Colors.orange.shade50,
        icon: const Icon(
          Icons.reply,
          color: Colors.deepOrange,
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String postId) {
    final replyController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;
    final provider = Provider.of<ChatProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Reply to Post"),
        content: TextField(
          controller: replyController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Write your reply here"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reply = replyController.text.trim();
              if (reply.isNotEmpty && currentUser != null) {
                final replyData = {
                  'reply': reply,
                  'userName': provider.getUserName,
                  'userImage': provider.getProfileImage ?? '',
                  'timestamp': FieldValue.serverTimestamp(),
                };

                await FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(postId)
                    .collection('replies')
                    .add(replyData);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  void _saveEdit() async {
    if (_messageController.text == _originalMessage) {
      return;
    }
    final updatedContent = _messageController.text.trim();
    if (updatedContent.isNotEmpty && updatedContent != _originalMessage) {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .update({
        'content': updatedContent,
        'isEdited': true,
      });
      setState(() {
        _originalMessage = updatedContent;
        editing = false;
      });
    } else {
      setState(() {
        editing = false;
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(widget.postId)
                  .delete();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _messageController.text = _originalMessage ?? '';
      editing = false;
    });
  }
}
