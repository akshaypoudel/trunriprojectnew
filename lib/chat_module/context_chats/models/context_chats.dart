// models/context_chat.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ContextChat {
  final String id;
  final String postId;
  final String postType; // 'job' or 'accommodation'
  final String posterId;
  final String seekerId;
  final Timestamp createdAt;
  final bool isClosed;

  ContextChat({
    required this.id,
    required this.postId,
    required this.postType,
    required this.posterId,
    required this.seekerId,
    required this.createdAt,
    required this.isClosed,
  });

  factory ContextChat.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContextChat(
      id: doc.id,
      postId: data['postId'],
      postType: data['postType'],
      posterId: data['posterId'],
      seekerId: data['seekerId'],
      createdAt: data['createdAt'],
      isClosed: data['isClosed'],
    );
  }
}
