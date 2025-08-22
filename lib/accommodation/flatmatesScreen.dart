import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import '../widgets/commomButton.dart';
import '../widgets/helper.dart';

class FlatmateScreen extends StatefulWidget {
  final String formID;
  final Map<String, dynamic> data;
  const FlatmateScreen({
    super.key,
    required this.formID,
    required this.data,
  });

  @override
  State<FlatmateScreen> createState() => _FlatmateScreenState();
}

class _FlatmateScreenState extends State<FlatmateScreen> {
  RangeValues currentRangeValues = const RangeValues(10, 80);
  bool male = false;
  bool female = false;
  bool nonBinary = false;
  bool isStudents = false;
  bool isEmployees = false;
  bool isFamilies = false;
  bool isSingle = false;
  bool isIndividuals = false;
  bool isCouples = false;
  RangeValues _currentRangeValues = const RangeValues(0, 100);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool showGenderError = false;
  bool showSituationError = false;

  bool isFormValid() {
    bool genderSelected = male || female || nonBinary;
    bool situationSelected = isStudents ||
        isEmployees ||
        isFamilies ||
        isSingle ||
        isIndividuals ||
        isCouples;
    return genderSelected && situationSelected;
  }

  Future<void> saveFlatmatesData() async {
    if (!isFormValid()) {
      setState(() {
        showGenderError = !(male || female || nonBinary);
        showSituationError = !(isStudents ||
            isEmployees ||
            isFamilies ||
            isSingle ||
            isIndividuals ||
            isCouples);
      });
      showSnackBar(context, 'Please fill in all required fields');
      return;
    }

    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('accommodation').doc(widget.formID).set({
        ...widget.data,
        'male': male,
        'female': female,
        'nonBinary': nonBinary,
        'isStudents': isStudents,
        'isEmployees': isEmployees,
        'isFamilies': isFamilies,
        'isSingle': isSingle,
        'isIndividuals': isIndividuals,
        'isCouples': isCouples,
        'currentRangeValues': {
          'start': _currentRangeValues.start,
          'end': _currentRangeValues.end,
        },
        'posterName': AuthServices().getCurrentUserDisplayName(),
        'status': 'pending',
        'isReported': false,
      }, SetOptions(merge: true));
      Get.offAll(const MyBottomNavBar());
      NewHelper.hideLoader(loader);
      // showSnackBar(context, 'Your property lisitng saved');
      showSnackBar(context,
          'Listing submitted for review. It will go live after approval.');
    } else {
      NewHelper.hideLoader(loader);
      log('No matching document found');
    }
  }

  void showToast(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'OK',
          onPressed: scaffold.hideCurrentSnackBar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Step 5: Flatmates',
          style: TextStyle(color: Colors.black, fontSize: 17),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Who would you prefer to live in the property?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose at least one option.',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: male,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          male = value ?? false;
                          showGenderError = false;
                        });
                      },
                    ),
                    const Text(
                      'Male',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: female,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          female = value ?? false;
                          showGenderError = false;
                        });
                      },
                    ),
                    const Text(
                      'Female',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: nonBinary,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          nonBinary = value ?? false;
                          showGenderError = false;
                        });
                      },
                    ),
                    const Text(
                      'Non-binary',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (showGenderError)
                  const Text(
                    'Please select at least one gender',
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'What is the preferred age group?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${_currentRangeValues.start.round()} to ${_currentRangeValues.end.round()} years old',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
                RangeSlider(
                  values: _currentRangeValues,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: const Color(0xffFF730A),
                  labels: RangeLabels(
                    _currentRangeValues.start.round().toString(),
                    _currentRangeValues.end.round().toString(),
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _currentRangeValues = values;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Who are you looking to accommodate in your rental home?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isStudents,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          isStudents = value ?? false;
                          showSituationError = false;
                        });
                      },
                    ),
                    const Text(
                      'Students',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isEmployees,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          isEmployees = value ?? false;
                          showSituationError = false;
                        });
                      },
                    ),
                    const Text(
                      'Employees',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isFamilies,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          isFamilies = value ?? false;
                          showSituationError = false;
                        });
                      },
                    ),
                    const Text(
                      'Families',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isSingle,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          isSingle = value ?? false;
                          showSituationError = false;
                        });
                      },
                    ),
                    const Text(
                      'Single',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isIndividuals,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          isIndividuals = value ?? false;
                          showSituationError = false;
                        });
                      },
                    ),
                    const Text(
                      'Individuals',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isCouples,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          isCouples = value ?? false;
                          showSituationError = false;
                        });
                      },
                    ),
                    const Text(
                      'Couples',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (showSituationError)
                  const Text(
                    'Please select at least one situation',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(15.0).copyWith(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: CommonButton(
                  text: 'Continue',
                  color: const Color(0xffFF730A),
                  textColor: Colors.white,
                  onPressed: () {
                    if (isFormValid()) {
                      saveFlatmatesData();
                    } else {
                      setState(() {
                        showGenderError = !(male || female || nonBinary);
                        showSituationError = !(isStudents ||
                            isEmployees ||
                            isFamilies ||
                            isSingle ||
                            isIndividuals ||
                            isCouples);
                      });
                      showToast('Please fill in all required fields');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
