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
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('MakeEvent').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No events available"));
        }

        List<Map<String, dynamic>> eventList = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<LocationData>(context, listen: false)
              .setEventList(eventList);
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(
                title: "Upcoming Events",
                press: () {
                  Get.to(() => EventDiscoveryScreen(eventList: eventList));
                },
              ),
            ),
            Container(
              height: 140,
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
                      Get.to(EventDetailsScreen(
                        eventDate: event['eventDate'],
                        eventName: event['eventName'],
                        eventTime: event['eventTime'],
                        location: event['location'],
                        photoUrl: event['photo'],
                        price: event['ticketPrice'],
                        description: event['description'],
                        category: event['category'][0],
                        eventType: event['eventType'][0],
                        contactInfo: event['contactInformation'],
                      ));
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
                  viewportFraction: 0.55,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayCurve: Curves.easeInOutCirc,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
