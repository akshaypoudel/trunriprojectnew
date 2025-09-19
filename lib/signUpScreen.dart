import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:trunriproject/google_signin/google_signin.dart';
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
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController professionController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  CustomGoogleSignin googleSignin = CustomGoogleSignin();
  String code = "+61";
  bool value = false;
  bool showValidation = false;
  FirebaseAuth auth = FirebaseAuth.instance;

  String termAndCondition = '';

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
        showSnackBar(context, 'OTP sent successfully');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewOtpScreen(
              isSignInScreen: false,
              phoneNumber: completePhoneNum,
              verificationId: verificationId,
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              // profession: professionController.text.trim(), // NEW
              // homeTown: homeTownController.text.trim(), // NEW
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        SignUpScreen.verificationOTP = verificationId;
      },
    );
  }

  final formKey1 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loadTermAndCondition();
  }

  void loadTermAndCondition() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('settings_document')
          .get();

      if (docSnapshot.exists) {
        termAndCondition = docSnapshot.data()?['terms_and_condition'] ?? '';
        log('Terms and Conditions loaded successfully');
      } else {
        termAndCondition = '';
        log('Settings document not found');
      }
    } catch (e) {
      termAndCondition = '';
      log('Error loading Terms and Conditions: $e');
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    professionController.dispose();
    cityController.dispose();
    stateController.dispose();
    addressController.dispose();
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

            // Existing Fields
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

            // Phone Field (unchanged)
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: IntlPhoneField(
                flagsButtonPadding: const EdgeInsets.all(8),
                dropdownIconPosition: IconPosition.trailing,
                showDropdownIcon: false,
                enabled: true,
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

            // NEW: Profession Field (Simple hint)
            CommonTextField(
                hintText: 'Profession',
                controller: professionController,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Profession is required'),
                ]).call),

            const SizedBox(height: 20),

            // NEW: HomeTown Section Header
            const Padding(
              padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HomeTown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff353047),
                  ),
                ),
              ),
            ),

// NEW: City Field
            CommonTextField(
                hintText: 'City',
                controller: cityController,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'City is required'),
                ]).call),

// NEW: State Field
            CommonTextField(
                hintText: 'State',
                controller: stateController,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'State is required'),
                ]).call),

            // NEW: Address Field
            CommonTextField(
                hintText: 'Address',
                controller: addressController,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Address is required'),
                ]).call),

            const SizedBox(height: 10),

            // Terms & Conditions Checkbox
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
                            });
                          }),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
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
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 400,
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    termAndCondition,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            actions: const <Widget>[],
                          );
                        },
                      );
                    },
                    child: Row(
                      children: [
                        const Text(
                          'I Accept',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
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

            // Rest of your existing code (Sign Up button, social login, etc.)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (formKey1.currentState!.validate()) {
                        if (value == true) {
                          checkEmailInFirestore();
                        } else {
                          showSnackBar(
                            context,
                            'Please select terms & conditions',
                          );
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
                                      const PickUpAddressScreen(),
                                ),
                              );
                            } catch (error) {
                              showSnackBar(
                                context,
                                'Error signing in with Apple: $error',
                              );
                            }
                          },
                          child: socialIcon("assets/images/apple.png"),
                        ),
                      const SizedBox(
                        width: 10,
                      ),
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
