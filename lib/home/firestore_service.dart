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

  Future<bool> updateProfile({
    required String name,
    required String address,
    required File profileImage,
    required bool allowChange,
    required BuildContext context,
    required Function(bool gg) updated,
  }) async {
    String? imageUrl;
    OverlayEntry loader = NewHelper.overlayLoader(context);
    try {
      if (allowChange) {
        Overlay.of(context).insert(loader);
        imageUrl = await getProfileImageUrl(profileImage);
      }
      await fireStore.collection(profileCollection).doc(userId).update({
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

  Future<String> getProfileImageUrl1(File profileImage) async {
    final fileName = path.basename(profileImage.path);
    final storageRef =
        FirebaseStorage.instance.ref().child('user_images/$fileName');

    return await storageRef.getDownloadURL();
  }

  Future<String> getProfileImageUrl(File profileImage) async {
    try {
      // Create unique filename to avoid conflicts
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference imageRef =
          FirebaseStorage.instance.ref().child('user_images').child(fileName);

      // Upload the file
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
