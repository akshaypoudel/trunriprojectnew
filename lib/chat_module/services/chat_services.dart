import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trunriproject/chat_module/models/message.dart';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("User").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Future<void> sendMessage(String receiverID, message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String phoneNumber = _auth.currentUser!.phoneNumber!;
    final String userName = _auth.currentUser!.displayName!;
    final Timestamp timeStamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserId,
      senderName: userName,
      message: message,
      timestamp: timeStamp,
      receiverID: receiverID,
    );

    List<String> ids = [currentUserId, receiverID];
    ids.sort();
    String chatRoomId = ids.join('_');
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
