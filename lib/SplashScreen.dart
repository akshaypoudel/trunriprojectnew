import 'dart:async';
import 'dart:developer';

// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/signUpScreen.dart';
import 'package:trunriproject/signinscreen.dart';
import 'package:trunriproject/widgets/appTheme.dart';
import 'package:trunriproject/widgets/helper.dart';

import 'home/bottom_bar.dart';
import 'home/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isCheckingUserLoginData = true;
  final bool _hasConnection = true;
  final bool _isChecking = true;

  Future<void> checkLogin() async {
    await Future.delayed(const Duration(seconds: 2)); // short delay

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Safe geocoding with timeout + try/catch
        try {
          final position = await Geolocator.getCurrentPosition();
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 3));

          final country =
              placemarks.isNotEmpty ? placemarks.first.country : null;
          final provider = Provider.of<LocationData>(context, listen: false);
          provider.setUserCountry(country ?? '');
        } catch (e) {
          debugPrint("Geocoding failed: $e");
          // fallback if reverse geocode fails
          final provider = Provider.of<LocationData>(context, listen: false);
          provider.setUserCountry('');
        }
      } else {
        showSnackBar(context, 'Location Permission Not Given.');
      }
    } catch (e) {
      log('Error in page');
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      bool userExists = await FirebaseFireStoreService().checkUserProfile();

      if (userExists) {
        Get.offAll(() => const MyBottomNavBar());
      } else {
        Get.offAll(() => const SignInScreen());
      }
    } else {
      setState(() {
        isCheckingUserLoginData = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // _checkConnection();
    if (!_hasConnection) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLogin();
    });
  }

  // Future<void> _checkConnection() async {
  //   setState(() {
  //     _isChecking = true;
  //   });
  //   // First check if device is connected to Wi-Fi or Mobile data
  //   // var connectivityResult = await Connectivity().checkConnectivity();
  //   // if (connectivityResult.contains(ConnectivityResult.none)) {
  //   //   setState(() {
  //   //     _hasConnection = false;
  //   //     _isChecking = false;
  //   //   });
  //   //   return;
  //   // }
  //   // Double-check with a ping (actual internet access)
  //   try {
  //     final result =
  //         await http.get(Uri.parse("https://www.google.com")).timeout(
  //               const Duration(seconds: 5),
  //             );
  //     setState(() {
  //       _hasConnection = result.statusCode == 200;
  //       _isChecking = false;
  //     });
  //   } catch (_) {
  //     setState(() {
  //       _hasConnection = false;
  //       _isChecking = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (isCheckingUserLoginData) {
      return const Scaffold(
        body: Center(
          child: Text(
            'TruNri',
            style: TextStyle(
              fontSize: 100,
              color: AppTheme.blackColor,
              fontFamily: 'Caveat',
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        color: Colors.white,
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: size.height * 0.53,
                width: size.width,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  color: Color(0xffFF730A),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(
                      "assets/images/taj.png",
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.6,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      "Namaste! Unite, Flourish\nTogether, Celebrate!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Color(0xff353047),
                          height: 1.2),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Welcome to our community app! Together\nlet's make connections that matter.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xff6F6B7A),
                      ),
                    ),
                    SizedBox(height: size.height * 0.07),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      child: Container(
                        height: size.height * 0.08,
                        width: size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: const Color(0xffD1B57D),
                          border: Border.all(
                            color: Colors.white,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withValues(alpha: 0.05),
                              spreadRadius: 1,
                              blurRadius: 7,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const SignUpScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.ease;
                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        var offsetAnimation =
                                            animation.drive(tween);
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  height: size.height * 0.08,
                                  width: size.width / 2.2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff253242),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Register",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Color(0xffFFFAFA),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const SignInScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.ease;
                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        var offsetAnimation =
                                            animation.drive(tween);
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xffFFFAFA),
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
