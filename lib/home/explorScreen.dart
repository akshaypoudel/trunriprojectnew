import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
import 'package:trunriproject/home/search_field.dart';
import 'package:trunriproject/job/jobHomePageScreen.dart';

import '../accommodation/accommodationOptionScreen.dart';
import '../events/eventHomeScreen.dart';
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
    final provider = Provider.of<LocationData>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Colors.white,
      ),
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              top: 10,
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
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          Get.to(
                            ResturentItemListScreen(
                              restaurant_List: Provider.of<LocationData>(
                                      context,
                                      listen: false)
                                  .getRestaurauntList,
                            ),
                          );
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
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          Get.to(
                            GroceryStoreListScreen(
                              groceryStores: provider.getGroceryList,
                            ),
                          );
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
                            color: Colors.black.withValues(alpha: 0.1),
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
                            color: Colors.black.withValues(alpha: 0.1),
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
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          Get.to(
                            TempleHomePageScreen(
                              templesList: provider.getTemplesList,
                            ),
                          );
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
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          Get.to(
                            EventDiscoveryScreen(
                              eventList: provider.getEventList,
                            ),
                          );
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
          ],
        ),
      ),
    );
  }
}
