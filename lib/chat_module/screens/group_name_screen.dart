import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:trunriproject/chat_module/components/chat_inputfield.dart';
import 'package:trunriproject/chat_module/screens/group_chat_screen.dart';
import 'package:trunriproject/widgets/helper.dart';

class GroupNameScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedUsers;
  final Set<String> selectedUsersSet;

  const GroupNameScreen(
      {super.key, required this.selectedUsers, required this.selectedUsersSet});

  @override
  State<GroupNameScreen> createState() => _GroupNameScreenState();
}

class _GroupNameScreenState extends State<GroupNameScreen> {
  File? _groupImage;
  final TextEditingController _groupNameController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _showEmojiKeyboard = false;
  String currentUserName = '';
  String currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    fetchCurrentUserEmail();
  }

  Future<void> fetchCurrentUserEmail() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (snapshot.exists) {
      setState(() {
        currentUserName = snapshot.get('name');
        currentUserEmail = snapshot.get('email');
      });
    }
  }

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

  Future<void> createGroup(String groupName, Set<String> memberEmails) async {
    File? groupImageFile = _groupImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text("Creating your Group...")),
              ],
            ),
          ),
        );
      },
    );
    try {
      String? imageUrl;

      // Upload group image if provided
      if (groupImageFile != null) {
        final fileName = path.basename(groupImageFile.path);
        final storageRef =
            FirebaseStorage.instance.ref().child('group_icons/$fileName');
        final uploadTask = await storageRef.putFile(groupImageFile);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Create group document
      final groupDoc =
          await FirebaseFirestore.instance.collection('groups').add({
        'groupName': groupName,
        'members': memberEmails,
        'lastMessage': '',
        'lastMessageTime': null,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'createdBy': currentUserEmail,
        'senderID': 'system', // use this as an identifier
        'message': 'created',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      Navigator.pop(context); // close AlertDialog
      Navigator.pop(context); // close group name screen
      Navigator.pop(context); // close group chat create screen

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => GroupChatScreen(
            groupName: groupName,
            groupImageUrl: imageUrl,
            groupId: groupDoc.id,
          ),
        ),
      );
    } catch (e) {
      log('Error creating group: $e');

      // Close loading dialog if open
      Navigator.pop(context);

      showSnackBar(context, 'Failed to create group');
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
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
                        backgroundImage: _groupImage != null
                            ? FileImage(_groupImage!)
                            : null,
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                    'Selected Participant: ${widget.selectedUsers.length}'),
              ),

              if (widget.selectedUsers.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Wrap(
                    direction: Axis.vertical,
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
              const SizedBox(
                width: 10,
                height: 20,
              ),
              // const Spacer(),
              // Emoji Picker (if shown)
              Align(
                alignment: Alignment.bottomCenter,
                child: Offstage(
                  offstage: !_showEmojiKeyboard,
                  child: SizedBox(
                    height: 300,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) =>
                          _onEmojiSelected(emoji),
                      config: const Config(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // FAB to navigate
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          createGroup(_groupNameController.text, widget.selectedUsersSet);
        },
        icon: const Icon(Icons.check),
        label: const Text("Create"),
      ),
    );
  }
}
