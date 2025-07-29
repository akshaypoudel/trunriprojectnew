import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/resturentDetailsScreen.dart';

class NearbyTemplesVisual extends StatelessWidget {
  const NearbyTemplesVisual(
      {super.key, required this.templesList, required this.isInAustralia});
  final List<dynamic> templesList;
  final bool isInAustralia;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return Container(
      height: (isInAustralia)
          ? height * .32
          : (templesList.isEmpty)
              ? height * .26
              : height * .32,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
      child: (templesList.isEmpty)
          ? ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 100),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.temple_buddhist,
                        size: 48,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (isInAustralia)
                            ? 'No Temples Nearby'
                            : 'No Temples Found',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isInAustralia
                            ? 'Try expanding your radius or check another suburb'
                            : 'Select a different suburb in Australia to find Indian temples',
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
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templesList.length,
              itemBuilder: (context, index) {
                final temples = templesList[index];
                final name = temples['name'];
                final address = temples['vicinity'];
                final rating = (temples['rating'] as num?)?.toDouble() ?? 0.0;
                final reviews = temples['reviews'];
                final description =
                    temples['description'] ?? 'No Description Available';
                final openingHours = temples['opening_hours'] != null
                    ? temples['opening_hours']['weekday_text']
                    : 'Not Available';
                final closingTime = temples['closing_time'] ?? 'Not Available';
                final photoReference = temples['photos'] != null
                    ? temples['photos'][0]['photo_reference']
                    : temples['photos'][1]['photo_reference'];
                final photoUrl = photoReference != null
                    ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=35000&photoreference=$photoReference&key=${Constants.API_KEY}'
                    : null;

                if (photoUrl == null ||
                    photoReference == null ||
                    name == null) {
                  return const SizedBox.shrink();
                }

                final lat = temples['geometry']['location']['lat'];
                final lng = temples['geometry']['location']['lng'];

                return GestureDetector(
                  onTap: () {
                    Get.to(
                      ResturentDetailsScreen(
                        name: name.toString(),
                        rating: rating,
                        desc: description.toString(),
                        openingTime: openingHours.toString(),
                        closingTime: closingTime.toString(),
                        address: address.toString(),
                        image: photoUrl.toString(),
                        isOpenNow: openingHours['open_now'],
                      ),
                      arguments: [lat, lng],
                    );
                  },
                  child: Container(
                    height: 180,
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: photoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  height: 180,
                                  width: 200,
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            name,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            address,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w300,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
