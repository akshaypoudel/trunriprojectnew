import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:trunriproject/recoveryPasswordScreen.dart';
import 'package:trunriproject/signUpScreen.dart';
import 'package:trunriproject/widgets/appTheme.dart';
import 'package:trunriproject/widgets/customTextFormField.dart';
import 'package:trunriproject/widgets/helper.dart';

import 'facebook/firebaseservices.dart';
import 'home/bottom_bar.dart';
import 'home/home_screen.dart';
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
  RxBool hide = true.obs;
  RxBool hide1 = true.obs;
  EmailOTP myauth = EmailOTP();
  bool showOtpField = false;

  String code = "+91";
  void loginUser() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      showSnackBar(context, "Please enter both phone number and password");
      NewHelper.hideLoader(loader);
      return;
    }

    try {
      // First check if the phone number exists
      QuerySnapshot phoneSnapshot = await FirebaseFirestore.instance
          .collection("User")
          .where("phoneNumber", isEqualTo: phone)
          .get();

      if (phoneSnapshot.docs.isEmpty) {
        NewHelper.hideLoader(loader);
        showSnackBar(context, "Phone number not found");
        return;
      }

// UserCredential userCredential = await FirebaseAuth.instance
//         .signInWithEmailAndPassword(email: syntheticEmail, password: password);
//         //FirebaseAuth.instance.signinWith

      // Now check if password matches for that phone number
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection("User")
          .where("phoneNumber", isEqualTo: phone)
          .where("password", isEqualTo: password)
          .get();

      if (userSnapshot.docs.isEmpty) {
        NewHelper.hideLoader(loader);
        showSnackBar(context, "Incorrect password");
        return;
      }

      // Successful login
      showSnackBar(context, "Login successful");
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      sharedPreferences.setString("myPhone", phoneController.text.trim());
      NewHelper.hideLoader(loader);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyBottomNavBar()),
      );
    } catch (e) {
      NewHelper.hideLoader(loader);
      showSnackBar(context, "Error: ${e.toString()}");
    }
  }

  Future<dynamic> signInWithGoogle(BuildContext context) async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      log("wewewewww${userCredential.user!.displayName.toString()}");
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      sharedPreferences.setString(
          "google_name", userCredential.user!.displayName ?? '');
      sharedPreferences.setString(
          "google_email", userCredential.user!.email ?? '');
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PickUpAddressScreen(),
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
      );

      return userCredential;
    } on Exception catch (e) {
      print('exception->$e');
    } finally {
      // Ensure the loader is always removed, even if an error occurs
      NewHelper.hideLoader(loader);
    }
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
          SizedBox(height: size.height * 0.04),
          // for username and password
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
              initialCountryCode: "IN",
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

          Obx(() {
            return CommonTextField(
              hintText: 'Password',
              controller: passwordController,
              keyboardType: TextInputType.text,
              validator: MultiValidator([
                RequiredValidator(errorText: 'Password is required'),
              ]).call,
              obSecure: !hide.value,
              suffixIcon: IconButton(
                onPressed: () {
                  hide.value = !hide.value;
                },
                icon: hide.value
                    ? const Icon(Icons.visibility_off)
                    : const Icon(Icons.visibility),
              ),
            );
          }),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Get.to(const RecoveryPasswordScreen());
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Text(
                  "Recovery Password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff6F6B7A),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.04),

          SizedBox(height: size.height * 0.01),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                // for sign in button
                GestureDetector(
                  onTap: () {
                    loginUser();
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
                        "Sign In",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.06),
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
                        signInWithGoogle(context);
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
                    GestureDetector(
                        onTap: () async {
                          signInWithFacebook();
                        },
                        child: socialIcon("assets/images/facebook.png")),
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
