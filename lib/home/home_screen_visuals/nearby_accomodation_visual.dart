import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/accomodationDetailsScreen.dart';
import 'package:trunriproject/accommodation/lookingForAPlaceScreen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/section_title.dart';

class NearbyAccomodationVisual extends StatelessWidget {
  const NearbyAccomodationVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('accommodation').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orange));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No accommodations available"));
        }

        List<Map<String, dynamic>> accommodationList = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<LocationData>(context, listen: false)
              .setAccomodationList(accommodationList);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(
                title: "Near By Accommodations",
                press: () {
                  Get.to(() => LookingForAPlaceScreen(
                        accommodationList: accommodationList,
                      ));
                },
              ),
            ),
            const SizedBox(height: 8),

            // Carousel Slider
            Container(
              height: 160,
              margin: const EdgeInsets.only(left: 20),
              child: CarouselSlider.builder(
                itemCount: accommodationList.length,
                itemBuilder: (context, index, realIndex) {
                  final data = accommodationList[index];
                  final List<dynamic> images = data['images'] ?? [];
                  final String imageUrl =
                      images.isNotEmpty ? images.first.toString() : "";

                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        () => AccommodationDetailsScreen(
                          accommodation: accommodationList[index],
                        ),
                      );
                    },
                    child: Container(
                      width: 242,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child:
                                        const Center(child: Text("No Image")),
                                  ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black54,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['city'] ?? 'No City',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      data['state'] ?? 'No State',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 160,
                  viewportFraction: 0.55,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayCurve: Curves.easeInOut,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
