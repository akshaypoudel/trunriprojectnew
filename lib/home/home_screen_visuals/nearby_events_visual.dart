import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:trunriproject/events/eventDetailsScreen.dart';
import 'package:trunriproject/events/eventHomeScreen.dart';
import 'package:trunriproject/home/section_title.dart';

class NearbyEventsVisual extends StatelessWidget {
  const NearbyEventsVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title: "Upcoming Events",
            press: () {
              Get.to(const EventDiscoveryScreen());
            },
          ),
        ),
        StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('MakeEvent').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No events available"));
            }
            var events = snapshot.data!.docs;
            return Container(
              height: 140,
              margin: const EdgeInsets.only(
                left: 20,
              ),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: CarouselSlider.builder(
                itemCount: events.length,
                itemBuilder: (context, index, realIndex) {
                  var event = events[index];
                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        EventDetailsScreen(
                          eventDate: event['eventDate'],
                          eventName: event['eventName'],
                          eventTime: event['eventTime'],
                          location: event['location'],
                          photo: event['photo'][0],
                          Price: event['ticketPrice'],
                        ),
                      );
                    },
                    child: Container(
                      width: 242,
                      margin: const EdgeInsets.only(
                        right: 10,
                      ),
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
            );
          },
        ),
      ],
    );
  }
}
