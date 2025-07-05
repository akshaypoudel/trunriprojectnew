import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/profile/profileScreen.dart';
import 'explorScreen.dart';
import 'favoriteRestaurantsScreen.dart';
import 'home_screen.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int myCurrentIndex = 0;
  List pages = [
    const HomeScreen(),
    const FavoriteRestaurantsScreen(),
    const ExplorScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: CrystalNavigationBar(
        currentIndex: myCurrentIndex,
        onTap: (index) {
          setState(() {
            myCurrentIndex = index;
          });
        },
        indicatorColor: Colors.orange,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.orange,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        outlineBorderColor: Colors.black.withValues(alpha: 0.3),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInExpo,
        splashColor: Colors.orange[100],
        // outlineBorderColor: Colors.white,
        borderWidth: 2,
        items: [
          CrystalNavigationBarItem(icon: Icons.home),
          CrystalNavigationBarItem(icon: Icons.favorite),
          CrystalNavigationBarItem(icon: Icons.explore),
          CrystalNavigationBarItem(icon: Icons.person_2_rounded),
        ],
      ),
      body: pages[myCurrentIndex],
    );
  }
}
