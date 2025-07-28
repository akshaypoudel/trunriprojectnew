import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  String? getCurrentUserDisplayName() {
    return _auth.currentUser!.displayName;
  }
}
