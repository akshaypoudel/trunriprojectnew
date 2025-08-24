import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionData extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isUserSubscribed = false;

  bool get isUserSubscribed => _isUserSubscribed;

  List<Map<String, String>> _features = [];

  List<Map<String, String>> get features => _features;

  void setFeatures(List<Map<String, String>> newFeatures) {
    _features = newFeatures;
    notifyListeners();
  }

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

  Future<void> fetchSubscriptionFeatures() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptionData')
          .doc('subscriptionData') // replace with your actual doc id
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final featuresMap = data['features'] as Map<String, dynamic>?;

        if (featuresMap != null) {
          // Extract both title and description as Map<String, String>
          List<Map<String, String>> features = [];

          featuresMap.forEach((key, value) {
            final title = value['title'] as String? ?? "";
            final description = value['description'] as String? ?? "";
            final id = value['id'] as String? ?? '0';
            features
                .add({"title": title, "description": description, "id": id});
          });

          // Save to Provider
          // Provider.of<SubscriptionFeaturesProvider>(context, listen: false)
          //     .setFeatures(features);
          setFeatures(features);
          // return features;
        }
      }
    } catch (e) {
      log('Error fetching subscription features: $e');
    }
    // return [];
  }
}
