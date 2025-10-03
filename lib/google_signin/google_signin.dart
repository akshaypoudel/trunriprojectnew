import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/currentLocation.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/nativAddressScreen.dart';
import 'package:trunriproject/widgets/customTextFormField.dart';
import 'package:trunriproject/widgets/helper.dart';

class CustomGoogleSignin {
///////////////////////////////////////

  Future<void> signInWithGoogle(BuildContext context,
      {String termAndCondition = ''}) async {
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

      final user = FirebaseAuth.instance.currentUser;
      bool isNewUser = userCredential.additionalUserInfo!.isNewUser;

      if (isNewUser) {
        NewHelper.hideLoader(loader);

        // Show bottom sheet and wait for user personal details
        Map<String, String>? personalDetails =
            await showPersonalDetailsSheet(context, termAndCondition);
        if (personalDetails == null) {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            try {
              await currentUser.delete();
            } on FirebaseAuthException catch (e) {
              // If the user needs to reauthenticate, sign out instead
              if (e.code == 'requires-recent-login') {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
              }
            }
          }
          NewHelper.hideLoader(loader);
          showSnackBar(context, "User details not filled");
          return;
        }

        // Register and save extra info
        await registerWithGoogle(
          userCredential.user!.displayName!,
          userCredential.user?.email,
          personalDetails,
          context,
        );
        showSnackBar(context, "User Registered Successfully");
        checkIfUserInAustralia();
      } else {
        if (user != null) {
          await PresenceService.setUserOnline();
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['isBlocked'] == true) {
          GoogleSignIn().signOut();
          FirebaseAuth.instance.signOut();
          NewHelper.hideLoader(loader);
          showSnackBar(context, "User is Blocked by Admin");
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MyBottomNavBar(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
          (Route<dynamic> route) => false,
        );
        showSnackBar(context, "User Log In Successfull");
      }
    } on Exception catch (e) {
      showSnackBar(context, 'exception occured = $e');
      log('exception->$e');
    } finally {
      NewHelper.hideLoader(loader);
    }
  }

////////////////////////////////////

  Future<void> registerWithGoogle(String name, email,
      Map<String, String> details, BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    FirebaseFirestore.instance.collection('User').doc(uid).set({
      'name': name,
      'email': email,
      'phoneNumber': "",
      'password': "",
      'address': "",
      'profile': "",
      'isOnline': true,
      'lastSeen': Timestamp.now(),
      'isSubscribed': false,
      'isBlocked': false,
      'subscriptionExpiry': DateTime.now(),
      'friendRequestLimit': 2,
      'profession': details['profession'],
      'hometown': {
        'city': details['city'],
        'state': details['state'],
        'address': details['address'],
      },
      'friends': [],
      'friendRequests': {
        'sent': [],
        'received': [],
      },
    }).then((value) {
      NewHelper.hideLoader(loader);
    });
  }

  void checkIfUserInAustralia() {
    Future.delayed(Duration.zero, () async {
      bool inAustralia = await isUserInAustralia();

      if (!inAustralia) {
        Get.offAll(
          () => const PickUpAddressScreen(),
        );
      } else {
        Get.offAll(
          () => const CurrentAddress(
            isProfileScreen: false,
            savedAddress: '',
            latitude: '',
            longitude: '',
            radiusFilter: 50,
          ),
        );
      }
    });
  }

  Future<bool> isUserInAustralia() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return false;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return placemarks.isNotEmpty && placemarks.first.isoCountryCode == 'AU';
  }

  Future<Map<String, String>?> showPersonalDetailsSheet123(
      BuildContext context, String termAndCondition) async {
    final formKey = GlobalKey<FormState>();
    final professionController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final addressController = TextEditingController();
    bool value = false;
    bool showValidation = false;

    return showModalBottomSheet<Map<String, String>>(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext ctx) {
        Size size = MediaQuery.of(ctx).size;
        return SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  top: 24,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Tell Us About You",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color(0xff353047),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CommonTextField(
                          hintText: 'Profession',
                          controller: professionController,
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: 'Profession is required'),
                          ]).call),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "HomeTown",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xff353047)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CommonTextField(
                          hintText: 'City',
                          controller: cityController,
                          validator: MultiValidator([
                            RequiredValidator(errorText: 'City is required'),
                          ]).call),
                      const SizedBox(height: 12),
                      CommonTextField(
                          hintText: 'State',
                          controller: stateController,
                          validator: MultiValidator([
                            RequiredValidator(errorText: 'State is required'),
                          ]).call),
                      const SizedBox(height: 12),
                      CommonTextField(
                          hintText: 'Address',
                          controller: addressController,
                          validator: MultiValidator([
                            RequiredValidator(errorText: 'Address is required'),
                          ]).call),
                      const SizedBox(height: 14),
                      Row(
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
                                  visualDensity: const VisualDensity(
                                      vertical: 0, horizontal: 0),
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
                                builder: (BuildContext _) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Terms And Conditions',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Icon(
                                            Icons.cancel_outlined,
                                          ),
                                        )
                                      ],
                                    ),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 400,
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          padding:
                                              const EdgeInsets.only(right: 16),
                                          child: Text(
                                            termAndCondition,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                    actions: const <Widget>[],
                                  );
                                },
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'I Accept',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  ' Terms And Conditions?',
                                  style: TextStyle(
                                    color: Color(0xffFF730A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: size.width,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF730A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() => showValidation = true);
                            if (formKey.currentState!.validate()) {
                              if (value == true) {
                                Navigator.pop<Map<String, String>>(context, {
                                  'profession':
                                      professionController.text.trim(),
                                  'city': cityController.text.trim(),
                                  'state': stateController.text.trim(),
                                  'address': addressController.text.trim(),
                                });
                              } else {
                                showSnackBar(context,
                                    'Please accept terms & conditions');
                              }
                            }
                          },
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, String>?> showPersonalDetailsSheet(
      BuildContext context, String termAndCondition) async {
    final formKey = GlobalKey<FormState>();
    final professionController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final addressController = TextEditingController();
    bool value = false;
    bool showValidation = false;

    return showModalBottomSheet<Map<String, String>>(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false, // Prevent dismiss on tap outside
      enableDrag: false, // Disable swipe down drag dismiss
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext ctx) {
        Size size = MediaQuery.of(ctx).size;
        return WillPopScope(
          onWillPop: () async => false, // Disable back button dismiss
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                    top: 24,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Tell Us About You",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xff353047),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CommonTextField(
                            hintText: 'Profession',
                            controller: professionController,
                            validator: MultiValidator([
                              RequiredValidator(
                                  errorText: 'Profession is required'),
                            ]).call),
                        const SizedBox(height: 14),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "HomeTown",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xff353047)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CommonTextField(
                            hintText: 'City',
                            controller: cityController,
                            validator: MultiValidator([
                              RequiredValidator(errorText: 'City is required'),
                            ]).call),
                        const SizedBox(height: 12),
                        CommonTextField(
                            hintText: 'State',
                            controller: stateController,
                            validator: MultiValidator([
                              RequiredValidator(errorText: 'State is required'),
                            ]).call),
                        const SizedBox(height: 12),
                        CommonTextField(
                            hintText: 'Address',
                            controller: addressController,
                            validator: MultiValidator([
                              RequiredValidator(
                                  errorText: 'Address is required'),
                            ]).call),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Transform.scale(
                              scale: 1.1,
                              child: Theme(
                                data: ThemeData(
                                    unselectedWidgetColor:
                                        showValidation == false
                                            ? Colors.white
                                            : Colors.red),
                                child: Checkbox(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    value: value,
                                    activeColor: Colors.orange,
                                    visualDensity: const VisualDensity(
                                        vertical: 0, horizontal: 0),
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
                                  builder: (BuildContext _) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                              child: const Icon(
                                                  Icons.cancel_outlined))
                                        ],
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        height: 400,
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.only(
                                                right: 16),
                                            child: Text(
                                              termAndCondition,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  color: Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                      actions: const <Widget>[],
                                    );
                                  },
                                );
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'I Accept',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    ' Terms And Conditions?',
                                    style: TextStyle(
                                      color: Color(0xffFF730A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: size.width,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFF730A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() => showValidation = true);
                              if (formKey.currentState!.validate()) {
                                if (value == true) {
                                  // Check for empty or null in any controller, return null if found
                                  if (professionController.text
                                          .trim()
                                          .isEmpty ||
                                      cityController.text.trim().isEmpty ||
                                      stateController.text.trim().isEmpty ||
                                      addressController.text.trim().isEmpty) {
                                    // Do not pop, return null
                                    Navigator.pop<Map<String, String>?>(
                                        context, null);
                                    return;
                                  }
                                  Navigator.pop<Map<String, String>>(context, {
                                    'profession':
                                        professionController.text.trim(),
                                    'city': cityController.text.trim(),
                                    'state': stateController.text.trim(),
                                    'address': addressController.text.trim(),
                                  });
                                } else {
                                  showSnackBar(context,
                                      'Please accept terms & conditions');
                                }
                              }
                            },
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
