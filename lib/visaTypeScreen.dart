import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trunriproject/home/bottom_bar.dart';
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
    if (selectedVisaType != null) {
      FirebaseFirestore.instance
          .collection('visaType')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'visaType': selectedVisaType}).then((value) {
        NewHelper.hideLoader(loader);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MyBottomNavBar(),
          ),
          (Route<dynamic> route) => false,
        );
        showSnackBar(context, 'Visa Type Added Successfully');
      }).catchError((error) {
        NewHelper.hideLoader(loader);
        showSnackBar(context, 'Error: $error');
      });
    } else {
      NewHelper.hideLoader(loader);
      showSnackBar(context, 'Please select visa type');
    }
  }

  Widget buildRadioButton(int value, String label) {
    bool isSelected = selectedVisaType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVisaType = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.shade200,
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? Colors.orange : Colors.white,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: const Icon(
              Icons.keyboard_arrow_left_outlined,
              color: Colors.black87,
              size: 30,
            )),
        title: Text(
          'Visa Type'.tr,
          style: GoogleFonts.poppins(
              color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We collect visa status to personalize community updates, news, and services according to your residency.'
                    .tr,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              buildRadioButton(1, 'Student visa'),
              buildRadioButton(2, 'Temporary resident'),
              buildRadioButton(3, 'Permanent resident'),
              buildRadioButton(4, 'Tourist visa'),
              buildRadioButton(5, 'Work visa'),
              buildRadioButton(6, 'Others'),
              const SizedBox(height: 30),
              SizedBox(
                width: size.width,
                child: ElevatedButton(
                  onPressed: visaType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF730A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: Colors.orangeAccent.shade200,
                  ),
                  child: Text(
                    "Next",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
