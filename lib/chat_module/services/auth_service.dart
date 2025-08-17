import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  String? getCurrentUserDisplayName() {
    return _auth.currentUser!.displayName;
  }

  void setUserProfilePicture(String url) {
    // _auth.currentUser.photoURL;
    _auth.currentUser!.updatePhotoURL(url);
  }

  String? getUserProfilePicture() => _auth.currentUser!.photoURL;
}
