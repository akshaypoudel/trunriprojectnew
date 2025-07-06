import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:trunriproject/otpScreen.dart';
import 'package:trunriproject/signinscreen.dart';
import 'package:trunriproject/widgets/appTheme.dart';
import 'package:trunriproject/widgets/customTextFormField.dart';
import 'package:trunriproject/widgets/helper.dart';

import 'nativAddressScreen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static String verificationOTP = "";
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  RxBool hide = true.obs;
  RxBool hide1 = true.obs;
  String code = "+91";
  bool value = false;
  bool showValidation = false;
  FirebaseAuth auth = FirebaseAuth.instance;

  void checkEmailInFirestore() async {
    if (phoneController.text.isEmpty) {
      showSnackBar(context, "Please enter your phone number");
      return;
    }
    String completePhoneNum = "$code${phoneController.text.trim()}";
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('User')
        .where('phoneNumber', isEqualTo: completePhoneNum)
        .get();

    if (result.docs.isNotEmpty) {
      showSnackBar(context, "User is already registered with this phoneNumber");
      return;
    }

    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: completePhoneNum,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        showSnackBar(context, "Phone number verified successfully");
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBar(context, "Verification failed: ${e.message}");

        log("Verification failed: ${e.message}");
        log("Verification failed: ${code.toString()}");
        log("Verification failed phone number: $completePhoneNum");
        NewHelper.hideLoader(loader);
      },
      codeSent: (String verificationId, int? resendToken) {
        SignUpScreen.verificationOTP = verificationId;
        NewHelper.hideLoader(loader);
        //register(completePhoneNum);
        showSnackBar(context, 'OTP sent successfully');
        NewHelper.hideLoader(loader);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewOtpScreen(
              phoneNumber: completePhoneNum,
              verificationId: verificationId,
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        SignUpScreen.verificationOTP = verificationId;
      },
    );
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
      // Handle the exception
      print('exception->$e');
    } finally {
      // Ensure the loader is always removed, even if an error occurs
      NewHelper.hideLoader(loader);
    }
  }

  final formKey1 = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Form(
        key: formKey1,
        child: ListView(
          children: [
            SizedBox(height: size.height * 0.03),
            const Text(
              "Join the Community!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Color(0xff353047),
              ),
            ),
            Image.asset(
              "assets/images/person.gif",
              height: 200.0,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 50, right: 50),
              child: Text(
                "Ready to explore and connect? Let's create your account!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20, color: Color(0xff6F6B7A), height: 1.2),
              ),
            ),
            SizedBox(height: size.height * 0.04),
            // for username and password
            CommonTextField(
                hintText: 'Full Name',
                controller: nameController,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Full Name is required'.tr),
                ]).call),
            CommonTextField(
                hintText: 'Email',
                controller: emailController,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Email is required'),
                  EmailValidator(errorText: 'Please enter a valid email'.tr),
                ]).call),
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
                initialCountryCode: "IN", // Set to Australia
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
                obSecure: !hide.value,
                suffixIcon: IconButton(
                  onPressed: () {
                    hide.value = !hide.value;
                  },
                  icon: hide.value
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Please enter your password'.tr),
                  MinLengthValidator(8,
                      errorText:
                          'Password must be at least 8 characters, with 1 special character & 1 numerical'
                              .tr),
                  // MaxLengthValidator(16, errorText: "Password maximum length is 16"),
                  PatternValidator(r"(?=.*\W)(?=.*?[#?!@()$%^&*-_])(?=.*[0-9])",
                      errorText:
                          "Password must be at least 8 characters, with 1 special character & 1 numerical"
                              .tr),
                ]).call,
              );
            }),
            Obx(() {
              return CommonTextField(
                hintText: 'Confirm Password',
                controller: confirmPasswordController,
                obSecure: !hide1.value,
                suffixIcon: IconButton(
                  onPressed: () {
                    hide1.value = !hide1.value;
                  },
                  icon: hide1.value
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return 'Please enter confirm password';
                  }
                  if (value.trim() != passwordController.text.trim()) {
                    return 'Confirm password is not matching';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Theme(
                      data: ThemeData(
                          unselectedWidgetColor: showValidation == false
                              ? Colors.white
                              : Colors.red),
                      child: Checkbox(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          value: value,
                          activeColor: Colors.orange,
                          visualDensity:
                              const VisualDensity(vertical: 0, horizontal: 0),
                          onChanged: (newValue) {
                            setState(() {
                              value = newValue!;
                              setState(() {});
                            });
                          }),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // Return the dialog box widget
                          return AlertDialog(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Terms And Conditions',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Icon(Icons.cancel_outlined))
                              ],
                            ),
                            content: const Text(
                                'Terms and conditions are part of a contract that ensure parties understand their contractual rights and obligations. Parties draft them into a legal contract, also called a legal agreement, in accordance with local, state, and federal contract laws. They set important boundaries that all contract principals must uphold.'
                                'Several contract types utilize terms and conditions. When there is a formal agreement to create with another individual or entity, consider how you would like to structure your deal and negotiate the terms and conditions with the other side before finalizing anything. This strategy will help foster a sense of importance and inclusion on all sides.'),
                            actions: const <Widget>[],
                          );
                        },
                      );
                    },
                    child: Row(
                      children: [
                        const Text('I Accept',
                            style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 13,
                                color: Colors.black)),
                        Text(
                          ' Terms And Conditions?',
                          style: GoogleFonts.poppins(
                              color: const Color(0xffFF730A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.04),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  // for sign in button
                  GestureDetector(
                    onTap: () {
                      if (formKey1.currentState!.validate()) {
                        if (value == true) {
                          checkEmailInFirestore();
                        } else {
                          showSnackBar(
                              context, 'Please select terms & conditions');
                        }
                      }
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
                          "Sign Up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
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
                      //socialIcon("assets/images/facebook.png"),
                    ],
                  ),
                  SizedBox(height: size.height * 0.07),
                  Text.rich(
                    TextSpan(
                        text: "Already have an account ? ",
                        style: const TextStyle(
                          color: Color(0xff6F6B7A),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(
                              text: "Login now",
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
                                          const SignInScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.ease;
                                        var tween = Tween(
                                                begin: begin, end: end)
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
        ),
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
}
