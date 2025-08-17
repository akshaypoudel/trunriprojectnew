import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/community/components/chat_provider.dart';
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
    try {
      final docSnapshot =
          await fireStore.collection(profileCollection).doc(userId).get();

      // log('Checking profile for userID: $userId');

      if (!docSnapshot.exists) {
        // log('User profile does not exist.');
        return false; // Or true if you want to allow unregistered users
      }

      final data = docSnapshot.data();

      // Defensive check
      if (data == null || !data.containsKey('isBlocked')) {
        log('User profile missing "isBlocked" field. Assuming not blocked.');
        return true;
      }

      final bool isBlocked = data['isBlocked'] == true;

      if (isBlocked) {
        log('User is blocked');
        Get.snackbar(
          'Access Denied',
          'User is blocked by Admin',
          backgroundColor: const Color(0xff0ff730a),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false; // 🚫 Don't allow sign-in
      }

      log('User is not blocked');
      return true; // ✅ Allow sign-in
    } catch (e, stack) {
      log('Error checking user profile: $e');
      log('Stack trace: $stack');
      Get.snackbar(
        'Access Denied',
        'Access is Denied',
        backgroundColor: const Color(0xff0ff730a),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false; // Fallback to block if something goes wrong
    }
  }

  Future<bool> checkUserProfile1() async {
    final response =
        await fireStore.collection(profileCollection).doc(userId).get();
    log('user current uid ppp : $userId');
    if (response.exists) {
      // return true;

      bool isBlocked = response.data()!['isBlocked'];
      if (isBlocked) {
        return false; //means, don't allow user to signin.
      } else {
        return true;
      }
    }
    return false;
  }

  Future<bool> updateProfile({
    required String name,
    required String address,
    // required File? profileImage,
    // required bool allowChange,
    required BuildContext context,
    required Function(bool gg) updated,
  }) async {
    // String? imageUrl;
    OverlayEntry loader = NewHelper.overlayLoader(context);
    // final provider = Provider.of<ChatProvider>(context, listen: false);

    try {
      // if (allowChange) {
      //   Overlay.of(context).insert(loader);
      //   imageUrl = await getProfileImageUrl(profileImage!);
      //   if (provider.getProfileImage != imageUrl) {
      //     provider.setProfileImage(imageUrl);
      //   }
      // }

      Map<String, dynamic> updateData = {"name": name};

      // if (imageUrl != null && provider.getProfileImage.isNotEmpty) {
      //   updateData["profile"] = imageUrl;
      // }

      await fireStore
          .collection(profileCollection)
          .doc(userId)
          .update(updateData);

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

  Future<void> updateProfilePicture(
    BuildContext context,
    File profileImage,
  ) async {
    final provider = Provider.of<ChatProvider>(context, listen: false);

    String url = await getProfileImageUrl(profileImage);
    provider.setProfileImage(url);
    await fireStore
        .collection(profileCollection)
        .doc(userId)
        .update({'profile': url});
    showSnackBar(context, 'Profile Picture Updated Successfully');
  }

  Future<String> getProfileImageUrl(File profileImage) async {
    try {
      // Create unique filename to avoid conflicts
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference imageRef =
          FirebaseStorage.instance.ref().child('user_images').child(fileName);
      final UploadTask uploadTask = imageRef.putFile(profileImage);

      // Wait for upload completion and get download URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      log('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Error uploading profile image: $e');
      rethrow; // This will be caught by the updateProfile method
    }
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
