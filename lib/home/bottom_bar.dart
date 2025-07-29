import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/screens/chat_list_screen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/profile/profileScreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'explorScreen.dart';
import 'home_screen.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key, this.index});
  final int? index;

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int myCurrentIndex = 0;
  List<Widget> pages = [
    const HomeScreen(),
    const ExplorScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      myCurrentIndex = 2;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeProvider();
    });
    checkAndUpdateSubscription();
  }

  void checkAndUpdateSubscription() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('User').doc(uid);
    final snapshot = await userRef.get();

    if (snapshot.exists && snapshot.data()!.containsKey('subscriptionExpiry')) {
      final Timestamp end = snapshot['subscriptionExpiry'];
      final isExpired = end.toDate().isBefore(DateTime.now());

      await userRef.update({
        'isSubscribed': !isExpired,
      });
    }
  }

  Future<void> initializeProvider() async {
    await Provider.of<SubscriptionData>(
      context,
      listen: false,
    ).fetchSubscriptionStatus();

    Provider.of<LocationData>(context, listen: false)
        .setUserInAustralia(await _handleLocationSource());

    bool isUserInAustralia =
        Provider.of<LocationData>(context, listen: false).isUserInAustralia;

    await Provider.of<LocationData>(
      context,
      listen: false,
    ).fetchUserAddressAndLocation(
      isInAustralia: isUserInAustralia,
    );
  }

  Future<bool> _handleLocationPermission() async {
    // radiusFilter = widget.radiusFilter;
    bool isServiceEnabled;
    LocationPermission permission;

    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      showSnackBar(context, 'Location Service Not Enabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showSnackBar(context, 'Location Permission Not Given.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showSnackBar(
        context,
        'Location Permission is Denied Forever. Can\'t Access Location',
      );
    }
    return true;
  }

  Future<bool> _handleLocationSource() async {
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      log('no permissionlllllllllllllllllllll');
      return false;
    }
    final position = await Geolocator.getCurrentPosition();
    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    final country = placemarks.first.country;

    if (country == "Australia") {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(
        index: myCurrentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.blueGrey,
        currentIndex: myCurrentIndex,
        onTap: (index) {
          setState(() {
            myCurrentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(
              Icons.home,
              size: 30,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
            activeIcon: Icon(
              Icons.explore,
              size: 30,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(
              Icons.message_rounded,
              size: 30,
            ),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_3_outlined),
            activeIcon: Icon(
              Icons.person_3,
              size: 30,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
