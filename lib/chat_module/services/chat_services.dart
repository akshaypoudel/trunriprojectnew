import 'dart:developer';

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
    String currentUserEmail = _auth.currentUser!.email ?? '';
    String userName = _auth.currentUser!.displayName ?? 'Unknown user';
    Timestamp timeStamp = Timestamp.now();

    dynamic snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(_auth.currentUser!.uid)
        .get();

    if (snapshot.exists) {
      userName = snapshot.get('name') ?? '';
      currentUserEmail = snapshot.get('email') ?? '';
    } else {
      userName = 'Unknown User';
    }

    Message newMessage = Message(
      senderID: currentUserEmail,
      senderName: userName,
      message: message,
      timestamp: timeStamp,
      receiverID: receiverID,
    );

    List<String> ids = [currentUserEmail, receiverID];
    ids.sort();
    String chatRoomId = ids.join('_');
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot<Object?>> getMessages(
      String senderID, String receiverID) {
    List<String> ids = [receiverID, senderID];
    ids.sort();
    String chatRoomId = ids.join('_');
    log("chat room id ppppppppppppppppppp = $chatRoomId");

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
