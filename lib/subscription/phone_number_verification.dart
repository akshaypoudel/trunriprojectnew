import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:trunriproject/subscription/otp_verification.dart';
import 'package:trunriproject/widgets/appTheme.dart';
import 'package:trunriproject/widgets/helper.dart';

class PhoneNumberVerification extends StatefulWidget {
  const PhoneNumberVerification({super.key});

  @override
  State<PhoneNumberVerification> createState() =>
      _PhoneNumberVerificationState();
}

class _PhoneNumberVerificationState extends State<PhoneNumberVerification> {
  TextEditingController phoneController = TextEditingController();
  RxBool hide = true.obs;
  RxBool hide1 = true.obs;
  bool showOtpField = false;
  int? _resendToken;

  String code = "+61";

  void requestForOtp() async {
    String completePhoneNum = '$code${phoneController.text.trim()}';

    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: completePhoneNum,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
        showSnackBar(context, "Phone number linked successfully");
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBar(context, "Verification failed: ${e.message}");
        NewHelper.hideLoader(loader);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _resendToken = resendToken;
        });
        NewHelper.hideLoader(loader);
        showSnackBar(context, 'OTP sent successfully');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerification(
              verificationId: verificationId,
              phoneNumber: completePhoneNum,
            ),
          ),
        );
      },
      forceResendingToken: _resendToken,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<bool> doesPhoneExist(String phone) async {
    final query = await FirebaseFirestore.instance
        .collection('User')
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return false;
    } else {
      return true;
    }

    // return query.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      body: SafeArea(
          child: ListView(
        children: [
          Image.asset(
            "assets/images/hand.gif",
            height: 300.0,
            width: 300.0,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Please enter your phone number to continue payment",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 23),
            ),
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
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    bool exist = await doesPhoneExist(
                      '$code${phoneController.text.trim()}',
                    );
                    if (!exist) {
                      requestForOtp();
                    } else {
                      showSnackBar(context, "User already exists!");
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
                const SizedBox(height: 20),
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
