import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DisplayGroupMembers extends StatefulWidget {
  final String groupId;

  const DisplayGroupMembers({super.key, required this.groupId});

  @override
  State<DisplayGroupMembers> createState() => _DisplayGroupMembersState();
}

class _DisplayGroupMembersState extends State<DisplayGroupMembers> {
  Map<String, dynamic>? groupData;
  List<Map<String, dynamic>> memberDetails = [];
  bool isLoading = true;
  String imageUrl = '';
  String groupName = 'Group';
  String createdBy = '';
  String createdByEmail = '';
  var createdAt = DateTime.timestamp();
  List groupMembers = [];

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!groupDoc.exists) return;

      final data = groupDoc.data()!;
      final members = List<String>.from(data['members']);
      final List<Map<String, dynamic>> fetchedMembers = [];

      for (final email in members) {
        final userSnap = await FirebaseFirestore.instance
            .collection('User')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userSnap.docs.isNotEmpty) {
          fetchedMembers.add(userSnap.docs.first.data());
          if (email == data['createdBy']) {
            createdBy = userSnap.docs.first.get('name');
          }
        }
      }

      setState(() {
        groupData = data;
        memberDetails = fetchedMembers;
        isLoading = false;
      });

      imageUrl = groupData!['imageUrl'] ?? '';
      groupName = groupData!['groupName'] ?? 'Group';
      createdByEmail = groupData!['createdBy'] ?? '';
      createdAt = (groupData!['createdAt'])?.toDate();
      groupMembers = groupData!['members'] as List;
    } catch (e) {
      debugPrint('Error loading group info: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (groupData == null) {
      return const Scaffold(
        body: Center(child: Text("Group not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group image
            (imageUrl != '')
                ? Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  )
                : const Center(
                    child: CircleAvatar(
                      radius: 60,
                      child: Icon(
                        Icons.group,
                        size: 80,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
            const SizedBox(height: 16),

            // Group title
            Center(
              child: Text(
                groupName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Member count
            Center(
              child: Text(
                "Group • ${groupMembers.length} Members",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // Created by + date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Created by: $createdBy ($createdByEmail)\nCreated on: ${createdAt != null ? "${createdAt.day}/${createdAt.month}/${createdAt.year}" : 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),

            const Divider(height: 30),
            const SizedBox(height: 16),

            // Members list
            Expanded(
              child: ListView.builder(
                itemCount: memberDetails.length,
                itemBuilder: (_, index) {
                  final member = memberDetails[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.blueGrey,
                      ),
                    ),
                    title: Text(member['name'] ?? ''),
                    subtitle: Text(member['email'] ?? ''),
                  );
                },
              ),
            ),

            // Exit group button
            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: OutlinedButton.icon(
            //     onPressed: () {
            //       // TODO: implement exit group logic
            //     },
            //     icon: const Icon(Icons.exit_to_app),
            //     label: const Text("Exit Group"),
            //     style: OutlinedButton.styleFrom(
            //       foregroundColor: Colors.red,
            //       side: const BorderSide(color: Colors.red),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
