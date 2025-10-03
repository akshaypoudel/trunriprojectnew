import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 5),
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
                      width: 260,
                      height: 250,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        border: BoxBorder.all(
                          width: 1,
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.8),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top half - image with overlay
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: event['photo'].isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: event['photo'][0],
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        "assets/images/singing.jpeg",
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              // Gradient overlay for text/icon clarity
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              // Top content (icon, event type, name)
                              const Positioned(
                                left: 16,
                                top: 12,
                                child: Icon(Icons.music_note,
                                    color: Colors.white, size: 26),
                              ),
                              Positioned(
                                right: 18,
                                top: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    event['category'][0] ?? 'Music',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    event['eventName'] ?? "Event Name",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Bottom half - content
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatEventDateTime(
                                        event['eventDate'],
                                        event['eventTime'],
                                      ),
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        event['location'] ?? 'Event Location',
                                        maxLines: 2,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "\$${event['ticketPrice'] ?? 'Free'}",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${event['interested'] ?? '0'} interested",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 850,
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

  String formatEventDateTime(String rawDateStr, String timeStr) {
    try {
      // Strip day prefix (e.g. "Sat ")
      String dateStr = rawDateStr.split(' ').length > 1
          ? rawDateStr.split(' ')[1]
          : rawDateStr;

      DateTime date = DateTime.parse(dateStr); // expects 'yyyy-MM-dd'
      DateFormat dateFormat = DateFormat('MMM dd, yyyy'); // Dec 15, 2024 format
      DateFormat timeFormat = DateFormat.jm(); // 6:00 PM format

      // Assuming eventTime is 'HH:mm' 24hr format as before
      DateTime time = DateFormat('HH:mm').parse(timeStr);

      String formattedDate = dateFormat.format(date);
      String formattedTime = timeFormat.format(time);

      return '$formattedDate - $formattedTime';
    } catch (e) {
      return '$rawDateStr - $timeStr'; // fallback
    }
  }
}
