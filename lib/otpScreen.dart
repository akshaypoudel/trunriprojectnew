import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/currentLocation.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/signUpScreen.dart';
import 'package:trunriproject/widgets/helper.dart';

import 'nativAddressScreen.dart';

class NewOtpScreen extends StatefulWidget {
  static String route = "/OtpScreen";

  final String phoneNumber;
  final String verificationId;
  String? name;
  String? email;
  String? profession;
  Map<String, dynamic>? hometown;
  final bool isSignInScreen;

  NewOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.name,
    this.email,
    this.profession,
    this.hometown,
    required this.isSignInScreen,
  });

  @override
  State<NewOtpScreen> createState() => _NewOtpScreenState();
}

class _NewOtpScreenState extends State<NewOtpScreen> {
  final TextEditingController otpController = TextEditingController();

  RxInt timerInt = 30.obs;
  Timer? timer;
  EmailOTP myauth = EmailOTP();

  setTimer() {
    timerInt.value = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timerInt.value--;
      if (timerInt.value == 0) {
        timer.cancel();
      }
    });
  }

  void register(
    String completePhoneNum,
    String name,
    String email,
    String profession,
    Map<String, dynamic> hometown,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    await updateUserName(name);
    FirebaseFirestore.instance.collection('User').doc(uid).set({
      'name': name,
      'email': email,
      'phoneNumber': completePhoneNum,
      'profile': '',
      'address': '',
      'isOnline': true,
      'lastSeen': Timestamp.now(),
      'isSubscribed': false,
      'isBlocked': false,
      'subscriptionExpiry': DateTime.now(),
      'friendRequestLimit': 2,
      'profession': profession,
      'hometown': {
        'city': hometown['city'],
        'state': hometown['state'],
        'address': hometown['address'],
      },
      'friends': [],
      'friendRequests': {
        'sent': [],
        'received': [],
      },
    }, SetOptions(merge: true)).then((value) {
      NewHelper.hideLoader(loader);
    });
  }

  Future<void> updateUserName(String newName) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await user.updateDisplayName(newName);
      } on FirebaseAuthException catch (e) {
        showSnackBar(context, "Error updating display name: ${e.message}");
      }
    } else {
      showSnackBar(context, "No user is currently signed in.");
    }
  }

  Future<bool> isUserInAustralia() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return false;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return placemarks.isNotEmpty && placemarks.first.isoCountryCode == 'AU';
  }

  void verifyOTP() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    if (otpController.text.trim().isEmpty) {
      showSnackBar(context, "Please enter OTP");
    } else {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otpController.text.trim(),
        );

        await FirebaseAuth.instance.signInWithCredential(credential);

///////////////////////////////
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        sharedPreferences.setString("myPhone", widget.phoneNumber);
//////////////////////////////////

        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('User')
            .where('phoneNumber', isEqualTo: widget.phoneNumber)
            .get();

        if (result.docs.isNotEmpty) {
          Navigator.pop(context);
          showSnackBar(
              context, "User is already registered with this phoneNumber");
          FirebaseAuth.instance.signOut();
          NewHelper.hideLoader(loader);
          return;
        }

        register(
          widget.phoneNumber,
          widget.name!,
          widget.email!,
          widget.profession!,
          widget.hometown!,
        );

        showSnackBar(context, "User registered successfully");

        checkIfUserInAustralia();
      } catch (e) {
        showSnackBar(context, "Invalid OTP error $e");
      }
    }

    NewHelper.hideLoader(loader);
  }

  void checkIfUserInAustralia() {
    Future.delayed(Duration.zero, () async {
      bool inAustralia = await isUserInAustralia();

      if (!inAustralia) {
        Get.offAll(
          () => const PickUpAddressScreen(),
        );
      } else {
        Get.offAll(
          () => const CurrentAddress(
            isProfileScreen: false,
            savedAddress: '',
            latitude: '',
            longitude: '',
            radiusFilter: 50,
          ),
        );
      }
    });
  }

  Future<void> _handlePostSignIn(User? user, String phone) async {
    if (user == null) {
      showSnackBar(context, "Sign-in failed. Try again.");
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid) // always use UID as doc ID
        .get();

    if (!userDoc.exists) {
      // user not registered yet → go to signup
      showSnackBar(context, 'User Not Registered!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignUpScreen()),
      );
      return;
    }

    final userData = userDoc.data();
    if (userData != null && userData['isBlocked'] == true) {
      await FirebaseAuth.instance.signOut();
      showSnackBar(context, "User is blocked by admin");
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MyBottomNavBar(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
      (Route<dynamic> route) => false,
    );

    // ✅ success
    // showSnackBar(context, "Welcome back!");
    // navigate to your home/dashboard screen
  }

  void verifyOTPForSignInScreen() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    if (otpController.text.trim().isEmpty) {
      showSnackBar(context, "Please enter OTP");
    } else {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otpController.text.trim(),
        );

        await FirebaseAuth.instance.signInWithCredential(credential);

        final user = FirebaseAuth.instance.currentUser;

        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        sharedPreferences.setString("myPhone", widget.phoneNumber);

        _handlePostSignIn(user, widget.phoneNumber);

        if (user != null) {
          await PresenceService.setUserOnline(); // only for current user
        }

        // checkIfUserInAustralia();
      } catch (e) {
        showSnackBar(context, "Invalid OTP Error : ${e.toString()}");
      }
    }

    NewHelper.hideLoader(loader);
  }

  final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        color: const Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
        color: Colors.grey.shade300,
        width: 4.0,
      ))));
  @override
  void initState() {
    super.initState();
    setTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFF730A),
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
            height: size.height,
            width: size.width,
            child: Stack(children: [
              Container(
                height: size.height,
                width: size.width,
                decoration: const BoxDecoration(color: Color(0xffFF730A)),
                padding: EdgeInsets.symmetric(
                    horizontal: size.width * .02, vertical: size.height * .06),
                child: Column(
                  children: [
                    Image.asset(
                        height: size.height * .15, 'assets/images/otplogo.png'),
                    const SizedBox(
                      height: 13,
                    ),
                    Text(
                      'OTP Verification',
                      style: GoogleFonts.poppins(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Enter the OTP Send to Your Phone',
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.white),
                    )
                  ],
                ),
              ),
              Positioned(
                  top: size.height * .40,
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      // borderRadius: BorderRadius.only(topLeft: Radius.circular(100))
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 60, left: 10, right: 10),
                      child: Column(
                        children: [
                          Pinput(
                            controller: otpController,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            keyboardType: TextInputType.number,
                            length: 6,
                            defaultPinTheme: defaultPinTheme,
                          ),
                          SizedBox(
                            height: size.height * .05,
                          ),
                          Text(
                            'Did not receive the OTP ?',
                            style: GoogleFonts.poppins(
                                color: const Color(0xff3D4260), fontSize: 17),
                          ),
                          SizedBox(
                            height: size.height * .03,
                          ),
                          GestureDetector(
                            onTap: () async {},
                            child: Obx(() {
                              return Text(
                                ' Resend OTP\n'
                                '${timerInt.value > 0 ? "In ${timerInt.value > 9 ? timerInt.value : "0${timerInt.value}"}" : ""}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff578AE8),
                                    fontSize: 16),
                              );
                            }),
                          ),
                          SizedBox(
                            height: size.height * .2,
                          ),
                        ],
                      ),
                    ),
                  ))
            ])),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(15.0).copyWith(bottom: 10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFF730A),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2))),
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                )),
            onPressed: () async {
              if (widget.isSignInScreen == false) {
                verifyOTP();
              } else {
                verifyOTPForSignInScreen();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Verify OTP'.tr,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
