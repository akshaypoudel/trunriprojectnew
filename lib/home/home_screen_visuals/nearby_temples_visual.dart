import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/resturentDetailsScreen.dart';

class NearbyTemplesVisual extends StatelessWidget {
  const NearbyTemplesVisual({super.key, required this.templesList});
  final List<dynamic> templesList;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return Container(
      height: height * .32,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
      child: ListView.builder(
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

          if (photoUrl == null || photoReference == null || name == null) {
            return const SizedBox.shrink();
          }

          final lat = temples['geometry']['location']['lat'];
          final lng = temples['geometry']['location']['lng'];

          // final resturentLat = lat.toString();
          // final resturentlong = lng.toString();

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
                ),
                arguments: [lat, lng],
              );
            },
            child: Container(
              height: 180,
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(11)),
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
                  const SizedBox(
                      height: 10), // Add space between the image and the text
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      name,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Adjust the font size as needed
                      ),
                      // overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Allow text to wrap to 2 lines if needed
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
                        fontSize: 14, // Adjust the font size as needed
                      ),
                      // overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Allow text to wrap to 2 lines if needed
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
