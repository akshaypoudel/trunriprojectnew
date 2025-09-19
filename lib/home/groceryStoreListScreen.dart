import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/resturentDetailsScreen.dart';

class GroceryStoreListScreen extends StatelessWidget {
  final List<dynamic> groceryStores;

  const GroceryStoreListScreen({super.key, required this.groceryStores});

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    List<dynamic> filteredStores = List.from(groceryStores);

    return StatefulBuilder(
      builder: (context, setState) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Grocery Stores Near You',
            style: TextStyle(
                fontSize: 21,
                // fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),
        body: SafeArea(
          child: ListView(
            children: [
              //Searchbar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.deepOrangeAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(
                          Icons.search,
                          color: Colors.deepOrangeAccent,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search Grocery Stores',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 17,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                          onChanged: (query) {
                            setState(() {
                              filteredStores =
                                  groceryStores.where((restaurant) {
                                final name = restaurant['name']
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';
                                return name.contains(query.toLowerCase());
                              }).toList();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              (filteredStores.isEmpty)
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          '😕 No Grocery Stores found.',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredStores.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 18,
                        childAspectRatio: 3 / 5.4,
                      ),
                      itemBuilder: (context, index) {
                        final store = filteredStores[index];
                        final name = store['name'] ?? 'Unknown';
                        final address = store['vicinity'] ?? 'No Address';
                        final rating =
                            (store['rating'] as num?)?.toDouble() ?? 0.0;
                        final photoReference = store['photos'] != null
                            ? store['photos'][0]['photo_reference']
                            : null;
                        final photoUrl = photoReference != null
                            ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=${Constants.API_KEY}'
                            : Constants.PLACEHOLDER_IMAGE;
                        final openingHours = store['opening_hours'] ?? {};

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.1),
                                blurRadius: 6,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.deepOrange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Get.to(
                                    ResturentDetailsScreen(
                                      name: name,
                                      rating: rating,
                                      desc: 'No Description Available',
                                      openingTime: openingHours['opening'] ??
                                          'Not Available',
                                      closingTime: openingHours['closing'] ??
                                          'Not Available',
                                      address: address,
                                      image: photoUrl,
                                      isOpenNow: openingHours['open_now'],
                                    ),
                                    arguments: [
                                      store['geometry']['location']['lat'],
                                      store['geometry']['location']['lng'],
                                    ],
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      // color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.deepOrange,
                                          Colors.orange.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Text(
                                      'View Details',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
