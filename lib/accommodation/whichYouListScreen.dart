import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../widgets/helper.dart';
import 'locationScreen.dart';

class WhichYouListScreen extends StatefulWidget {
  const WhichYouListScreen({super.key});

  @override
  State<WhichYouListScreen> createState() => _WhichYouListScreenState();
}

class _WhichYouListScreenState extends State<WhichYouListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Uuid uuid = const Uuid();
  String formID = '';

  Future<void> saveData(String text) async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    User? user = _auth.currentUser;

    if (user != null) {
      formID = uuid.v4();

      final Map<String, dynamic> data = {
        'uid': user.uid,
        'roomType': text,
        'formID': formID,
      };
      NewHelper.hideLoader(loader);

      Get.to(() => LocationScreen(formID: formID, data: data));
    } else {
      NewHelper.hideLoader(loader);
      log('No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: const Icon(Icons.clear)),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 15, right: 15),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'What do you wish to list ?',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () async {
                    await saveData('A room');
                    // Get.to(LocationScreen(
                    //   dateTime: formID,
                    // ));
                  },
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(11)),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/aroom.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const Text(
                            'A room',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    await saveData('Entire home for rent');
                    // Get.to(LocationScreen());
                  },
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/apartment.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const Text(
                            'Entire home for rent',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    await saveData('Studio unit');
                    // Get.to(LocationScreen());
                  },
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/apartment.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const Text(
                            'Studio unit',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    await saveData('Granny flat');
                    // Get.to(LocationScreen());
                  },
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/apartment.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const Text(
                            'Granny flat',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    await saveData('Shared room / rooms in shared house');
                    // Get.to(LocationScreen());
                  },
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/apartment.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const Expanded(
                            child: Text(
                              'Shared room / rooms in shared house',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    await saveData('Shared bedroom');
                    // Get.to(LocationScreen());
                  },
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/apartment.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const Text(
                            'Shared bedroom',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    await saveData('Single bed unit');
                    // Get.to(LocationScreen());
                  },
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/apartment.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          const Text(
                            'Single bed unit',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
