import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionData extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isUserSubscribed = false;

  bool get isUserSubscribed => _isUserSubscribed;

  void changeSubscriptionStatus(bool isSubscribed) {
    _isUserSubscribed = isSubscribed;
    notifyListeners();
  }

  Future<void> fetchSubscriptionStatus() async {
    final uid = _firebaseAuth.currentUser?.uid;

    if (uid == null) return;

    try {
      final doc = await _firestore.collection('User').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        final isSubscribed = data?['isSubscribed'] ?? false;

        _isUserSubscribed = isSubscribed;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching subscription status: $e');
    }
  }
}
