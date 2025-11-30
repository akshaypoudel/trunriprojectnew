import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:trunriproject/google_signin/google_signin.dart';
import 'package:trunriproject/signUpScreen.dart';
import 'package:trunriproject/widgets/appTheme.dart';
import 'package:trunriproject/widgets/helper.dart';

import 'nativAddressScreen.dart';
import 'otpScreen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  CustomGoogleSignin googleSignin = CustomGoogleSignin();
  RxBool hide = true.obs;
  RxBool hide1 = true.obs;
  EmailOTP myauth = EmailOTP();
  bool showOtpField = false;

  String code = "+61";

  Future<bool> doesPhoneExist(String phone) async {
    final query = await FirebaseFirestore.instance
        .collection('User')
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<bool> checkIfUserIsBlockedByPhone(String phone) async {
    final query = await FirebaseFirestore.instance
        .collection('User')
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final userData = query.docs.first.data();
      if (userData['isBlocked'] == true) {
        return true;
      }
    }

    return false;
  }

  void requestForOtp(String phone) async {
    // final isUserBlocked = await checkIfUserIsBlockedByPhone(phone);
    // if (isUserBlocked) {
    // log('user is blocked');
    // showSnackBar(context, "User is Blocked by Admin");
    // return;
    // }
    // await FirebaseMessaging.instance.requestPermission();

    String completePhoneNum = '$code${phoneController.text.trim()}';

    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: completePhoneNum,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        showSnackBar(context, "User Logged In Successfully");
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBar(context,
            "Firebase Premium is required to Sign in with Real Numbers, Please use Test phone numbers to sign in for now.");
        NewHelper.hideLoader(loader);
      },
      codeSent: (String verificationId, int? resendToken) {
        SignUpScreen.verificationOTP = verificationId;
        NewHelper.hideLoader(loader);
        showSnackBar(context, 'OTP sent successfully');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewOtpScreen(
              isSignInScreen: true,
              verificationId: verificationId,
              phoneNumber: completePhoneNum,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        SignUpScreen.verificationOTP = verificationId;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: ListView(
        children: [
          Image.asset(
            "assets/images/hand.gif",
            height: 200.0,
            width: 100.0,
          ),
          const Text(
            "Wellcome back you've\nbeen missed!",
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 27, color: Color(0xff6F6B7A), height: 1.2),
          ),
          SizedBox(height: size.height * 0.08),
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: IntlPhoneField(
              flagsButtonPadding: const EdgeInsets.all(8),
              dropdownIconPosition: IconPosition.trailing,
              showDropdownIcon: false, // Hide the country selection dropdown
              enabled: true, // Ensure only the phone number input is editable
              cursorColor: Colors.black,
              textInputAction: TextInputAction.next,
              dropdownTextStyle: const TextStyle(color: Colors.black),
              style: const TextStyle(color: AppTheme.textColor),
              controller: phoneController,
              decoration: InputDecoration(
                fillColor: Colors.grey.shade100,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                hintStyle: const TextStyle(
                    color: Colors.black45,
                    fontSize: 19,
                    fontWeight: FontWeight.w400),
                hintText: 'Phone Number',
                labelStyle: const TextStyle(color: AppTheme.textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(11),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              initialCountryCode: "AU",
              onCountryChanged: (country) {
                code = '+${country.dialCode}';
              },
              validator: (value) {
                if (value == null || phoneController.text.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: size.height * 0.04),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    // bool exist = await doesPhoneExist(
                    //   '$code${phoneController.text.trim()}',
                    // );
                    // if (exist) {
                    requestForOtp('$code${phoneController.text.trim()}');
                    // } else {
                    // showSnackBar(context, "User Doesn't Exists");
                    // }
                  },
                  child: Container(
                    width: size.width,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffFF730A),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Request OTP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 2,
                      width: size.width * 0.2,
                      color: Colors.black12,
                    ),
                    const Text(
                      "  Or continue with   ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff6F6B7A),
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      height: 2,
                      width: size.width * 0.2,
                      color: Colors.black12,
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        googleSignin.signInWithGoogle(context);
                      },
                      child: socialIcon(
                        "assets/images/google.png",
                      ),
                    ),
                    if (Platform.isIOS)
                      const SizedBox(
                        width: 10,
                      ),
                    if (Platform.isIOS)
                      GestureDetector(
                        onTap: () async {
                          try {
                            final credential =
                                await SignInWithApple.getAppleIDCredential(
                              scopes: [
                                AppleIDAuthorizationScopes.email,
                                AppleIDAuthorizationScopes.fullName,
                              ],
                            );
                            final OAuthProvider oAuthProvider =
                                OAuthProvider('apple.com');
                            final OAuthCredential oAuthCredential =
                                oAuthProvider.credential(
                              idToken: credential.identityToken,
                              accessToken: credential.authorizationCode,
                            );
                            await FirebaseAuth.instance
                                .signInWithCredential(oAuthCredential);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PickUpAddressScreen()),
                            );
                          } catch (error) {
                            print('Error signing in with Apple: $error');
                          }
                        },
                        child: socialIcon("assets/images/apple.png"),
                      ),
                    const SizedBox(
                      width: 10,
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.03),
                Text.rich(
                  TextSpan(
                      text: "Not a member? ",
                      style: const TextStyle(
                        color: Color(0xff6F6B7A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                            text: "Register now",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const SignUpScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.ease;
                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      var offsetAnimation =
                                          animation.drive(tween);
                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              })
                      ]),
                ),
                const SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        ],
      )),
    );
  }

  Container socialIcon(image) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Image.asset(
        image,
        height: 35,
      ),
    );
  }

  Container myTextField(String hint, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 10,
      ),
      child: TextField(
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 15,
            ),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(15),
            ),
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.black45,
              fontSize: 19,
            ),
            suffixIcon: Icon(
              Icons.visibility_off_outlined,
              color: color,
            )),
      ),
    );
  }
}
