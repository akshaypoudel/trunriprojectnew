import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

      bool isNewUser = userCredential.additionalUserInfo!.isNewUser;

      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => (!isNewUser)
              ? const MyBottomNavBar()
              : const PickUpAddressScreen(),
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

      if (isNewUser) {
        registerWithGoogle(
          userCredential.user!.displayName!,
          userCredential.user?.email,
          context,
        );
      }

      if (!isNewUser) {
        showSnackBar(context, "User Log In Successfull");
      } else {
        showSnackBar(context, "User Registered Successfully");
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
      'profile': ""
    }).then((value) {
      NewHelper.hideLoader(loader);
    });
  }
}
