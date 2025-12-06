import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'dart:developer';

class SubscriptionSuccessScreen extends StatefulWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen> {
  bool isLoading = true;
  Map<String, dynamic>? userPlanData;
  List<Map<String, dynamic>> planFeatures = [];
  String planName = '';
  String planType = '';
  String billingType = '';

  @override
  void initState() {
    super.initState();
    _fetchUserPlanData();
  }

  Future<void> _fetchUserPlanData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Fetch user's current plan details
      final userDoc =
          await FirebaseFirestore.instance.collection('User').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        planType = userData['planType'] ?? 'individual';
        billingType = userData['billingType'] ?? 'annual';

        log('User plan type: $planType');
        log('User billing type: $billingType');

        // Fetch subscription plans data
        final subscriptionDoc = await FirebaseFirestore.instance
            .collection('SubscriptionPlans')
            .doc('SubscriptionsPlans')
            .get();

        if (subscriptionDoc.exists) {
          final subscriptionData =
              subscriptionDoc.data() as Map<String, dynamic>;

          // Get plan-specific features and details
          await _processPlanData(subscriptionData);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      log('Error fetching user plan data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _processPlanData(Map<String, dynamic> subscriptionData) async {
    if (planType == 'individual') {
      // Handle individual plans
      final individualData = subscriptionData['individual'];
      if (individualData != null) {
        final plans = individualData['plans'] as Map<String, dynamic>?;
        final features = individualData['features'] as Map<String, dynamic>?;

        if (plans != null && plans.containsKey(billingType)) {
          final currentPlan = plans[billingType];
          planName = currentPlan['name'] ?? 'Individual Plan';

          // Add plan note as first feature if it exists
          final planNote = currentPlan['note'] as String? ?? '';
          if (planNote.isNotEmpty) {
            planFeatures.add({
              'title': 'Plan Details',
              'description': planNote,
            });
          }
        }

        if (features != null) {
          final additionalFeatures = features.values
              .map<Map<String, dynamic>>((feature) => {
                    'title': feature['title'] ?? '',
                    'description': feature['description'] ?? '',
                  })
              .toList();
          planFeatures.addAll(additionalFeatures);
        }
      }
    } else if (planType == 'business') {
      // Handle business plans
      final businessData = subscriptionData['business'];
      if (businessData != null) {
        final plans = businessData['plans'] as Map<String, dynamic>?;
        final features = businessData['features'] as Map<String, dynamic>?;

        if (plans != null && plans.containsKey(billingType)) {
          final currentPlan = plans[billingType];
          planName = currentPlan['name'] ?? 'Business Plan';
          await _addIndividualPlanFeaturesForBusiness(subscriptionData);

          // Add plan note as first feature if it exists
          final planNote = currentPlan['note'] as String?;
          if (planNote != null && planNote.isNotEmpty) {
            planFeatures.add({
              'title': 'Plan Limits',
              'description': planNote,
            });
          }
        }

        // Add individual plan features inclusion notice

        if (features != null) {
          List<Map<String, dynamic>> additionalFeatures = [];

          // For business plans, show features based on plan tier
          if (billingType == 'basic') {
            // Basic plan gets features 1 and 2
            final basicFeatureIds = ['1', '2'];
            additionalFeatures = features.entries
                .where((entry) => basicFeatureIds.contains(entry.value['id']))
                .map<Map<String, dynamic>>((entry) => {
                      'title': entry.value['title'] ?? '',
                      'description': entry.value['description'] ?? '',
                    })
                .toList();
          } else if (billingType == 'premium') {
            // Premium plan gets all features
            additionalFeatures = features.values
                .map<Map<String, dynamic>>((feature) => {
                      'title': feature['title'] ?? '',
                      'description': feature['description'] ?? '',
                    })
                .toList();
          }

          planFeatures.addAll(additionalFeatures);
        }
      }
    }

    log('Plan name: $planName');
    log('Plan features: $planFeatures');
  }

// New method to add individual plan features for business plans
  Future<void> _addIndividualPlanFeaturesForBusiness(
      Map<String, dynamic> subscriptionData) async {
    final individualData = subscriptionData['individual'];
    if (individualData != null) {
      final features = individualData['features'] as Map<String, dynamic>?;

      if (features != null) {
        // Create a list of individual feature titles for display
        List<String> individualFeatureTitles = features.values
            .map<String>((feature) => feature['title'] ?? '')
            .where((title) => title.isNotEmpty)
            .toList();

        // Add the inclusion notice as a feature
        planFeatures.add({
          'title': 'Includes All Individual Features',
          'description':
              'This business plan includes: ${individualFeatureTitles.join(', ')}',
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade50,
                Colors.white,
                Colors.orange.shade50,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.deepOrange,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade50,
              Colors.white,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    color: Colors.deepOrange,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                expandedHeight: 0,
                floating: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildSuccessHeader(),
                      const SizedBox(height: 40),
                      _buildFeaturesCard(),
                      const SizedBox(height: 30),
                      _buildContinueButton(),
                      const SizedBox(height: 20),
                      if (_shouldShowUpgradeButton()) ...[
                        _buildUpgradePlanButton(),
                        const SizedBox(height: 20),
                      ],
                      _buildCancelSubscriptionButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to check if upgrade button should be shown
  bool _shouldShowUpgradeButton() {
    // Show upgrade button if user is NOT on Business Premium plan
    return !(planType == 'business' && billingType == 'premium');
  }

// Method to build the upgrade plan button
  Widget _buildUpgradePlanButton() {
    String buttonText = _getUpgradeButtonText();

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade300,
            Colors.red.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Get.to(() => const SubscriptionScreen());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.upgrade_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Method to get appropriate button text based on current plan
  String _getUpgradeButtonText() {
    if (planType == 'business' && billingType == 'basic') {
      return 'Upgrade to Premium';
    } else if (planType == 'individual') {
      return 'Upgrade to Business';
    } else {
      return 'Upgrade Plan';
    }
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        // Crown with glow effect
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.orange.shade100,
                Colors.orange.shade50,
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange,
                  Colors.orange.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/crown.png',
              height: 80,
              width: 80,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Success Message
        Column(
          children: [
            Text(
              '🎉 Congratulations! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.deepOrange,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade100,
                    Colors.orange.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                planName.isNotEmpty
                    ? 'Welcome to $planName'
                    : 'Welcome to TruNri Pro',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          planType == 'business'
              ? 'You now have access to all business features\nand exclusive benefits!'
              : 'You now have access to all premium features\nand exclusive benefits!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesCard() {
    // Pool of generic icons
    final List<IconData> iconPool = [
      Icons.info_outline_rounded, // Special icon for plan note/limits
      Icons.star_rounded, // Special icon for individual features inclusion
      Icons.business_rounded,
      Icons.upload_file_rounded,
      Icons.trending_up_rounded,
      Icons.people_rounded,
      Icons.notifications_active_rounded,
      Icons.diamond_rounded,
    ];

    // Pool of generic colors
    final List<Color> colorPool = [
      Colors.blue, // Special color for plan note/limits
      Colors.purple, // Special color for individual features inclusion
      Colors.deepOrange,
      Colors.green,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
    ];

    // Build FeatureData list using actual plan features
    final features = List<FeatureData>.generate(planFeatures.length, (index) {
      final feature = planFeatures[index];

      // Use special styling for special features
      IconData icon = iconPool[index % iconPool.length];
      Color color = colorPool[index % colorPool.length];

      // Special handling for plan note/limits
      if (feature['title'] == 'Plan Details' ||
          feature['title'] == 'Plan Limits') {
        icon = Icons.info_outline_rounded;
        color = Colors.blue;
      }
      // Special handling for individual features inclusion
      else if (feature['title'] == 'Includes All Individual Features') {
        icon = Icons.star_rounded;
        color = Colors.purple;
      }

      return FeatureData(
        title: feature['title'] ?? '',
        subtitle: feature['description'] ?? '',
        icon: icon,
        color: color,
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepOrange, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    planType == 'business'
                        ? Icons.business_rounded
                        : Icons.star_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planType == 'business'
                            ? 'Business Features'
                            : 'Premium Features',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (planName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          planName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (features.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No features available for this plan.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            ...features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              return _buildFeatureItem(feature, index == features.length - 1);
            }),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(FeatureData feature, bool isLast) {
    // Check if this is a special feature
    bool isPlanNote =
        feature.title == 'Plan Details' || feature.title == 'Plan Limits';
    bool isIndividualInclusion =
        feature.title == 'Includes All Individual Features';
    bool isSpecialFeature = isPlanNote || isIndividualInclusion;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  // Add special border for special features
                  border: isSpecialFeature
                      ? Border.all(
                          color: feature.color.withValues(alpha: 0.3), width: 1)
                      : null,
                ),
                child: Icon(
                  feature.icon,
                  color: feature.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: isSpecialFeature
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            isPlanNote ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isIndividualInclusion
                      ? Colors.purple.shade50
                      : isPlanNote
                          ? Colors.blue.shade50
                          : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIndividualInclusion
                      ? Icons.star
                      : isPlanNote
                          ? Icons.info
                          : Icons.check_rounded,
                  color: isIndividualInclusion
                      ? Colors.purple.shade600
                      : isPlanNote
                          ? Colors.blue.shade600
                          : Colors.green.shade600,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange,
            Colors.orange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Get.offAll(() => const MyBottomNavBar()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start Exploring',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelSubscriptionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.orange.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.deepOrange,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          showCancelSubscriptionDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Cancel Subscription',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }

  void showCancelSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  "Cancel Subscription?",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  "Are you sure you want to cancel your ${planName.isNotEmpty ? planName : 'subscription'}?\n\n"
                  "Your subscription will remain active until the end of the current billing cycle. "
                  "You will not be charged for the next billing period.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.deepOrange,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "No, Keep It",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            String uid = FirebaseAuth.instance.currentUser!.uid;
                            final provider = Provider.of<SubscriptionData>(
                                context,
                                listen: false);

                            provider.changeSubscriptionStatus(false);

                            await FirebaseFirestore.instance
                                .collection('User')
                                .doc(uid)
                                .update({
                              "isSubscribed": false,
                              "subscriptionExpiry": Timestamp.now(),
                            });

                            showSnackBar(
                                context, "Subscription cancelled successfully");
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }

                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Yes, Cancel",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
