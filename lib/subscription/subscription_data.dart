import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum PlanType { free, individual, businessBasic, businessPremium }

enum FeatureType {
  // Individual Plan Features
  socialFeatures,
  eventAlerts,
  eventBookings,

  // Business Plan Features
  businessContent,
  offersUploads,
  leadGeneration,

  // Upload limits
  unlimitedUploads,
  limitedUploads, // 10 per day
}

class SubscriptionData extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Original properties (keeping for backward compatibility)
  bool _isUserSubscribed = false;
  List<Map<String, String>> _features = [];

  // New enhanced properties
  PlanType _currentPlan = PlanType.free;
  String _planType = '';
  String _billingType = '';
  String _planName = '';
  Map<String, dynamic>? _subscriptionDetails;

  // Upload tracking
  int _dailyUploadCount = 0;
  DateTime? _lastUploadDate;

  // Getters (maintaining backward compatibility)
  bool get isUserSubscribed => _isUserSubscribed;
  List<Map<String, String>> get features => _features;

  // New getters
  PlanType get currentPlan => _currentPlan;
  String get planType => _planType;
  String get billingType => _billingType;
  String get planName => _planName;
  int get dailyUploadCount => _dailyUploadCount;
  int get remainingUploads => getRemainingUploads();
  Map<String, dynamic>? get subscriptionDetails => _subscriptionDetails;

  // Legacy methods (maintaining backward compatibility)
  void setFeatures(List<Map<String, String>> newFeatures) {
    _features = newFeatures;
    notifyListeners();
  }

  void changeSubscriptionStatus(bool isSubscribed) {
    _isUserSubscribed = isSubscribed;
    if (!isSubscribed) {
      _currentPlan = PlanType.free;
      _planType = '';
      _billingType = '';
      _planName = '';
    }
    notifyListeners();
  }

  // Enhanced subscription status fetching
  Future<void> fetchSubscriptionStatus() async {
    final uid = _firebaseAuth.currentUser?.uid;

    if (uid == null) return;

    try {
      final doc = await _firestore.collection('User').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        final isSubscribed = data?['isSubscribed'] ?? false;

        _isUserSubscribed = isSubscribed;

        if (isSubscribed) {
          _planType = data?['planType'] ?? '';
          _billingType = data?['billingType'] ?? '';
          _currentPlan = _determinePlanType(_planType, _billingType);

          // Fetch detailed plan information
          await _fetchPlanDetails();

          // Initialize upload tracking
          // await _initializeUploadTracking(uid);
        } else {
          _resetToFreeplan();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching subscription status: $e');
      log('Error fetching subscription status: $e');
    }
  }

  void _resetToFreeplan() {
    _currentPlan = PlanType.free;
    _planType = '';
    _billingType = '';
    _planName = '';
    _subscriptionDetails = null;
    _isUserSubscribed = false;
    _dailyUploadCount = 0;
  }

  PlanType _determinePlanType(String planType, String billingType) {
    if (!_isUserSubscribed) return PlanType.free;

    switch (planType.toLowerCase()) {
      case 'individual':
        return PlanType.individual;
      case 'business':
        return billingType.toLowerCase() == 'premium'
            ? PlanType.businessPremium
            : PlanType.businessBasic;
      default:
        return PlanType.free;
    }
  }

  Future<void> _fetchPlanDetails() async {
    try {
      final subscriptionDoc = await _firestore
          .collection('SubscriptionPlans')
          .doc('SubscriptionsPlans')
          .get();

      if (subscriptionDoc.exists) {
        final subscriptionData = subscriptionDoc.data() as Map<String, dynamic>;
        _subscriptionDetails = subscriptionData;

        if (_planType == 'individual') {
          final plans =
              subscriptionData['individual']?['plans'] as Map<String, dynamic>?;
          _planName = plans?[_billingType]?['name'] ?? 'Individual Plan';

          // Set individual features
          final individualFeatures = subscriptionData['individual']?['features']
              as Map<String, dynamic>?;
          if (individualFeatures != null) {
            _features = individualFeatures.values
                .map<Map<String, String>>((feature) => {
                      'title': feature['title']?.toString() ?? '',
                      'description': feature['description']?.toString() ?? '',
                    })
                .toList();
          }
        } else if (_planType == 'business') {
          final plans =
              subscriptionData['business']?['plans'] as Map<String, dynamic>?;
          _planName = plans?[_billingType]?['name'] ?? 'Business Plan';

          // Set business features (includes individual features)
          await _setBusinessFeatures(subscriptionData);
        }
      }
    } catch (e) {
      debugPrint('Error fetching plan details: $e');
      log('Error fetching plan details: $e');
    }
  }

  Future<void> _setBusinessFeatures(
      Map<String, dynamic> subscriptionData) async {
    List<Map<String, String>> businessFeatures = [];

    // Add individual features first
    final individualFeatures =
        subscriptionData['individual']?['features'] as Map<String, dynamic>?;
    if (individualFeatures != null) {
      businessFeatures.addAll(individualFeatures.values
          .map<Map<String, String>>((feature) => {
                'title': feature['title']?.toString() ?? '',
                'description': feature['description']?.toString() ?? '',
              })
          .toList());
    }

    // Add business-specific features
    final businessFeaturesData =
        subscriptionData['business']?['features'] as Map<String, dynamic>?;
    if (businessFeaturesData != null) {
      if (_billingType == 'basic') {
        // Basic plan gets features 1 and 2
        final basicFeatureIds = ['1', '2'];
        final basicFeatures = businessFeaturesData.entries
            .where((entry) => basicFeatureIds.contains(entry.value['id']))
            .map<Map<String, String>>((entry) => {
                  'title': entry.value['title']?.toString() ?? '',
                  'description': entry.value['description']?.toString() ?? '',
                })
            .toList();
        businessFeatures.addAll(basicFeatures);
      } else if (_billingType == 'premium') {
        // Premium plan gets all business features
        final premiumFeatures = businessFeaturesData.values
            .map<Map<String, String>>((feature) => {
                  'title': feature['title']?.toString() ?? '',
                  'description': feature['description']?.toString() ?? '',
                })
            .toList();
        businessFeatures.addAll(premiumFeatures);
      }
    }

    _features = businessFeatures;
  }

  Future<void> _initializeUploadTracking(String uid) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final uploadDoc =
          await _firestore.collection('UserUploads').doc(uid).get();

      if (uploadDoc.exists) {
        final uploadData = uploadDoc.data() as Map<String, dynamic>;
        final lastDate = uploadData['lastUploadDate'] as String?;

        if (lastDate == dateKey) {
          _dailyUploadCount = uploadData['dailyCount'] ?? 0;
        } else {
          // Reset count for new day
          _dailyUploadCount = 0;
          await _resetDailyUploadCount(uid, dateKey);
        }
      } else {
        // Create initial upload tracking document
        await _resetDailyUploadCount(uid, dateKey);
      }

      _lastUploadDate = today;
    } catch (e) {
      debugPrint('Error initializing upload tracking: $e');
      log('Error initializing upload tracking: $e');
    }
  }

  // Feature Access Control Methods
  bool hasFeature(FeatureType feature) {
    switch (_currentPlan) {
      case PlanType.free:
        return false;

      case PlanType.individual:
        return _hasIndividualFeature(feature);

      case PlanType.businessBasic:
        return _hasBusinessBasicFeature(feature);

      case PlanType.businessPremium:
        return _hasBusinessPremiumFeature(feature);
    }
  }

  bool _hasIndividualFeature(FeatureType feature) {
    const individualFeatures = [
      FeatureType.socialFeatures,
      FeatureType.eventAlerts,
      FeatureType.eventBookings,
    ];
    return individualFeatures.contains(feature);
  }

  bool _hasBusinessBasicFeature(FeatureType feature) {
    const businessBasicFeatures = [
      // All individual features
      FeatureType.socialFeatures,
      FeatureType.eventAlerts,
      FeatureType.eventBookings,
      // Business basic features
      FeatureType.businessContent,
      FeatureType.offersUploads,
      FeatureType.limitedUploads, // 10 per day
    ];
    return businessBasicFeatures.contains(feature);
  }

  bool _hasBusinessPremiumFeature(FeatureType feature) {
    const businessPremiumFeatures = [
      // All individual features
      FeatureType.socialFeatures,
      FeatureType.eventAlerts,
      FeatureType.eventBookings,
      // All business features
      FeatureType.businessContent,
      FeatureType.offersUploads,
      FeatureType.leadGeneration,
      FeatureType.unlimitedUploads,
    ];
    return businessPremiumFeatures.contains(feature);
  }

  // Upload Management
  bool canUpload() {
    if (!_isUserSubscribed) return false;

    switch (_currentPlan) {
      case PlanType.individual:
        return false; // Individual plans don't have upload feature

      case PlanType.businessBasic:
        return _dailyUploadCount < 10; // 10 uploads per day limit

      case PlanType.businessPremium:
        return true; // Unlimited uploads

      case PlanType.free:
      default:
        return false;
    }
  }

  int getRemainingUploads() {
    switch (_currentPlan) {
      case PlanType.businessBasic:
        return (10 - _dailyUploadCount).clamp(0, 10);
      case PlanType.businessPremium:
        return -1; // -1 indicates unlimited
      default:
        return 0;
    }
  }

  Future<bool> recordUpload() async {
    if (!canUpload()) return false;

    try {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) return false;

      _dailyUploadCount++;

      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore.collection('UserUploads').doc(uid).set({
        'dailyCount': _dailyUploadCount,
        'lastUploadDate': dateKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error recording upload: $e');
      log('Error recording upload: $e');
      return false;
    }
  }

  Future<void> _resetDailyUploadCount(String uid, String dateKey) async {
    try {
      await _firestore.collection('UserUploads').doc(uid).set({
        'dailyCount': 0,
        'lastUploadDate': dateKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error resetting upload count: $e');
      log('Error resetting upload count: $e');
    }
  }

  // Convenience getters for easy UI access
  bool get canAccessSocialFeatures => hasFeature(FeatureType.socialFeatures);
  bool get canAccessEventAlerts => hasFeature(FeatureType.eventAlerts);
  bool get canAccessEventBookings => hasFeature(FeatureType.eventBookings);
  bool get canAccessBusinessContent => hasFeature(FeatureType.businessContent);
  bool get canAccessOffersUploads => hasFeature(FeatureType.offersUploads);
  bool get canAccessLeadGeneration => hasFeature(FeatureType.leadGeneration);

  // Get user-friendly plan description
  String get planDescription {
    switch (_currentPlan) {
      case PlanType.free:
        return 'Free Plan - Limited Access';
      case PlanType.individual:
        return _planName.isNotEmpty
            ? _planName
            : 'Individual Plan - Premium Features';
      case PlanType.businessBasic:
        return _planName.isNotEmpty
            ? '$_planName - 10 uploads/day'
            : 'Business Basic - 10 uploads/day';
      case PlanType.businessPremium:
        return _planName.isNotEmpty
            ? '$_planName - Unlimited'
            : 'Business Premium - Unlimited';
    }
  }

  // Get upload limit description
  String get uploadLimitDescription {
    switch (_currentPlan) {
      case PlanType.businessBasic:
        return '$_dailyUploadCount/10 uploads used today';
      case PlanType.businessPremium:
        return 'Unlimited uploads';
      default:
        return 'No upload access';
    }
  }

  // Method to refresh subscription data (useful for real-time updates)
  Future<void> refreshSubscriptionData() async {
    await fetchSubscriptionStatus();
  }

  // Check if a specific plan type is active
  bool isPlanActive(PlanType planType) {
    return _currentPlan == planType;
  }

  // Get remaining days of subscription (if you have expiry date)
  Future<int> getRemainingDays() async {
    try {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) return 0;

      final doc = await _firestore.collection('User').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final expiryTimestamp = data?['subscriptionExpiry'] as Timestamp?;

        if (expiryTimestamp != null) {
          final expiryDate = expiryTimestamp.toDate();
          final now = DateTime.now();
          final difference = expiryDate.difference(now).inDays;
          return difference > 0 ? difference : 0;
        }
      }
    } catch (e) {
      debugPrint('Error getting remaining days: $e');
    }

    return 0;
  }
}
