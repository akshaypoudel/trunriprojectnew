import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
import 'package:trunriproject/job/jobHomePageScreen.dart';

import '../accommodation/accommodationHomeScreen.dart';
import '../accommodation/accommodationOptionScreen.dart';
import '../events/eventHomeScreen.dart';
import '../events/event_list_screen.dart';
import '../temple/templeHomePageScreen.dart';
import 'groceryStoreListScreen.dart';

class ExplorScreen extends StatefulWidget {
  const ExplorScreen({super.key});

  @override
  State<ExplorScreen> createState() => _ExplorScreenState();
}

class _ExplorScreenState extends State<ExplorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Discover Items'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    Get.to(const ResturentItemListScreen());
                  },
                  leading: Image.asset(
                    'assets/icons/rasturent.png',
                  ),
                  title: const Text('Restaurant'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 15,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    Get.to(const GroceryStoreListScreen());
                  },
                  leading: Image.asset('assets/icons/grocery.png'),
                  title: const Text('Grocery Stores'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 15,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Image.asset('assets/icons/accommodation.png'),
                  title: const Text('Accommodation'),
                  onTap: () {
                    Get.to(const Accommodationoptionscreen());
                  },
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 15,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    Get.to(const JobHomePageScreen());
                  },
                  leading: Image.asset('assets/icons/jobs.png'),
                  title: const Text('Jobs'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 15,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    Get.to(const TempleHomePageScreen());
                  },
                  leading: Image.asset('assets/icons/templs.png'),
                  title: const Text('Temple'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 15,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    Get.to(EventDiscoveryScreen());
                  },
                  leading: Image.asset('assets/icons/events.png'),
                  title: const Text('Event'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 15,
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
