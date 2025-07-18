import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/groceryStoreListScreen.dart';
import 'package:trunriproject/home/resturentDetailsScreen.dart';
import 'package:trunriproject/home/section_title.dart';

class NearbyGroceryStoresVisual extends StatelessWidget {
  const NearbyGroceryStoresVisual({super.key, required this.groceryStores});
  final List<dynamic> groceryStores;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title: "Near By Grocery Stores",
            press: () {
              Get.to(const GroceryStoreListScreen());
            },
          ),
        ),
        Container(
          height: height * .32,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: groceryStores.length,
            itemBuilder: (context, index) {
              final groceryStore = groceryStores[index];
              final name = groceryStore['name'];
              final address = groceryStore['vicinity'];
              final rating =
                  (groceryStore['rating'] as num?)?.toDouble() ?? 0.0;
              final description =
                  groceryStore['description'] ?? 'No Description Available';
              final openingHours = groceryStore['opening_hours'] != null
                  ? groceryStore['opening_hours']['weekday_text']
                  : 'Not Available';
              final closingTime =
                  groceryStore['closing_time'] ?? 'Not Available';
              final photoReference = groceryStore['photos'] != null
                  ? groceryStore['photos'][0]['photo_reference']
                  : null;
              final photoUrl = photoReference != null
                  ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=${Constants.API_KEY}'
                  : null;

              if (photoUrl == null || photoReference == null || name == null) {
                return const SizedBox.shrink();
              }
              final lat = groceryStore['geometry']['location']['lat'];
              final lng = groceryStore['geometry']['location']['lng'];

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
                      arguments: [lat, lng]);
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
                      const SizedBox(
                          height:
                              10), // Add space between the image and the text
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
                          maxLines:
                              1, // Allow text to wrap to 2 lines if needed
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
                          maxLines:
                              1, // Allow text to wrap to 2 lines if needed
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
