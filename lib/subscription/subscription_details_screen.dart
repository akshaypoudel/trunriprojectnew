import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({super.key});

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> purchaseHistory = [];
  String planName = '';
  String planType = '';
  String billingType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionData();
  }

  Future<void> _fetchSubscriptionData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user subscription data
        final userDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          userData = userDoc.data();
          planType = userData?['planType'] ?? 'individual';
          billingType = userData?['billingType'] ?? 'annual';

          log('User plan type: $planType');
          log('User billing type: $billingType');

          // Fetch plan name from SubscriptionPlans
          await _fetchPlanName();
        }

        // Fetch purchase history
        final purchaseQuery = await FirebaseFirestore.instance
            .collection('purchases')
            .where('userID', isEqualTo: user.uid)
            .orderBy('purchaseDate', descending: true)
            .get();

        purchaseHistory = purchaseQuery.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
      }
    } catch (e) {
      log('Error fetching subscription data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchPlanName() async {
    try {
      final subscriptionDoc = await FirebaseFirestore.instance
          .collection('SubscriptionPlans')
          .doc('SubscriptionsPlans')
          .get();

      if (subscriptionDoc.exists) {
        final subscriptionData = subscriptionDoc.data() as Map<String, dynamic>;

        // Get plan name based on user's plan type and billing type
        if (planType == 'individual') {
          final individualData = subscriptionData['individual'];
          if (individualData != null) {
            final plans = individualData['plans'] as Map<String, dynamic>?;
            if (plans != null && plans.containsKey(billingType)) {
              planName = plans[billingType]['name'] ?? 'Pro';
            }
          }
        } else if (planType == 'business') {
          final businessData = subscriptionData['business'];
          if (businessData != null) {
            final plans = businessData['plans'] as Map<String, dynamic>?;
            if (plans != null && plans.containsKey(billingType)) {
              planName = plans[billingType]['name'] ?? 'Business';
            }
          }
        }

        // Fallback plan names
        if (planName.isEmpty) {
          if (planType == 'business') {
            planName =
                billingType == 'basic' ? 'Business Basic' : 'Business Premium';
          } else {
            planName = billingType == 'monthly' ? 'Pro Monthly' : 'Pro Annual';
          }
        }

        log('Fetched plan name: $planName');
      }
    } catch (e) {
      log('Error fetching plan name: $e');
      // Set fallback plan name
      planName = 'Pro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLoading) ...[
                loadingUI(),
              ],
              if (!isLoading) ...[
                const SizedBox(height: 20),
                _buildSubscriptionStatusCard(),
                const SizedBox(height: 20),
                _buildSubscriptionDetailsCard(),
                const SizedBox(height: 20),
                _buildPurchaseHistoryCard(),
                const SizedBox(height: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget loadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange,
                  Colors.orange.shade400,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading subscription details...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Text(
            planName.isNotEmpty
                ? 'Manage your TruNri $planName'
                : 'Manage your TruNri Pro',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.orange.shade200,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatusCard() {
    final isSubscribed = userData?['isSubscribed'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSubscribed
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.red.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isSubscribed ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSubscribed ? Colors.green : Colors.red.shade600,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSubscribed ? Icons.verified_rounded : Icons.cancel_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSubscribed
                ? (planName.isNotEmpty
                    ? (planName.contains('Pro'))
                        ? '$planName Active'
                        : 'TruNri $planName Active'
                    : 'TruNri Pro Active')
                : 'Subscription Expired',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isSubscribed ? Colors.green.shade800 : Colors.red.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSubscribed
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSubscribed
                  ? (planType == 'business'
                      ? 'All business features unlocked'
                      : 'All premium features unlocked')
                  : 'Upgrade to access premium features',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isSubscribed ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetailsCard() {
    final subscriptionDate = userData?['subscriptionDate'] as Timestamp?;
    final subscriptionExpiry = userData?['subscriptionExpiry'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepOrange,
                        Colors.orange.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Details',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (planName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          planName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDetailRow(
            icon: Icons.label_rounded,
            title: 'Plan Type',
            value: planType == 'business' ? 'Business Plan' : 'Individual Plan',
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.credit_card_rounded,
            title: 'Billing Cycle',
            value: _getBillingCycleText(),
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.play_arrow_rounded,
            title: 'Start Date',
            value: subscriptionDate != null
                ? DateFormat('MMM dd, yyyy').format(subscriptionDate.toDate())
                : 'Not available',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.event_rounded,
            title: 'Expiry Date',
            value: subscriptionExpiry != null
                ? DateFormat('MMM dd, yyyy').format(subscriptionExpiry.toDate())
                : 'Not available',
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            title: 'Days Remaining',
            value: _calculateDaysRemaining(),
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getBillingCycleText() {
    if (planType == 'business') {
      return billingType == 'basic' ? 'Basic Plan' : 'Premium Plan';
    } else {
      return billingType == 'monthly' ? 'Monthly' : 'Annual';
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepOrange,
                        Colors.orange.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Purchase History',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${purchaseHistory.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (purchaseHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 32,
                      color: Colors.orange.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Purchase History',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your purchase history will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: purchaseHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final purchase = purchaseHistory[index];
                return _buildPurchaseItem(purchase);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(Map<String, dynamic> purchase) {
    final purchaseDate = purchase['purchaseDate'] as Timestamp?;
    final amount = purchase['amount'] ?? 'N/A';
    final plan = purchase['plan'] ??
        (planName.isNotEmpty ? planName : 'TruNri Pro Monthly');
    final status = purchase['status'] ?? 'Completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                purchaseDate != null
                    ? DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(purchaseDate.toDate())
                    : 'Date not available',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                amount == 'N/A' ? 'N/A' : '₹$amount',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateDaysRemaining() {
    final subscriptionExpiry = userData?['subscriptionExpiry'] as Timestamp?;
    final isSubscribed = userData?['isSubscribed'] ?? false;

    if (!isSubscribed || subscriptionExpiry == null) {
      return 'N/A';
    }

    final expiryDate = subscriptionExpiry.toDate();
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      return 'Expires Today';
    } else {
      return '$difference days';
    }
  }
}
