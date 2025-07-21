import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:trunriproject/widgets/helper.dart';

class OtpVerification extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerification({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final TextEditingController otpController = TextEditingController();

  RxInt timerInt = 30.obs;
  Timer? timer;
  late bool _isVerified;

  setTimer() {
    timerInt.value = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timerInt.value--;
      if (timerInt.value == 0) {
        timer.cancel();
      }
    });
  }

  void register(String completePhoneNum) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('User').doc(uid).update({
      'phoneNumber': completePhoneNum,
    });
  }

  void verifyOTP() async {
    if (_isVerified) {
      return;
    }
    if (otpController.text.trim().isEmpty) {
      showSnackBar(context, "Please enter OTP");
    } else {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otpController.text.trim(),
        );

        await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

        register(
          widget.phoneNumber,
        );

        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
        }
        _isVerified = true;
      } catch (e) {
        showSnackBar(context, "Invalid OTP");
      }
    }
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
        ),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _isVerified = false;
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
              verifyOTP();
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
