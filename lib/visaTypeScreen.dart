import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/home/home_screen.dart';
import 'package:trunriproject/widgets/helper.dart';

class VisaTypeScreen extends StatefulWidget {
  const VisaTypeScreen({super.key});

  @override
  State<VisaTypeScreen> createState() => _VisaTypeScreenState();
}

class _VisaTypeScreenState extends State<VisaTypeScreen> {
  int? selectedVisaType;

  void visaType() {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    FirebaseFirestore.instance
        .collection('visaType')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({'visaType': selectedVisaType}).then((value) {
      if (selectedVisaType != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MyBottomNavBar(),
          ),
          (Route<dynamic> route) => false,
        );
        showSnackBar(context, 'Visa Type Added Successfully');
        NewHelper.hideLoader(loader);
      } else {
        showSnackBar(context, 'please select visa Type');
        NewHelper.hideLoader(loader);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: const Icon(Icons.keyboard_arrow_left_outlined)),
        title: Text(
          'Visa Type'.tr,
          style: GoogleFonts.poppins(
              color: const Color(0xff292F45),
              fontWeight: FontWeight.w600,
              fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We collect visa status to personalize community updates, news, and services according to your residency.'
                    .tr,
                style: GoogleFonts.poppins(
                    color: const Color(0xff292F45),
                    fontWeight: FontWeight.w400,
                    fontSize: 16),
              ),
              const SizedBox(
                height: 10,
              ),
              buildRadioButton(1, 'Student visa'),
              buildRadioButton(2, 'Temporary resident'),
              buildRadioButton(3, 'Permanent resident'),
              buildRadioButton(4, 'Tourist visa'),
              buildRadioButton(5, 'Work visa'),
              buildRadioButton(6, 'Others'),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  visaType();
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
                      "Next",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 40,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRadioButton(int value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11), color: Colors.grey.shade300),
      child: Row(
        children: [
          Radio(
            value: value,
            groupValue: selectedVisaType,
            onChanged: (newValue) {
              setState(() {
                selectedVisaType = newValue;
              });
            },
          ),
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 20, color: Colors.black),
          )
        ],
      ),
    );
  }
}
