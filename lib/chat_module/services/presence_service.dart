import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> setUserOnline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('User').doc(user.uid);

    await userRef.update({
      'isOnline': true,
      'lastSeen': DateTime.now(),
    });
  }

  static Future<void> setUserOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('User').doc(user.uid);

    await userRef.update({
      'isOnline': false,
      'lastSeen': DateTime.now(),
    });
  }
}
