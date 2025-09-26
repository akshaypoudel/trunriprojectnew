import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/favourites/favourite_model.dart';
import 'package:trunriproject/home/groceryStoreListScreen.dart';
import 'package:trunriproject/home/resturentDetailsScreen.dart';
import 'package:trunriproject/home/section_title.dart';

class NearbyGroceryStoresVisual extends StatelessWidget {
  const NearbyGroceryStoresVisual(
      {super.key, required this.groceryStores, required this.isInAustralia});
  final List<dynamic> groceryStores;
  final bool isInAustralia;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title:
                (isInAustralia) ? "Near By Grocery Stores" : "Grocery Stores",
            press: () {
              Get.to(GroceryStoreListScreen(groceryStores: groceryStores));
            },
          ),
        ),
        Container(
          height: (isInAustralia)
              ? height * .32
              : (groceryStores.isEmpty)
                  ? height * .26
                  : height * .32,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
          child: (groceryStores.isEmpty)
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
                            Icons.local_grocery_store,
                            size: 48,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (isInAustralia)
                                ? 'No Grocery Stores Nearby'
                                : 'No Grocery Stores Found',
                            textAlign: TextAlign.center,
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
                                : 'Select a different suburb in Australia to find Grocery Stores',
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
                  itemCount: groceryStores.length,
                  itemBuilder: (context, index) {
                    final groceryStore = groceryStores[index];
                    final name = groceryStore['name'];
                    final address = groceryStore['vicinity'];
                    final rating =
                        (groceryStore['rating'] as num?)?.toDouble() ?? 0.0;
                    final description = groceryStore['description'] ??
                        'No Description Available';
                    final openingHours = groceryStore['opening_hours'] != null
                        ? groceryStore['opening_hours']['weekday_text']
                        : 'Not Available';
                    final closingTime =
                        groceryStore['closing_time'] ?? 'Not Available';
                    // final photoReference = groceryStore['photos'] != null
                    //     ? groceryStore['photos'][0]['photo_reference']
                    //     : null;
                    final photos = groceryStore['photos'] as List?;
                    final photoReference = (photos != null && photos.isNotEmpty)
                        ? photos.first['photo_reference']
                        : null;
                    final photoUrl = photoReference != null
                        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=${Constants.API_KEY}'
                        : null;

                    if (photoUrl == null ||
                        photoReference == null ||
                        name == null) {
                      return const SizedBox.shrink();
                    }
                    final lat = groceryStore['geometry']['location']['lat'];
                    final lng = groceryStore['geometry']['location']['lng'];

                    return GestureDetector(
                      onTap: () {
                        Get.to(
                            ResturentDetailsScreen(
                              name: name.toString(),
                              type: FavouriteType.grocery,
                              rating: rating,
                              desc: description.toString(),
                              openingTime: openingHours.toString(),
                              closingTime: closingTime.toString(),
                              address: address.toString(),
                              image: photoUrl.toString(),
                              isOpenNow: groceryStore['opening_hours']
                                  ['open_now'],
                            ),
                            arguments: [lat, lng]);
                      },
                      child: Container(
                        height: 200,
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
                                  fontSize: 15,
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
                                  fontSize: 15,
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
        )
      ],
    );
  }
}
