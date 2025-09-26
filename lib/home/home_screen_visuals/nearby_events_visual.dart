import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/events/eventDetailsScreen.dart';
import 'package:trunriproject/events/eventHomeScreen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/section_title.dart';

class NearbyEventsVisual extends StatelessWidget {
  const NearbyEventsVisual({super.key, required this.isInAustralia});
  final bool isInAustralia;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Always visible heading
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title: "Upcoming Events",
            press: () {
              final events = Provider.of<LocationData>(context, listen: false)
                  .getEventList;
              Get.to(() => EventDiscoveryScreen(eventList: events));
            },
          ),
        ),
        // Event data visual
        StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('MakeEvent').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<Map<String, dynamic>> eventList = [];

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              eventList = snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((item) => item['status'] == 'approved')
                  .toList();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<LocationData>(context, listen: false)
                    .setEventList(eventList);
              });
            }

            if (eventList.isEmpty) {
              return SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Container(
                      width: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 100),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepOrange.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month_sharp,
                            size: 48,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              (isInAustralia)
                                  ? 'No Events Nearby'
                                  : 'No Events Found',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isInAustralia
                                ? 'Try expanding your radius or check another suburb'
                                : 'Select a different suburb in Australia to find Events',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              height: 170,
              margin: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CarouselSlider.builder(
                itemCount: eventList.length,
                itemBuilder: (context, index, realIndex) {
                  final event = eventList[index];
                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        EventDetailsScreen(
                          eventData: event,
                          nearbyEvents: eventList,
                        ),
                      );
                    },
                    child: Container(
                      width: 242,
                      margin: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: event['photo'].isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: event['photo'][0],
                                height: 180,
                                width: 200,
                                fit: BoxFit.cover,
                              )
                            : Image.asset("assets/images/singing.jpeg",
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 450,
                  viewportFraction: 0.65,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayCurve: Curves.easeInOutCirc,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
