import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
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
  final Color orangeColor = Colors.deepOrange.shade400;

  Widget buildTile({
    required BuildContext context,
    required String title,
    required IconData iconData,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 80, // smaller height
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8), // less vertical margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            // offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: orangeColor.withValues(alpha: 0.2),
        child: Center(
          child: ListTile(
            minLeadingWidth: 60,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: CircleAvatar(
              radius: 24, // smaller radius
              backgroundColor: iconColor.withValues(alpha: 0.2),
              child: FaIcon(
                iconData,
                color: iconColor,
                size: 26, // smaller icon size
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16, // smaller font
                color: Colors.grey[900],
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: orangeColor.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocationData>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text(
            'Explore',
            style: TextStyle(
              color: Colors.black,
              fontSize: 27,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              buildTile(
                context: context,
                title: 'Restaurant',
                iconData: FontAwesomeIcons.utensils,
                iconColor: Colors.lime.shade600,
                onTap: () {
                  Get.to(
                    ResturentItemListScreen(
                      restaurant_List: provider.getRestaurauntList,
                    ),
                  );
                },
              ),
              buildTile(
                context: context,
                title: 'Grocery Stores',
                iconData: FontAwesomeIcons.cartShopping,
                iconColor: Colors.green,
                onTap: () {
                  Get.to(
                    GroceryStoreListScreen(
                      groceryStores: provider.getGroceryList,
                    ),
                  );
                },
              ),
              buildTile(
                context: context,
                title: 'Accommodation',
                iconData: FontAwesomeIcons.hotel,
                iconColor: Colors.blueAccent,
                onTap: () {
                  Get.to(const Accommodationoptionscreen());
                },
              ),
              buildTile(
                context: context,
                title: 'Jobs',
                iconData: FontAwesomeIcons.briefcase,
                iconColor: Colors.purpleAccent,
                onTap: () {
                  Get.to(const JobHomePageScreen());
                },
              ),
              buildTile(
                context: context,
                title: 'Temple',
                iconData: FontAwesomeIcons.placeOfWorship,
                iconColor: Colors.orangeAccent,
                onTap: () {
                  Get.to(
                    TempleHomePageScreen(
                      templesList: provider.getTemplesList,
                    ),
                  );
                },
              ),
              buildTile(
                context: context,
                title: 'Event',
                iconData: FontAwesomeIcons.calendar,
                iconColor: Colors.deepOrange,
                onTap: () {
                  Get.to(
                    EventDiscoveryScreen(
                      eventList: provider.getEventList,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
