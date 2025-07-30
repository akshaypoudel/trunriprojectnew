import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/chat_module/components/show_user_tiles.dart';
import 'package:trunriproject/chat_module/screens/group_name_screen.dart';
import 'package:trunriproject/chat_module/services/chat_services.dart';

class GroupChatCreateScreen extends StatefulWidget {
  const GroupChatCreateScreen({super.key});

  @override
  State<GroupChatCreateScreen> createState() => _GroupChatCreateScreenState();
}

class _GroupChatCreateScreenState extends State<GroupChatCreateScreen> {
  final ChatServices chatService = ChatServices();
  List<Map<String, dynamic>> userList = [];
  Set<String> selectedUserEmails = {};
  Map<String, String> emailToNameMap = {};
  bool isLoading = true;
  String? currentUserEmail = '';
  String? currentUserName = '';
  List<String> friendEmails = [];

  @override
  void initState() {
    super.initState();
    fetchFriendsAndUsers();
  }

  Future<void> fetchFriendsAndUsers() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUserId)
          .get();

      currentUserEmail = currentUserDoc.get('email');
      currentUserName = currentUserDoc.get('name');
      friendEmails = List<String>.from(currentUserDoc.get('friends') ?? []);

      if (friendEmails.isEmpty) {
        setState(() {
          userList = [];
          isLoading = false;
        });
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('email', whereIn: friendEmails)
          .get();

      final filteredUsers = querySnapshot.docs.map((doc) {
        return {
          'name': doc.get('name'),
          'email': doc.get('email'),
        };
      }).toList();

      emailToNameMap = {
        for (var user in filteredUsers) user['email']: user['name']
      };

      setState(() {
        userList = filteredUsers;
        isLoading = false;
      });
    } catch (e) {
      log('Error fetching friends: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleUserSelection(String email) {
    setState(() {
      if (selectedUserEmails.contains(email)) {
        selectedUserEmails.remove(email);
      } else {
        selectedUserEmails.add(email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (selectedUserEmails.isEmpty)
            ? const Text('New Group')
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('New Group'),
                  const SizedBox(width: 5),
                  Text(
                    '(${selectedUserEmails.length} of ${userList.length})',
                    style: const TextStyle(fontSize: 15),
                  )
                ],
              ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 15.0, bottom: 6, top: 10),
            child: Text(
              'Add Participant',
              style: TextStyle(fontSize: 20),
            ),
          ),
          if (selectedUserEmails.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: selectedUserEmails.map((email) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(emailToNameMap[email] ?? email),
                      onDeleted: () {
                        setState(() {
                          selectedUserEmails.remove(email);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : userList.isEmpty
                    ? const Center(
                        child: Text(
                          "Please add some friends before creating a group.",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: userList.length,
                        itemBuilder: (context, index) {
                          final user = userList[index];
                          final email = user['email'];
                          final isSelected = selectedUserEmails.contains(email);

                          return GestureDetector(
                            onTap: () => toggleUserSelection(email),
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                ShowUserTiles(
                                  userName: user['name'],
                                  onTap: () => toggleUserSelection(email),
                                ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 25),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: selectedUserEmails.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final userSet = selectedUserEmails.toSet();
                userSet.add(currentUserEmail!);
                final selectedNewUserList = userSet.map((email) {
                  return {
                    'email': email,
                    'name': (email == currentUserEmail)
                        ? "$currentUserName (You)"
                        : emailToNameMap[email] ?? '',
                  };
                }).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupNameScreen(
                      selectedUsers: selectedNewUserList,
                      selectedUsersSet: userSet,
                    ),
                  ),
                );
              },
              label: const Text('Next'),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }
}
