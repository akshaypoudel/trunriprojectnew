import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:image_picker/image_picker.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:trunriproject/chat_module/screens/group_chat_screen.dart';
import 'package:trunriproject/widgets/helper.dart';

class GroupNameScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedUsers;
  final Set<String> selectedUsersSet;

  const GroupNameScreen({
    super.key,
    required this.selectedUsers,
    required this.selectedUsersSet,
  });

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

  // void _onEmojiSelected(Emoji emoji) {
  //   _groupNameController.text += emoji.emoji;
  // }

  // void _toggleEmojiKeyboard() {
  //   if (_showEmojiKeyboard) {
  //     setState(() => _showEmojiKeyboard = false);
  //     FocusScope.of(context).requestFocus(focusNode);
  //   } else {
  //     FocusScope.of(context).unfocus();
  //     Future.delayed(const Duration(milliseconds: 200), () {
  //       setState(() => _showEmojiKeyboard = true);
  //     });
  //   }
  // }

  Future<void> createGroup(String groupName, Set<String> memberEmails) async {
    if (groupName.trim().isEmpty) {
      showSnackBar(context, 'Please enter a group name');
      return;
    }

    File? groupImageFile = _groupImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepOrange,
                          Colors.orange.shade400,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Creating Your Group',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Setting up your group chat...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
        'senderID': 'system',
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
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupInfoSection(),
              const SizedBox(height: 24),
              _buildSelectedMembersSection(),
              const SizedBox(height: 20),
              // _buildEmojiPicker(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCreateButton(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Text(
            'Set group name and photo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.orange.shade200,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupInfoSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Group Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Group Image Picker
              GestureDetector(
                onTap: _pickGroupImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.orange.shade50,
                    backgroundImage:
                        _groupImage != null ? FileImage(_groupImage!) : null,
                    child: _groupImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 27,
                                color: Colors.deepOrange,
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Group Name Input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _groupNameController.text.isNotEmpty
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _groupNameController,
                        focusNode: focusNode,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter group name...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          // suffixIcon: Container(
                          //   margin: const EdgeInsets.all(6),
                          //   decoration: BoxDecoration(
                          //     color: _showEmojiKeyboard
                          //         ? Colors.deepOrange
                          //         : Colors.orange.shade100,
                          //     borderRadius: BorderRadius.circular(10),
                          //   ),
                          //   child: IconButton(
                          //     icon: Icon(
                          //       _showEmojiKeyboard
                          //           ? Icons.keyboard_rounded
                          //           : Icons.emoji_emotions_rounded,
                          //       color: _showEmojiKeyboard
                          //           ? Colors.white
                          //           : Colors.deepOrange,
                          //       size: 20,
                          //     ),
                          //     onPressed: _toggleEmojiKeyboard,
                          //   ),
                          // ),
                        ),
                        onChanged: (value) => setState(() {}),
                        onTap: () {
                          if (_showEmojiKeyboard) {
                            setState(() => _showEmojiKeyboard = false);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMembersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.deepOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Group Members',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.selectedUsers.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.selectedUsers.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.selectedUsers.map((user) {
                final isCurrentUser = user['name'].contains('(You)');
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isCurrentUser
                        ? LinearGradient(
                            colors: [
                              Colors.deepOrange,
                              Colors.orange.shade400,
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade50,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentUser
                          ? Colors.transparent
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isCurrentUser
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.deepOrange,
                        child: Text(
                          user['name'][0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCurrentUser ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Widget _buildEmojiPicker() {
  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     height: _showEmojiKeyboard ? 300 : 0,
  //     child: Container(
  //       margin: const EdgeInsets.symmetric(horizontal: 20),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.1),
  //             blurRadius: 20,
  //             offset: const Offset(0, -5),
  //           ),
  //         ],
  //       ),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(20),
  //         child: EmojiPicker(
  //           onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
  //           config: Config(
  //             height: 280,
  //             emojiViewConfig: const EmojiViewConfig(
  //               backgroundColor: Colors.white,
  //               columns: 8,
  //               emojiSizeMax: 28,
  //             ),
  //             categoryViewConfig: const CategoryViewConfig(
  //               backgroundColor: Colors.white,
  //               iconColorSelected: Colors.deepOrange,
  //               backspaceColor: Colors.deepOrange,
  //             ),
  //             bottomActionBarConfig: BottomActionBarConfig(
  //               backgroundColor: Colors.grey.shade50,
  //               buttonColor: Colors.orange.shade100,
  //               buttonIconColor: Colors.deepOrange,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCreateButton() {
    final bool canCreate = _groupNameController.text.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: canCreate
            ? LinearGradient(
                colors: [
                  Colors.deepOrange,
                  Colors.orange.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade400,
                ],
              ),
        boxShadow: canCreate
            ? [
                BoxShadow(
                  color: Colors.deepOrange.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: FloatingActionButton.extended(
        onPressed: canCreate
            ? () =>
                createGroup(_groupNameController.text, widget.selectedUsersSet)
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_rounded,
                color: canCreate ? Colors.white : Colors.grey.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Create Group',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: canCreate ? Colors.white : Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
