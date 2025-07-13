import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:trunriproject/chat_module/components/chat_inputfield.dart';

class GroupNameScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedUsers;

  const GroupNameScreen({super.key, required this.selectedUsers});

  @override
  State<GroupNameScreen> createState() => _GroupNameScreenState();
}

class _GroupNameScreenState extends State<GroupNameScreen> {
  File? _groupImage;
  final TextEditingController _groupNameController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _showEmojiKeyboard = false;

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _groupImage = File(pickedFile.path);
      });
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _groupNameController.text += emoji.emoji;
  }

  void _toggleEmojiKeyboard() {
    if (_showEmojiKeyboard) {
      setState(() => _showEmojiKeyboard = false);
      FocusScope.of(context).requestFocus(focusNode);
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() => _showEmojiKeyboard = true);
      });
    }
  }

  Future<void> createGroup(String groupName, List<String> memberEmails) async {
    final groupDoc = await FirebaseFirestore.instance.collection('groups').add({
      'groupName': groupName,
      'members': memberEmails,
      'lastMessage': '',
      'lastMessageTime': null,
    });

    // Optionally send a welcome message
    await groupDoc.collection('messages').add({
      'senderId': 'system',
      'message': 'Group "$groupName" created.',
      'timestamp': Timestamp.now(),
    });
  }

  void _navigateToGroupChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Group Chat")),
          body: Center(
            child: Text("Welcome to group: ${_groupNameController.text}"),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickGroupImage,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        _groupImage != null ? FileImage(_groupImage!) : null,
                    child: _groupImage == null
                        ? const Icon(Icons.camera_alt, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GroupNameInputField(
                    controller: _groupNameController,
                    focusNode: focusNode,
                    onTap: () {
                      if (_showEmojiKeyboard) {
                        setState(() => _showEmojiKeyboard = false);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: (_showEmojiKeyboard)
                      ? const Icon(Icons.emoji_emotions_outlined)
                      : const Icon(Icons.keyboard),
                  onPressed: _toggleEmojiKeyboard,
                ),
              ],
            ),
          ),

          // Selected Participants as Chips
          if (widget.selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selectedUsers.map((user) {
                  return Chip(
                    elevation: 10,
                    label: Text(user['name']),
                    avatar: const CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.blueGrey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const Spacer(),
          // Emoji Picker (if shown)
          Align(
            alignment: Alignment.bottomCenter,
            child: Offstage(
              offstage: !_showEmojiKeyboard,
              child: SizedBox(
                height: 300,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                  config: const Config(),
                ),
              ),
            ),
          ),
        ],
      ),

      // FAB to navigate
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToGroupChatScreen,
        icon: const Icon(Icons.check),
        label: const Text("Create"),
      ),
    );
  }
}
