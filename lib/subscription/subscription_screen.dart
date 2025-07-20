import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_success_screen.dart';
import 'package:trunriproject/widgets/helper.dart';

const daysInAYear = (30 * 12);
const daysInAMonth = 30;

const monthlyPlan = 'Monthly';
const annualPlan = 'Annual';

const annualPrice = '₹4099.99/year';
const monthlyPrice = '₹619.99/month';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPlan = 'Annual';
  @override
  Widget build(BuildContext context) {
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
                child: const Text(
                  "Unlock all features and bonus content with PRO!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
                        buildFeatureRow("Post Jobs", true),
                        buildFeatureRow("Promote Business Ads", true),
                        buildFeatureRow("Direct Replies to Jobs", true),
                        buildFeatureRow("Control Job Visibility", true),
                        buildFeatureRow(
                          "One-on-One and Group Chat Feature",
                          true,
                        ),
                        buildFeatureRow("Basic App Access", false),
                        const SizedBox(height: 30),
                        FadeIn(
                          child: const Text(
                            "Choose your plan",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ZoomIn(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPlan = annualPlan;
                                    });
                                  },
                                  child: buildPlanTile(
                                      title: annualPlan,
                                      price: "₹341.29/month",
                                      subtitle: annualPrice,
                                      isSelected: selectedPlan == annualPlan),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ZoomIn(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPlan = monthlyPlan;
                                    });
                                  },
                                  child: buildPlanTile(
                                      title: monthlyPlan,
                                      price: monthlyPrice,
                                      subtitle: "Billed monthly",
                                      isSelected: selectedPlan == monthlyPlan),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: subscribeUserToProMemberShip,
                              child: const Text(
                                "SUBSCRIBE TO PRO",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
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

  void subscribeUserToProMemberShip() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirebaseFirestore.instance;
    if (uid == null) {
      showSnackBar(context, 'User not logged in');
      return;
    }
    final expiryDuration = (selectedPlan == annualPlan)
        ? daysInAYear
        : ((selectedPlan == monthlyPlan) ? daysInAMonth : 0);
    try {
      final DateTime expiryDate = DateTime.now().add(
        Duration(
          days: expiryDuration,
        ),
      );
      await firestore.collection('User').doc(uid).update(
        {
          'isSubscribed': true,
          'subscriptionExpiry': expiryDate,
        },
      );

      Provider.of<SubscriptionData>(context, listen: false)
          .changeSubscriptionStatus(true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => const SubscriptionSuccessScreen(),
        ),
      );
    } catch (e) {
      showSnackBar(context, 'Failed to activate subscription: $e');
    }
  }

  Widget buildFeatureRow(String label, bool isPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isPro ? Icons.check_circle : Icons.check,
            color: isPro ? Colors.orange : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const Spacer(),
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
            (subtitle == annualPrice) ? '$subtitle\nBilled Annualy' : subtitle,
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
}
