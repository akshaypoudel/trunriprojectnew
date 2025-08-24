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

const daysInAYear = (30 * 12);
const daysInAMonth = 30;

const monthlyPlanNameDefault = 'TruNri Pro Monthly';
const annualPlanNameDefault = 'TruNri Pro Annual';

// const annualPrice = '\$4099.99/year';
// const monthlyPrice = '\$619.99/month';

// const annualPriceAmount = 4099.99;
// const monthlyPriceAmount = 619.99;

const annualPlanKey = "Annual Plan";
const monthlyPlanKey = "Monthly Plan";

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;

  String annualPlanName = annualPlanNameDefault;
  double annualPlanPrice = 4099.99;
  String monthlyPlanName = monthlyPlanNameDefault;
  double monthlyPlanPrice = 619.19;
  String selectedPlan = '';
  List<Map<String, String>> features = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    selectedPlan = annualPlanName;
    _fetchSubscriptionData();
  }

  Future<void> _fetchSubscriptionData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptionData')
          .doc('subscriptionData')
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        final annualPlan = data[annualPlanKey];
        final monthlyPlan = data[monthlyPlanKey];
        // final featureMap = data['features'] as Map<String, dynamic>?;
        // final featureMap = data

        setState(() {
          if (annualPlan != null) {
            annualPlanName = annualPlan['name'] ?? annualPlanNameDefault;
            annualPlanPrice = (annualPlan['price'] ?? annualPlanPrice) * 1.0;
          }
          if (monthlyPlan != null) {
            monthlyPlanName = monthlyPlan['name'] ?? monthlyPlanNameDefault;
            monthlyPlanPrice = (monthlyPlan['price'] ?? monthlyPlanPrice) * 1.0;
          }
          // if (featureMap != null) {
          //   features = featureMap.values.map<Map<String, String>>((f) {
          //     return {
          //       'title': f['title'] as String,
          //       'description': f['description'] as String,
          //     };
          //   }).toList();
          // }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Optional: Show an error snackbar here.
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      log("Subscription data fetch error: $e");
      // Optional: Show snack bar or dialog on error
    }
  }

  @override
  void dispose() {
    _razorpay.clear();

    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    log('razorpay payment successfull = $response');
    _subscribeUserToProMemberShip();
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

    final annualPriceText = "\$${annualPlanPrice.toStringAsFixed(2)}/year";
    final monthlyPriceText = "\$${monthlyPlanPrice.toStringAsFixed(2)}/month";

    final featureTitles =
        Provider.of<SubscriptionData>(context, listen: false).features;

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
                        // buildFeatureRow("Post Events & Restauraunts", true),
                        // buildFeatureRow("Promote Business Ads", true),
                        // // buildFeatureRow("", true),
                        // buildFeatureRow("Control Posts Visibility", true),
                        // buildFeatureRow(
                        //   "One-on-One and Group Chat Feature",
                        //   true,
                        // ),
                        // buildFeatureRow(
                        //   "Send Friend Requests",
                        //   true,
                        // ),
                        // buildFeatureRow("Basic App Access", false),

                        ...featureTitles.map(
                          (f) => buildFeatureRow(
                            f['title'] ?? 'Title',
                            f['description'] ?? 'Description',
                            true,
                          ),
                        ),

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
                                      selectedPlan = annualPlanName;
                                    });
                                  },
                                  child: buildPlanTile(
                                      title: annualPlanName,
                                      price: annualPriceText,
                                      subtitle: "Billed Annually",
                                      isSelected:
                                          selectedPlan == annualPlanName),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ZoomIn(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPlan = monthlyPlanName;
                                    });
                                  },
                                  child: buildPlanTile(
                                      title: monthlyPlanName,
                                      price: monthlyPriceText,
                                      subtitle: "Billed monthly",
                                      isSelected:
                                          selectedPlan == monthlyPlanName),
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
                              onPressed: startRazorpayTransaction,
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
    final list = await getUserPhoneNumber();
    String? number = list[0];
    // ignore: unnecessary_null_comparison
    if (number!.isEmpty || number == null) {
      Get.to(() => const PhoneNumberVerification());
      return;
    }
    final email = list[1];
    // final result = number.replaceFirst('+61', '');

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirebaseFirestore.instance;
    if (uid == null) {
      showSnackBar(context, 'User not logged in');
      return;
    }
    await firestore.collection('User').doc(uid).get();

    double amount =
        (selectedPlan == annualPlanName) ? annualPlanPrice : monthlyPlanPrice;

    amount *= 100; //amount in paise

    var options = {
      'key': Constants.RAZORPAY_KEY,
      'amount': amount,
      'name': 'TruNri',
      'description': 'Pro Subscription',
      'prefill': {
        'contact': number,
        'email': email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      log(e.toString());
    }
  }

  void _subscribeUserToProMemberShip() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirebaseFirestore.instance;
    if (uid == null) {
      showSnackBar(context, 'User not logged in');
      return;
    }

    final expiryDuration = (selectedPlan == annualPlanName)
        ? daysInAYear
        : ((selectedPlan == monthlyPlanName) ? daysInAMonth : 0);
    try {
      final DateTime expiryDate = DateTime.now().add(
        Duration(
          days: expiryDuration,
        ),
      );
      await firestore.collection('User').doc(uid).update(
        {
          'isSubscribed': true,
          'subscriptionDate': FieldValue.serverTimestamp(),
          'subscriptionExpiry': expiryDate,
        },
      );
      await firestore.collection('purchases').doc(uid).set({
        'userID': AuthServices().getCurrentUser()!.uid,
        'plan':
            (selectedPlan == annualPlanName) ? annualPlanName : monthlyPlanName,
        'purchaseDate': FieldValue.serverTimestamp(),
        // 'subscriptionExpiry': expiryDate,
        'status': 'Completed',
        'amount': (selectedPlan == annualPlanName)
            ? annualPlanPrice
            : monthlyPlanPrice,
      }, SetOptions(merge: true));

      Provider.of<SubscriptionData>(context, listen: false)
          .changeSubscriptionStatus(true);

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

  Widget buildFeatureRow1(String label, bool isPro) {
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
}
