import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/screens/chat_list_screen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/profile/profileScreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'explorScreen.dart';
import 'home_screen.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key, this.index, this.indexForChat});
  final int? index;
  final int? indexForChat;

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int myCurrentIndex = 0;
  int? chatTabIndex;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    if (widget.index != null && widget.indexForChat != null) {
      myCurrentIndex = 2;
      chatTabIndex = 0;
    } else if (widget.index != null) {
      myCurrentIndex = 2;
    }

    // Initialize pages list with conditional ChatListScreen
    _initializePages();

    if (widget.index != null) {
      myCurrentIndex = 2;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeProvider();
    });
    checkAndUpdateSubscription();
  }

  void _initializePages() {
    pages = [
      const HomeScreen(),
      const ExplorScreen(),
      // Pass the chat tab index if both conditions are met
      chatTabIndex != null
          ? ChatListScreen(index: chatTabIndex!)
          : const ChatListScreen(),
      const ProfileScreen(),
    ];
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
      // extendBody: true,
      body: SafeArea(
        child: IndexedStack(
          index: myCurrentIndex,
          children: pages,
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => myCurrentIndex = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 17),
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 2),
                      decoration: BoxDecoration(
                        color: myCurrentIndex == i
                            ? Colors.orange.withValues(alpha: 0.11)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            [
                              OctIcons.home,
                              FontAwesome.compass,
                              FontAwesome.comment,
                              OctIcons.person,
                            ][i],
                            size: 22,
                            color: myCurrentIndex == i
                                ? Colors.orange
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ["Home", "Explore", "Chat", "Account"][i],
                            style: TextStyle(
                              color: myCurrentIndex == i
                                  ? Colors.orange
                                  : Colors.grey[700],
                              fontWeight: myCurrentIndex == i
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
