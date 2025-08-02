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
  const NearbyAccomodationVisual({super.key, required this.isInAustralia});
  final bool isInAustralia;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('accommodation').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        List<Map<String, dynamic>> accommodationList = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          accommodationList = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<LocationData>(context, listen: false)
                .setAccomodationList(accommodationList);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Heading - Always Visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(
                title: (isInAustralia)
                    ? "Nearby Accommodations"
                    : "Accommodations",
                press: () {
                  Get.to(() => LookingForAPlaceScreen(
                        accommodationList: accommodationList,
                      ));
                },
              ),
            ),
            const SizedBox(height: 8),

            // Show either carousel or not-found visual
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
            else if (accommodationList.isEmpty)
              SizedBox(
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
                            Icons.house_sharp,
                            size: 48,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              (isInAustralia)
                                  ? 'No Accomodations Nearby'
                                  : 'No Accomodations Found',
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
                                : 'Select a different suburb in Australia to find Accomodations',
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
              )
            else
              Container(
                height: 200,
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
                        width: 300,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['city'] ?? 'No City',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        data['state'] ?? 'No State',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                        ),
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
                    height: 350,
                    viewportFraction: 0.7,
                    aspectRatio: 16 / 9,
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
