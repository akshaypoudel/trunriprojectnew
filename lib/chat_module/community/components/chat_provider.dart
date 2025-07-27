import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String _profileImageUrl = '';
  String _userName = '';

  String get getProfileImage => _profileImageUrl;
  String get getUserName => _userName;

  void setProfileImage(String imageUrl) {
    _profileImageUrl = imageUrl;
    notifyListeners();
  }

  Future<void> fetchUserProfileImage() async {
    dynamic profileImageSnap =
        await firestore.collection('User').doc(auth.currentUser!.uid).get();

    if (profileImageSnap.exists) {
      _profileImageUrl = profileImageSnap.data()['profile'] ?? '';
      _userName = profileImageSnap.data()['name'] ?? 'Anonymous';

      notifyListeners();
    } else {
      log('profile image doesnt exists');
    }
  }
}
