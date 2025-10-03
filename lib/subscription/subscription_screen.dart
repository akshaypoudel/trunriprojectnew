import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/subscription/phone_number_verification.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_success_screen.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'package:uuid/uuid.dart';

const daysInAYear = (30 * 12);
const daysInAMonth = 30;

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;

  Map<String, dynamic>? subscriptionData;
  String selectedPlan = 'individual';
  String selectedBillingType = 'annual';
  bool isLoading = true;

  Uuid uuid = const Uuid();

  // User's current subscription info
  String? currentPlanType;
  String? currentBillingType;
  bool isUserSubscribed = false;

  // Available options based on current plan
  List<String> availablePlanTypes = [];
  List<String> availableBillingTypes = [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _fetchUserCurrentSubscription();
  }

  Future<void> _fetchUserCurrentSubscription() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Fetch user's current subscription
      final userDoc =
          await FirebaseFirestore.instance.collection('User').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        isUserSubscribed = userData['isSubscribed'] ?? false;
        currentPlanType = userData['planType'];
        currentBillingType = userData['billingType'];

        log('Current subscription - isSubscribed: $isUserSubscribed, planType: $currentPlanType, billingType: $currentBillingType');

        _determineAvailableOptions();
      }

      // Fetch subscription plans data
      await _fetchSubscriptionPlans();
    } catch (e) {
      log('Error fetching user subscription: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _determineAvailableOptions() {
    if (!isUserSubscribed || currentPlanType == null) {
      // New user - show all options
      availablePlanTypes = ['individual', 'business'];
      availableBillingTypes = ['annual', 'monthly']; // For individual
      selectedPlan = 'individual';
      selectedBillingType = 'annual';
    } else {
      // Existing user - determine upgrade options
      switch (currentPlanType) {
        case 'individual':
          if (currentBillingType == 'monthly') {
            // Individual monthly user can upgrade to annual or business
            availablePlanTypes = ['individual', 'business'];
            availableBillingTypes = [
              'annual'
            ]; // Only show annual for individual
            selectedPlan = 'individual';
            selectedBillingType = 'annual';
          } else {
            // Individual annual user can ONLY upgrade to business (no individual options)
            availablePlanTypes = ['business'];
            availableBillingTypes = [
              'basic',
              'premium'
            ]; // Show both business options
            selectedPlan = 'business';
            selectedBillingType = 'basic';
          }
          break;

        case 'business':
          if (currentBillingType == 'basic') {
            // Business basic user can only upgrade to premium
            availablePlanTypes = ['business'];
            availableBillingTypes = ['premium'];
            selectedPlan = 'business';
            selectedBillingType = 'premium';
          }
          // Business premium users shouldn't reach here
          break;

        default:
          availablePlanTypes = ['individual', 'business'];
          availableBillingTypes = ['annual'];
          selectedPlan = 'individual';
          selectedBillingType = 'annual';
      }
    }

    log('Available options - Plans: $availablePlanTypes, Billing: $availableBillingTypes');
    log('Selected - Plan: $selectedPlan, Billing: $selectedBillingType');
  }

  Future<void> _fetchSubscriptionPlans() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('SubscriptionPlans')
          .doc('SubscriptionsPlans')
          .get();

      log('Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        log('Document data: $data');

        setState(() {
          subscriptionData = data;
          isLoading = false;
        });
      } else {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('SubscriptionPlans')
            .get();

        log('Found ${querySnapshot.docs.length} documents in SubscriptionPlans collection');

        if (querySnapshot.docs.isNotEmpty) {
          final firstDoc = querySnapshot.docs.first;
          log('Using document with ID: ${firstDoc.id}');

          setState(() {
            subscriptionData = firstDoc.data() as Map<String, dynamic>?;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          showSnackBar(context, "Subscription plans not found");
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      log("Subscription plans fetch error: $e");
      showSnackBar(
          context, "Error loading subscription plans: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    log('razorpay payment successful = $response');
    _subscribeUserToProMembership();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    showSnackBar(context, "Payment failed. Please try again.");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    showSnackBar(context, "External Wallet selected: ${response.walletName}");
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.deepOrangeAccent,
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 181, 71),
            Color.fromARGB(255, 255, 132, 94)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FadeInDown(
                child: Text(
                  _getHeaderText(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isUserSubscribed) _buildCurrentPlanInfo(),
            const SizedBox(height: 20),
            Expanded(
              child: SlideInUp(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Plan Type Selection (only if multiple options available OR business only with explanation)
                        if (availablePlanTypes.length > 1 ||
                            (availablePlanTypes.length == 1 &&
                                availablePlanTypes.first == 'business')) ...[
                          FadeIn(
                            child: Text(
                              _getPlanSelectionTitle(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPlanTypeSelection(),
                          const SizedBox(height: 30),
                        ],

                        // Features Section
                        if (subscriptionData != null) ...[
                          if (selectedPlan == 'individual') ...[
                            ...buildIndividualFeatures(),
                            const SizedBox(height: 30),
                            if (availableBillingTypes.isNotEmpty)
                              buildIndividualPlanSelection(),
                          ] else if (selectedPlan == 'business') ...[
                            // Business Plan Comparison Table
                            buildBusinessComparisonTable(),
                          ],
                        ],

                        const SizedBox(height: 30),
                        BounceInUp(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.deepOrange,
                                  Colors.orangeAccent
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: startRazorpayTransaction,
                              child: Text(
                                _getSubscribeButtonText(),
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeaderText() {
    if (!isUserSubscribed) {
      return "Unlock all features and bonus content with PRO!";
    } else if (currentPlanType == 'individual') {
      return "Upgrade your plan for more features!";
    } else if (currentPlanType == 'business' && currentBillingType == 'basic') {
      return "Upgrade to Premium for unlimited access!";
    } else {
      return "Choose your upgrade plan!";
    }
  }

  String _getPlanSelectionTitle() {
    if (!isUserSubscribed) {
      return "Choose your plan type";
    } else {
      return "Select upgrade option";
    }
  }

  Widget _buildCurrentPlanInfo() {
    if (!isUserSubscribed) return const SizedBox.shrink();

    String currentPlanName = _getCurrentPlanDisplayName();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: Colors.green.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Plan",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  currentPlanName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPlanDisplayName() {
    if (currentPlanType == 'individual') {
      return currentBillingType == 'monthly'
          ? 'Individual Monthly'
          : 'Individual Annual';
    } else if (currentPlanType == 'business') {
      return currentBillingType == 'basic'
          ? 'Business Basic'
          : 'Business Premium';
    }
    return 'Unknown Plan';
  }

  Widget _buildPlanTypeSelection() {
    // If only business plans available, don't show selection
    if (availablePlanTypes.length == 1 &&
        availablePlanTypes.first == 'business') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.deepOrange, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.business, color: Colors.deepOrange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Business Plans",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Upgrade to unlock business features",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Original plan type selection for multiple options
    return Row(
      children: availablePlanTypes.map((planType) {
        bool isSelected = selectedPlan == planType;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: planType != availablePlanTypes.last ? 10 : 0),
            child: ZoomIn(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPlan = planType;
                    // Reset billing type based on new plan
                    if (planType == 'individual') {
                      selectedBillingType =
                          availableBillingTypes.contains('annual')
                              ? 'annual'
                              : 'monthly';
                    } else {
                      selectedBillingType =
                          availableBillingTypes.contains('basic')
                              ? 'basic'
                              : 'premium';
                    }
                  });
                },
                child: buildPlanTypeTile(
                  title: planType == 'individual' ? "Individual" : "Business",
                  description: planType == 'individual'
                      ? "For personal use"
                      : "For business use",
                  isSelected: isSelected,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSubscribeButtonText() {
    if (selectedPlan == 'business') {
      if (subscriptionData != null) {
        final businessPlans =
            subscriptionData!['business']['plans'] as Map<String, dynamic>?;
        if (businessPlans != null &&
            businessPlans.containsKey(selectedBillingType)) {
          final planPrice = businessPlans[selectedBillingType]['price'] ?? 0;
          if (planPrice == 0) {
            return "GET STARTED FOR FREE";
          }
        }
      }
      return isUserSubscribed ? "UPGRADE TO BUSINESS" : "SUBSCRIBE TO BUSINESS";
    } else {
      return isUserSubscribed ? "UPGRADE PLAN" : "SUBSCRIBE TO PRO";
    }
  }

  // Method to build individual features
  List<Widget> buildIndividualFeatures() {
    if (subscriptionData?['individual']?['features'] == null) return [];

    final features =
        subscriptionData!['individual']['features'] as Map<String, dynamic>;
    return features.values.map<Widget>((feature) {
      return buildFeatureRow(
        feature['title'] ?? '',
        feature['description'] ?? '',
        true,
      );
    }).toList();
  }

  // Update buildIndividualPlanSelection to only show available billing types
  Widget buildIndividualPlanSelection() {
    if (subscriptionData?['individual']?['plans'] == null ||
        availableBillingTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    final plans =
        subscriptionData!['individual']['plans'] as Map<String, dynamic>;

    return Column(
      children: [
        FadeIn(
          child: const Text(
            "Choose billing cycle",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: availableBillingTypes.map((billingType) {
            final plan = plans[billingType];
            if (plan == null) return const SizedBox.shrink();

            bool isSelected = selectedBillingType == billingType;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    right: billingType != availableBillingTypes.last ? 10 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBillingType = billingType;
                    });
                  },
                  child: buildPlanTile(
                    title: plan['name'],
                    price:
                        "\$${plan['price']}/${billingType == 'annual' ? 'year' : 'month'}",
                    subtitle: billingType == 'annual'
                        ? "Billed Annually"
                        : "Billed Monthly",
                    isSelected: isSelected,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper method to define which features belong to basic plan
  List<String> _getBasicPlanFeatures() {
    // Basic plan gets features "1" and "2"
    return ["1", "2"]; // Business Content and Offers & Uploads
  }

  // Helper method to define which features belong to premium plan
  List<String> _getPremiumPlanFeatures() {
    // Premium plan has all features
    return ["1", "2", "3"]; // All features including Lead Generation
  }

  // Method to build business comparison table
  Widget buildBusinessComparisonTable() {
    if (subscriptionData?['business'] == null) {
      return const SizedBox.shrink();
    }

    final businessData = subscriptionData!['business'];
    final features = businessData['features'] as Map<String, dynamic>;
    final plans = businessData['plans'] as Map<String, dynamic>;

    // Filter available business plans based on user's current subscription
    List<String> showablePlans = [];
    if (availableBillingTypes.contains('basic') &&
        availableBillingTypes.contains('premium')) {
      showablePlans = ['basic', 'premium'];
    } else if (availableBillingTypes.contains('premium')) {
      showablePlans = ['premium'];
    } else if (availableBillingTypes.contains('basic')) {
      showablePlans = ['basic'];
    } else {
      showablePlans = ['basic', 'premium']; // Fallback
    }

    // If only showing premium (for basic users upgrading)
    if (showablePlans.length == 1 && showablePlans.first == 'premium') {
      final premiumPlan = plans['premium'];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeIn(
            child: const Text(
              "Upgrade to Business Premium",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Show individual features first
          const Text(
            "Individual Plan Features (Included)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          if (subscriptionData?['individual']?['features'] != null) ...[
            ...subscriptionData!['individual']['features']
                .values
                .map<Widget>((feature) {
              return buildFeatureRowWithLabel(
                feature['title'] ?? '',
                feature['description'] ?? '',
                "INCLUDED",
                Colors.blue,
              );
            }).toList(),
          ],

          const SizedBox(height: 20),
          const Text(
            "Business Premium Features",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 10),
          ...features.values.map<Widget>((feature) {
            return buildFeatureRowWithLabel(
              feature['title'] ?? '',
              feature['description'] ?? '',
              "PREMIUM",
              Colors.purple,
            );
          }),

          const SizedBox(height: 20),
          _buildSelectedBusinessPlanPrice(),
        ],
      );
    }

    // Original comparison table for multiple business options
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeIn(
          child: const Text(
            "Business Plans Comparison",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Plan Headers
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 1,
                child: Text(
                  "Features",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (showablePlans.contains('basic'))
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBillingType = 'basic';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedBillingType == 'basic'
                            ? Colors.deepOrange
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedBillingType == 'basic'
                              ? Colors.deepOrange
                              : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Business Basic",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedBillingType == 'basic'
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$${plans['basic']['price']}/month",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: selectedBillingType == 'basic'
                                  ? Colors.white
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plans['basic']['note'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: selectedBillingType == 'basic'
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (showablePlans.contains('basic') &&
                  showablePlans.contains('premium'))
                const SizedBox(width: 10),
              if (showablePlans.contains('premium'))
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBillingType = 'premium';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedBillingType == 'premium'
                            ? Colors.deepOrange
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedBillingType == 'premium'
                              ? Colors.deepOrange
                              : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Business Premium",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedBillingType == 'premium'
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$${plans['premium']['price']}/month",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: selectedBillingType == 'premium'
                                  ? Colors.white
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plans['premium']['note'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: selectedBillingType == 'premium'
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Individual features first (included in all business plans)
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Individual Plan Features (Included in all Business plans)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              if (subscriptionData?['individual']?['features'] != null) ...[
                ...subscriptionData!['individual']['features']
                    .values
                    .map<Widget>((feature) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            feature['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        if (showablePlans.contains('basic'))
                          const Expanded(
                            child: Center(
                              child: Icon(Icons.check_circle,
                                  color: Colors.blue, size: 20),
                            ),
                          ),
                        if (showablePlans.contains('basic') &&
                            showablePlans.contains('premium'))
                          const SizedBox(width: 10),
                        if (showablePlans.contains('premium'))
                          const Expanded(
                            child: Center(
                              child: Icon(Icons.check_circle,
                                  color: Colors.blue, size: 20),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        // Business-specific Feature Rows
        ...features.values.map<Widget>((feature) {
          // Define which features belong to which plan
          bool basicHasFeature =
              _getBasicPlanFeatures().contains(feature['id']);
          bool premiumHasFeature =
              _getPremiumPlanFeatures().contains(feature['id']);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.orange.withOpacity(0.3)),
                right: BorderSide(color: Colors.orange.withOpacity(0.3)),
                bottom: BorderSide(color: Colors.orange.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature['description'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Basic Plan Column
                if (showablePlans.contains('basic'))
                  Expanded(
                    child: Center(
                      child: Icon(
                        basicHasFeature ? Icons.check_circle : Icons.close,
                        color:
                            basicHasFeature ? Colors.orange : Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ),
                if (showablePlans.contains('basic') &&
                    showablePlans.contains('premium'))
                  const SizedBox(width: 10),
                // Premium Plan Column
                if (showablePlans.contains('premium'))
                  Expanded(
                    child: Center(
                      child: Icon(
                        premiumHasFeature ? Icons.check_circle : Icons.close,
                        color: premiumHasFeature
                            ? Colors.orange
                            : Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),

        // Selected Plan Price Display
        const SizedBox(height: 20),
        _buildSelectedBusinessPlanPrice(),
      ],
    );
  }

  // Method to build selected business plan price display
  Widget _buildSelectedBusinessPlanPrice() {
    if (subscriptionData?['business']?['plans'] == null) {
      return const SizedBox.shrink();
    }

    final businessPlans =
        subscriptionData!['business']['plans'] as Map<String, dynamic>;
    final selectedBusinessPlan = businessPlans[selectedBillingType];
    final planName = selectedBusinessPlan['name'] ?? '';
    final planPrice = selectedBusinessPlan['price'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            "Selected Plan: $planName",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            planPrice == 0 ? "Free" : "\$$planPrice/month",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          if (selectedBusinessPlan['note'] != null) ...[
            const SizedBox(height: 4),
            Text(
              selectedBusinessPlan['note'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build feature row with label
  Widget buildFeatureRowWithLabel(
      String label, String subtitle, String labelText, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labelText,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New method to build plan type tiles
  Widget buildPlanTypeTile({
    required String title,
    required String description,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? Colors.deepOrange : Colors.orange,
          width: isSelected ? 3.5 : 1.5,
        ),
        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFeatureRow(String label, String subtitle, bool isPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPro ? Icons.check_circle : Icons.check,
            color: isPro ? Colors.orange : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "PRO",
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPlanTile({
    String title = '',
    String price = '',
    String subtitle = '',
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: (isSelected) ? Colors.deepOrange : Colors.orange,
          width: (isSelected) ? 3.5 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: (isSelected) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: (isSelected) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: (isSelected) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String?>> getUserPhoneNumber() async {
    final firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot userDoc =
          await firestore.collection('User').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final phoneNumber = data['phoneNumber'] as String?;
        final email = data['email'] as String?;
        return [phoneNumber, email];
      } else {
        showSnackBar(context, "User not found");
        return [];
      }
    } catch (e) {
      showSnackBar(context, "Error fetching phone number: $e");
      return [];
    }
  }

  void startRazorpayTransaction() async {
    if (subscriptionData == null) {
      showSnackBar(context, "Subscription data not available");
      return;
    }

    double amount = 0;
    String planName = '';

    if (selectedPlan == 'business') {
      final businessPlans =
          subscriptionData!['business']['plans'] as Map<String, dynamic>;
      final selectedBusinessPlan = businessPlans[selectedBillingType];
      amount = (selectedBusinessPlan['price'] as num).toDouble();
      planName = selectedBusinessPlan['name'];

      if (amount == 0) {
        _subscribeUserToProMembership();
        return;
      }
    } else if (selectedPlan == 'individual') {
      final individualPlans =
          subscriptionData!['individual']['plans'] as Map<String, dynamic>;
      amount =
          (individualPlans[selectedBillingType]['price'] as num).toDouble();
      planName = individualPlans[selectedBillingType]['name'];
    }

    if (amount == 0) {
      showSnackBar(context, "This plan is free!");
      _subscribeUserToProMembership();
      return;
    }

    final list = await getUserPhoneNumber();
    log('list ----- $list');
    String? number = list[0];
    if (number == null || number.isEmpty) {
      Get.to(() => const PhoneNumberVerification());
      return;
    }
    number = list[0];
    final email = list[1];

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showSnackBar(context, 'User not logged in');
      return;
    }

    amount *= 100; // amount in paise

    log('phone number == ${number!.substring(1)}');

    var options = {
      'key': Constants.RAZORPAY_KEY,
      'amount': amount.toInt(),
      'name': 'TruNri',
      'description': 'Subscription: $planName',
      'currency': 'INR',
      'prefill': {
        'contact': '9999999999',
        'email': email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    log('Razorpay options: $options');

    try {
      _razorpay.open(options);
    } catch (e) {
      log(e.toString());
    }
  }

  void _subscribeUserToProMembership() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirebaseFirestore.instance;
    if (uid == null) {
      showSnackBar(context, 'User not logged in');
      return;
    }

    try {
      final DateTime expiryDate = DateTime.now().add(
        Duration(
          days: selectedBillingType == 'annual' ? daysInAYear : 30,
        ),
      );

      await firestore.collection('User').doc(uid).set({
        'isSubscribed': true,
        'subscriptionDate': FieldValue.serverTimestamp(),
        'subscriptionExpiry': expiryDate,
        'planType': selectedPlan,
        'billingType': selectedBillingType,
      }, SetOptions(merge: true));

      String planName = '';
      double planPrice = 0;

      if (selectedPlan == 'individual') {
        final individualPlans =
            subscriptionData!['individual']['plans'] as Map<String, dynamic>;
        final selectedIndividualPlan = individualPlans[selectedBillingType];
        planName = selectedIndividualPlan['name'];
        planPrice = (selectedIndividualPlan['price'] as num).toDouble();
      } else if (selectedPlan == 'business') {
        final businessPlans =
            subscriptionData!['business']['plans'] as Map<String, dynamic>;
        final selectedBusinessPlan = businessPlans[selectedBillingType];
        planName = selectedBusinessPlan['name'];
        planPrice = (selectedBusinessPlan['price'] as num).toDouble();
      }

      String purchaseId = uuid.v4();

      await firestore.collection('purchases').doc(purchaseId).set(
        {
          'userID': AuthServices().getCurrentUser()!.uid,
          'plan': planName,
          'planType': selectedPlan,
          'billingType': selectedBillingType,
          'purchaseDate': FieldValue.serverTimestamp(),
          'status': 'Completed',
          'amount': planPrice,
        },
      );

      Provider.of<SubscriptionData>(context, listen: false)
          .changeSubscriptionStatus(true);

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => const SubscriptionSuccessScreen(),
        ),
      );
      showSnackBar(context, "Subscription Activated");
    } catch (e) {
      showSnackBar(context, 'Failed to activate subscription: $e');
    }
  }
}
