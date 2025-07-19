import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/currentLocation.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/profile/show_address_text.dart';
import 'package:trunriproject/signinscreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';
import 'package:trunriproject/subscription/subscription_success_screen.dart';
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
    final provider = Provider.of<LocationData>(context, listen: false);

    String phone = '';
    String newEmail = '';

    dynamic snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(auth.currentUser!.uid)
        .get();

    if (snapshot.exists) {
      newEmail = snapshot.get('email') ?? '';
      phone = snapshot.get('phoneNumber') ?? '';
      imageUrl = snapshot.get('profile') ?? '';
    }
    addressText = provider.getUsersAddress;
    addressController.text = provider.getShortFormAddress;
    latitude = provider.getLatitude.toString();
    longitude = provider.getLongitude.toString();

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationData>(context, listen: false)
          .fetchUserAddressAndLocation();
    });

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
    final subscriptionProvider =
        Provider.of<SubscriptionData>(context, listen: false);

    return Consumer<LocationData>(
      builder: (BuildContext context, LocationData value, Widget? child) {
        final address = value.getUsersAddress;
        final shortFormAddress = value.getShortFormAddress;
        addressController.text = shortFormAddress;
        final latitude = value.getLatitude;
        final longitude = value.getLongitude;
        final radiusFilter = value.getRadiusFilter;

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
                                                  CupertinoIcons
                                                      .person_alt_circle,
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
                                        onTap: () {
                                          onLocationChanged(
                                            address,
                                            radiusFilter,
                                            latitude.toString(),
                                            longitude.toString(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 40,
                            ),

                            (subscriptionProvider.isUserSubscribed)
                                ? alreadySubscribedProButton(context)
                                : buildTryProButton(context),
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
                                  showSnackBar(
                                      context, "Logged Out Successfully");
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
      },
    );
  }

  Widget buildTryProButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 55,
            width: Get.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange, width: 1.5),
              gradient: LinearGradient(
                colors: [
                  Colors.white54,
                  Colors.orangeAccent.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade100.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: RawMaterialButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const SubscriptionScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Try TruNri Pro',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Crown image floating above
          Positioned(
            top: -55,
            child: Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  'assets/icons/crown.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget alreadySubscribedProButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Container(
        height: 50,
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: BoxBorder.all(color: Colors.orange, width: 1.5),
          gradient: LinearGradient(
            colors: [
              Colors.white54,
              Colors.red.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 4),
              blurRadius: 10,
            )
          ],
        ),
        child: RawMaterialButton(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => const SubscriptionSuccessScreen(),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/icons/crown.png',
                height: 80,
                width: 80,
              ),
              Text(
                'You are a Pro TruNri',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onLocationChanged(
      String address, int radiusFilter, String lat, lng) async {
    Map<String, dynamic> selectedAddress = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurrentAddress(
          isProfileScreen: true,
          savedAddress: address,
          latitude: lat,
          longitude: lng,
          radiusFilter: radiusFilter,
        ),
      ),
    );

    final provider = Provider.of<LocationData>(context, listen: false);
    // ignore: unnecessary_null_comparison
    if (selectedAddress.isNotEmpty) {
      String lat = selectedAddress['latitude'];
      String lon = selectedAddress['longitude'];
      setState(() {
        final shortFormAddress =
            '📍 ${selectedAddress['city']}, ${provider.getStateShortForm(selectedAddress['state'])}';

        provider.setAllLocationData(
          lat: lat.toNum.toDouble(),
          long: lon.toNum.toDouble(),
          fullAddress: selectedAddress['address'],
          shortFormAddress: shortFormAddress,
          radiusFilter: selectedAddress['radiusFilter'],
          isLocationFetched: false,
        );
        addressController.text = shortFormAddress;
      });
    }
  }
}
