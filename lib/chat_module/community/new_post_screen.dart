import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  List<String> selectedTags = [];
  final List<String> _defaultTags = [
    'Legal',
    'Immigration',
    'Work',
    'Car Buying',
    'Banking'
  ];

  void _toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isNotEmpty && !selectedTags.contains(tag)) {
      setState(() {
        selectedTags.add(tag);
        _defaultTags.add(tag);
        _customTagController.clear();
      });
    }
  }

  Future<void> _submitPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    String userName = '';
    String photoUrl = '';
    final userSnap = await FirebaseFirestore.instance
        .collection('User')
        .doc(firebaseAuth.currentUser!.uid)
        .get();
    if (userSnap.exists) {
      userName = userSnap.data()!['name'];
      photoUrl = userSnap.data()!['profile'];
    }

    await FirebaseFirestore.instance.collection('community_posts').add({
      'uid': firebaseAuth.currentUser!.uid,
      'username': userName,
      'profileUrl': photoUrl,
      'content': content,
      'tags': selectedTags,
      'timestamp': FieldValue.serverTimestamp(),
      'replies': [],
      'isEdited': false
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _postController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'What do you want to share?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: _defaultTags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagController,
                      decoration: const InputDecoration(
                        hintText: 'Add your own tag',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addCustomTag,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.deepOrangeAccent,
                  ),
                  child: const Text('Post'),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
