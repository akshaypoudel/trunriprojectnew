import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/currentLocation.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/profile/show_address_text.dart';
import 'package:trunriproject/signinscreen.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../recoveryPasswordScreen.dart';
import '../widgets/helper.dart';
import '../home/firestore_service.dart';
import 'addressListScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.fromLogin, this.home});
  final bool? fromLogin;
  final bool? home;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFireStoreService fireStoreService = FirebaseFireStoreService();
  bool isobscurepassword = true;
  File userImageFile = File("");
  bool isEditing = false;
  bool imagePicked = false;
  bool dataLoaded = true;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String addressText = '';
  String city = '';
  String state = '';
  String latitude = '';
  String longitude = '';
  String imageUrl = '';

  updateProfile() async {
    if (!formKey.currentState!.validate()) {
      showSnackBar(context, "Returning From Method");
      return;
    }
    try {
      await fireStoreService.updateProfile(
        address: addressText,
        allowChange: userImageFile.path.isEmpty ? false : true,
        context: context,
        email: emailController.text.trim(),
        name: nameController.text.trim(),
        profileImage: userImageFile,
        updated: (bool value) {
          if (value) {
            if (widget.fromLogin == false) {
              Get.back();
            } else {
              Get.offAll(const MyBottomNavBar());
              fetchUserData();
            }
          } else {
            showSnackBar(context, "Failed to update profile");
          }
        },
      );
    } catch (e) {
      showSnackBar(context, "Error updating profile: $e");
      print("Error updating profile: $e");
    }
  }

  Future<void> fetchUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    String phone = '';
    String newEmail = '';

    dynamic snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(auth.currentUser!.uid)
        .get();

    dynamic addressSnapshot = await FirebaseFirestore.instance
        .collection('currentLocation')
        .doc(auth.currentUser!.uid)
        .get();

    if (snapshot.exists) {
      newEmail = snapshot.get('email') ?? '';
      phone = snapshot.get('phoneNumber') ?? '';
      imageUrl = snapshot.get('profile') ?? '';
    }

    if (addressSnapshot.exists) {
      final street = addressSnapshot.data()['Street'] ?? '';
      final city = addressSnapshot.data()['city'] ?? '';
      this.city = city;
      final town = addressSnapshot.data()['town'] ?? '';
      final state = addressSnapshot.data()['state'] ?? '';
      this.state = state;
      final country = addressSnapshot.data()['country'] ?? '';
      final zip = addressSnapshot.data()['zipcode'] ?? '';

      final fullAddress = '$street, $town, $city, $state, $zip, $country';
      addressText = fullAddress;
      latitude = addressSnapshot.data()['latitude'] ?? '';
      longitude = addressSnapshot.data()['longitude'] ?? '';

      final shortFormAddress = '📍 $city, ${getStateShortForm(state)}';
      addressController.text = shortFormAddress;
    } else {
      log('currentLocation doesnt exists');
    }

    dynamic querySnapshot;
    if (phone.isNotEmpty) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('phoneNumber', isEqualTo: phone)
          .get();
    } else {
      querySnapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: newEmail)
          .get();
    }
    try {
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        nameController.text = userData['name'] ?? '';
        emailController.text = userData['email'] ?? '';

        name = userData['name'] ?? '';
        email = userData['email'] ?? '';
        log('user address = $addressText');
      } else {
        showSnackBar(context, "User data not found for phone number");
      }
    } catch (e) {
      showSnackBar(context, "Error fetching user data: ${e.toString()}");
    }
  }

  String getStateShortForm(String stateName) {
    List<String> words = stateName.trim().split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words[0]; // Single word (e.g., Rajasthan)
    }

    // Multiple words: take first letter of each word and capitalize
    return words.map((word) => word[0].toUpperCase()).join();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    await fetchUserData();
    setState(() {});
  }

  @override
  void dispose() {
    addressController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () {
              if (isEditing) {
                updateProfile();
              }
              setState(() {
                isEditing = !isEditing;
              });
            },
            child: isEditing
                ? const Text(
                    'save',
                    style: TextStyle(color: Colors.green, fontSize: 17),
                  )
                : Image.asset(
                    'assets/images/edit.png',
                    height: 30,
                  ),
          ),
          const SizedBox(
            width: 15,
          )
        ],
      ),
      body: dataLoaded
          ? Container(
              height: Get.height,
              color: Colors.white,
              padding: const EdgeInsets.only(left: 15, top: 20, right: 15),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                NewHelper.showImagePickerSheet(
                                    gotImage: (File gg) {
                                      userImageFile = gg;
                                      imagePicked = true;
                                      updateProfile();
                                      setState(() {});
                                    },
                                    context: context);
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 4, color: Colors.white),
                                      boxShadow: [
                                        BoxShadow(
                                          spreadRadius: 2,
                                          blurRadius: 10,
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                        )
                                      ],
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10000),
                                      child: (imageUrl.isNotEmpty)
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              CupertinoIcons.person_alt_circle,
                                              size: 45,
                                              color: Colors.grey.shade700,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            width: 4,
                                            color: Colors.white,
                                          ),
                                          color: Colors.blue),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    decoration: InputDecoration(
                                      // border: InputBorder.none,
                                      hintText: name,
                                    ),
                                    readOnly: !isEditing,
                                    controller: nameController,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        color: Colors.black),
                                  ),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      hintText: email,
                                    ),
                                    readOnly: !isEditing,
                                    controller: emailController,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        color: Colors.black),
                                  ),
                                  ShowAddressText(
                                    controller: addressController,
                                    onTap: () async {
                                      Map<String, dynamic> selectedAddress =
                                          await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CurrentAddress(
                                            isProfileScreen: true,
                                            savedAddress: addressText,
                                            latitude: latitude,
                                            longitude: longitude,
                                          ),
                                        ),
                                      );

                                      if (selectedAddress.isNotEmpty) {
                                        setState(() {
                                          latitude =
                                              selectedAddress['latitude'];
                                          longitude =
                                              selectedAddress['longitude'];
                                          addressText =
                                              selectedAddress['address'];
                                          final shortFormAddress =
                                              '📍 ${selectedAddress['city']}, ${getStateShortForm(selectedAddress['state'])}';

                                          log('short form address == $shortFormAddress');
                                          addressController.text =
                                              shortFormAddress;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ListTile(
                          leading: Image.asset(
                            'assets/images/address.png',
                            height: 30,
                          ),
                          title: const Text('Address'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                          onTap: () {
                            Get.to(const AddressListScreen());
                          },
                        ),
                        const Divider(
                          height: 10,
                        ),
                        ListTile(
                          onTap: () {
                            Get.to(const RecoveryPasswordScreen());
                          },
                          leading: Image.asset(
                            'assets/images/password.png',
                            height: 30,
                          ),
                          title: const Text('Change Password'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                        ),
                        const Divider(
                          height: 10,
                        ),
                        ListTile(
                          leading: Image.asset(
                            'assets/images/language.png',
                            height: 30,
                          ),
                          title: const Text('Change Language'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                        ),
                        const Divider(
                          height: 10,
                        ),
                        ListTile(
                          leading: Image.asset(
                            'assets/images/notification.png',
                            height: 30,
                          ),
                          title: const Text('Notification preferences'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                        ),
                        const Divider(
                          height: 10,
                        ),
                        ListTile(
                          leading: Image.asset(
                            'assets/images/feedback.png',
                            height: 30,
                          ),
                          title: const Text('Feedback'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                        ),
                        const Divider(
                          height: 10,
                        ),
                        ListTile(
                          onTap: () {
                            Share.share('https://www.google.co.in/');
                          },
                          leading: Image.asset(
                            'assets/images/share.png',
                            height: 30,
                          ),
                          title: const Text('Share App'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                        ),
                        const Divider(
                          height: 10,
                        ),
                        ListTile(
                          onTap: () {
                            launchUrlString("tel://+917665096245");
                          },
                          leading: Image.asset(
                            'assets/images/contact.png',
                            height: 30,
                          ),
                          title: const Text('Contact Us'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 15,
                          ),
                        ),
                        const Divider(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            PresenceService.setUserOffline();
                            GoogleSignIn().signOut();
                            FirebaseAuth.instance.signOut().then((value) {
                              Get.offAll(const SignInScreen());
                              showSnackBar(context, "Logged Out Successfully");
                            });
                          },
                          child: ListTile(
                            leading: Image.asset(
                              'assets/images/logout.png',
                              height: 30,
                            ),
                            title: const Text('LogOut'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_outlined,
                              size: 15,
                            ),
                          ),
                        ),
                        //const Divider(
                        //  height: 10,
                        //),
                        // GestureDetector(
                        //   onTap: () async {
                        //     User? user = FirebaseAuth.instance.currentUser;
                        //     await user!.delete();
                        //     GoogleSignIn().signOut();
                        //     showSnackBar(
                        //         context, "Your account has been deleted");
                        //     Get.to(const SignUpScreen());
                        //   },
                        //   child: ListTile(
                        //     leading: Image.asset(
                        //       'assets/images/delete.png',
                        //       height: 30,
                        //     ),
                        //     title: const Text('Delete Account'),
                        //     trailing: const Icon(
                        //       Icons.arrow_forward_ios_outlined,
                        //       size: 15,
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 85),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            ),
    );
  }
}
