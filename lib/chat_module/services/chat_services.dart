import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/context_chats/models/context_chats.dart';
import 'package:trunriproject/chat_module/models/message.dart';
import 'package:trunriproject/subscription/subscription_data.dart';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUserStream() {
    final userSnapshot =
        _firestore.collection("User").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
    return userSnapshot;
  }

  Stream<List<Map<String, dynamic>>> getGroupStream() {
    final groupSnapShot =
        _firestore.collection('groups').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
    return groupSnapShot;
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
      isReported: false,
    );

    List<String> ids = [currentUserEmail, receiverID];
    ids.sort();
    String chatRoomId = ids.join('_');
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection("chat_messages")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot<Object?>> getMessages(
      String senderID, String receiverID) {
    List<String> ids = [receiverID, senderID];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("chat_messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  ///////////////////////////////
  ///Context Based Chat Services.
  ///

  Future<ContextChat> openContextChat({
    required String postId,
    required String postType,
    required String posterId,
    required String seekerId,
    required String postTitle,
    required String postCity,
    required String postState,
    required String seekerName,
    required String posterName,
  }) async {
    final query = await _firestore
        .collection('contextChats')
        .where('postId', isEqualTo: postId)
        .where('seekerId', isEqualTo: seekerId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ContextChat.fromDoc(query.docs.first);
    }

    // final userName = await fetchUserName();

    final docRef = await _firestore.collection('contextChats').add({
      'postId': postId,
      'postType': postType,
      'posterId': posterId,
      'seekerId': seekerId,
      'createdAt': FieldValue.serverTimestamp(),
      'isClosed': false,
      'postTitle': postTitle,
      'city': postCity,
      'state': postState,
      'seekerName': seekerName,
      'posterName': posterName,
    });

    final doc = await docRef.get();
    return ContextChat.fromDoc(doc);
  }

  Future<bool> canSendMessage({
    required String chatId,
    required String userId,
  }) async {
    final chatDoc =
        await _firestore.collection('contextChats').doc(chatId).get();
    final data = chatDoc.data()!;
    final isSeeker = data['seekerId'] == userId;

    if (!isSeeker) return true; // Poster always allowed

    final counterRef = _firestore
        .collection('contextChats')
        .doc(chatId)
        .collection('counters')
        .doc('messageCount');

    final counterDoc = await counterRef.get();
    final sent = counterDoc.exists ? counterDoc.data()!['count'] as int : 0;

    if (sent < 2) {
      await counterRef.set({'count': sent + 1});
      return true;
    }
    return false;
  }

  Stream<QuerySnapshot> messagesStream(String chatId) {
    return _firestore
        .collection('contextChats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendContextMessage({
    required String chatId,
    required String senderId,
    required String text,
    required BuildContext context,
  }) async {
    final provider = Provider.of<SubscriptionData>(context, listen: false);

    final chatDoc =
        await _firestore.collection('contextChats').doc(chatId).get();
    final data = chatDoc.data()!;
    final isSeeker = data['seekerId'] == senderId;

    if (isSeeker && !provider.isUserSubscribed) {
      final counterRef = _firestore
          .collection('contextChats')
          .doc(chatId)
          .collection('counters')
          .doc('messageCount');

      final counterDoc = await counterRef.get();
      final sent = counterDoc.exists ? counterDoc.data()!['count'] as int : 0;

      if (sent < 2) {
        await counterRef.set({'count': sent + 1});
      }
    }

    await _firestore
        .collection('contextChats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendContextMessage1({
    required String chatId,
    required String senderId,
    required String text,
    required BuildContext context,
  }) async {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    if (!provider.isUserSubscribed) {
      final allowed = await canSendMessage(chatId: chatId, userId: senderId);
      if (!allowed) {
        throw 'SUBSCRIPTION_REQUIRED';
      }
    }
    await _firestore
        .collection('contextChats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
