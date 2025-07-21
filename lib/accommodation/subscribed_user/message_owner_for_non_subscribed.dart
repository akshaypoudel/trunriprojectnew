import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageOwnerScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;
  final String propertyTitle;

  const MessageOwnerScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    required this.propertyTitle,
  });

  @override
  State<MessageOwnerScreen> createState() => _MessageOwnerScreenState();
}

class _MessageOwnerScreenState extends State<MessageOwnerScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isSending = false;

  Future<void> sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _controller.text.trim().isEmpty) return;

    setState(() {
      isSending = true;
    });

    try {
      final chatRoomId = getChatRoomId(currentUser.uid, widget.ownerId);

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'text': _controller.text.trim(),
        'senderId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Optionally store/update chat room meta
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .set({
        'lastMessage': _controller.text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [currentUser.uid, widget.ownerId],
        'propertyTitle': widget.propertyTitle,
      }, SetOptions(merge: true));

      _controller.clear();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Message Sent"),
          content: const Text("You’ve messaged the property owner."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error sending message: $e");
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  String getChatRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Message ${widget.ownerName}"),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Only subscribers can view full conversations. You can message ${widget.ownerName} once to express interest.",
                style: GoogleFonts.urbanist(
                  color: Colors.orange.shade900,
                  fontSize: 14,
                ),
              ),
            ),
            TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                hintText: "Type your message here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSending ? null : sendMessage,
              icon: const Icon(Icons.send),
              label: const Text("Send Message"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
