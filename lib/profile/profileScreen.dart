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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trunriproject/chat_module/community/components/chat_provider.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/signinscreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';
import 'package:trunriproject/subscription/subscription_success_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';
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

  final formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String imageUrl = '';

  updateProfile() async {
    if (!formKey.currentState!.validate()) {
      showSnackBar(context, "Returning From Method");
      return;
    }

    try {
      await fireStoreService.updateProfile(
        address: '',
        allowChange: userImageFile.path.isEmpty ? false : true,
        context: context,
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
      if (userImageFile != File("")) {
        await fireStoreService.updateProfilePictureForCommunity(userImageFile);
      }
    } catch (e) {
      showSnackBar(context, "Error updating profile");
      // log('updaitn profile error==========  $e');
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

    if (snapshot.exists) {
      newEmail = snapshot.get('email') ?? '';
      phone = snapshot.get('phoneNumber') ?? '';
      imageUrl = snapshot.get('profile') ?? '';
      // userImageUrl = imageUrl;
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

    initialize();
  }

  void initialize() async {
    await fetchUserData();
    setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationData>(
      builder: (BuildContext context, LocationData value, Widget? child) {
        return Scaffold(
          backgroundColor: Colors.white,
          extendBody: true,
          appBar: _buildAppBar(),
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
                                        readOnly: true,
                                        controller: emailController,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                            color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            _buildSubscriptionSection(),
                            const SizedBox(height: 45),
                            _buildMenuSection(),
                            const SizedBox(height: 95),
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

  Widget _buildSubscriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Consumer<SubscriptionData>(
        builder: (context, subscriptionProvider, _) {
          return subscriptionProvider.isUserSubscribed
              ? _buildProUserCard()
              : _buildTryProCard();
        },
      ),
    );
  }

  Widget _buildTryProCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.orange.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icons/crown.png',
              height: 40,
              width: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock TruNri Pro',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get premium features and enhanced experience',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Try Pro Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProUserCard() {
    return GestureDetector(
      onTap: () {
        Get.to(() => const SubscriptionSuccessScreen());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange, Colors.orange.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/crown.png',
                height: 32,
                width: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TruNri Pro Member',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                  Text(
                    'Enjoying premium features',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.verified,
              color: Colors.green.shade500,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    PresenceService.setUserOffline();
    GoogleSignIn().signOut();
    FirebaseAuth.instance.signOut().then((value) {
      Get.offAll(const SignInScreen());
      showSnackBar(
        context,
        "Logged Out Successfully",
      );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasShownLocationDialog');
  }

  Widget _buildMenuSection() {
    final menuItems = [
      MenuItemData(
        title: 'Address',
        icon: Icons.location_on_outlined,
        onTap: () => Get.to(const AddressListScreen()),
      ),
      MenuItemData(
        title: 'Feedback',
        icon: Icons.feedback_outlined,
        onTap: () {},
      ),
      MenuItemData(
        title: 'Share App',
        icon: Icons.share_outlined,
        onTap: () => Share.share('https://www.google.co.in/'),
      ),
      MenuItemData(
        title: 'Contact Us',
        icon: Icons.phone_outlined,
        onTap: () => launchUrlString("tel://+917665096245"),
      ),
      MenuItemData(
        title: 'Log Out',
        icon: Icons.logout_outlined,
        onTap: _handleLogout,
        isDestructive: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;

          return Column(
            children: [
              _buildMenuItem(item),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 1,
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  dynamic _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                if (isEditing) {
                  updateProfile();
                }
                setState(() {
                  isEditing = !isEditing;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isEditing ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isEditing ? Colors.green : Colors.deepOrange,
                    width: 1,
                  ),
                ),
                child: isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'Save',
                            style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.edit_outlined,
                        color: Colors.deepOrange,
                        size: 20,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItemData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isDestructive
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: item.isDestructive
                      ? Colors.red.shade500
                      : Colors.deepOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: item.isDestructive
                        ? Colors.red.shade600
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItemData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  MenuItemData({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}
