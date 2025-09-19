import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/currentLocation.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/nativAddressScreen.dart';
import 'package:trunriproject/widgets/helper.dart';

class CustomGoogleSignin {
  Future<void> signInWithGoogle(BuildContext context) async {
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
        registerWithGoogle(
          userCredential.user!.displayName!,
          userCredential.user?.email,
          context,
        );
      } else {
        if (user != null) {
          await PresenceService.setUserOnline();
        }
      }

      if (isNewUser) {
        showSnackBar(context, "User Registered Successfully");
      }

      if (isNewUser) {
        checkIfUserInAustralia();
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['isBlocked'] == true) {
          //signout users
          GoogleSignIn().signOut();
          FirebaseAuth.instance.signOut();

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
      }
      if (!isNewUser) {
        showSnackBar(context, "User Log In Successfull");
      }
    } on Exception catch (e) {
      log('exception->$e');
    } finally {
      NewHelper.hideLoader(loader);
    }
  }

  void registerWithGoogle(String name, email, BuildContext context) async {
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
      'friends': [],
      'friendRequests': {
        'sent': [],
        'received': [],
      }
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
}
