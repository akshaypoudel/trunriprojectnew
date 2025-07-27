import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import '../widgets/helper.dart';

enum UpdateType { set, update }

class FirebaseFireStoreService {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static String profileCollection = "User";
  final FirebaseAuth auth = FirebaseAuth.instance;
  final storageRef = FirebaseStorage.instance.ref();

  String get userId => auth.currentUser!.uid;

  bool get userLoggedIn => auth.currentUser != null;

  String get phoneNumber => auth.currentUser!.phoneNumber!;

  Future<bool> checkUserProfile() async {
    final response =
        await fireStore.collection(profileCollection).doc(userId).get();
    log('user current uid ppp : $userId');
    if (response.exists) {
      return true;
    }
    return false;
  }

  // Future<ModelProfileData?> getProfileDetails() async {
  //   final response =
  //       await fireStore.collection(profileCollection).doc(userId).get();
  //   if (response.exists) {
  //     log("Api Repsponse.....    ${jsonEncode(response.data())}");
  //     if (response.data() == null) return null;
  //     return ModelProfileData.fromJson(response.data()!);
  //   }
  //   return null;
  // }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String address,
    required File profileImage,
    required bool allowChange,
    required BuildContext context,
    required Function(bool gg) updated,
  }) async {
    String profileUrl = profileImage.path;
    String? imageUrl;
    OverlayEntry loader = NewHelper.overlayLoader(context);
    try {
      if (allowChange) {
        Overlay.of(context).insert(loader);
        imageUrl = await getProfileImageUrl(profileImage);

        // final userProfileImageRef = storageRef.child("user_images/$userId");

        // UploadTask task6 = userProfileImageRef.putFile(profileImage);
        // profileUrl = await (await task6).ref.getDownloadURL();
      }
      await fireStore.collection(profileCollection).doc(userId).update({
        // "email": email,
        "name": name,
        "address": address,
        "profile": imageUrl,
      });

      showSnackBar(context, "Profile updated");
      updated(true);
      NewHelper.hideLoader(loader);
      return true;
    } catch (e) {
      showSnackBar(context, 'Error: ${e.toString()}');
      NewHelper.hideLoader(loader);
      return false;
    } finally {
      NewHelper.hideLoader(loader);
    }
  }

  Future<String> getProfileImageUrl(File profileImage) async {
    final fileName = path.basename(profileImage.path);
    final storageRef =
        FirebaseStorage.instance.ref().child('user_images/$fileName');
    final uploadTask = await storageRef.putFile(profileImage);

    return await storageRef.getDownloadURL();
  }

  Future<void> updateProfilePictureForCommunity(
      File profileImageFilePath) async {
    String newProfileUrl = await getProfileImageUrl(profileImageFilePath);
    final postsQuery = await FirebaseFirestore.instance
        .collection('community_posts')
        .where('uid', isEqualTo: userId)
        .get();

    for (var doc in postsQuery.docs) {
      await doc.reference.update({'profileUrl': newProfileUrl});
    }
  }
}
