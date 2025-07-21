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
          title: TextField(
            controller: searchController,
            onChanged: (value) {
              final query = value.toLowerCase();
              setState(() {
                filteredStores = groceryStores.where((store) {
                  final name = store['name']?.toString().toLowerCase() ?? '';
                  return name.contains(query);
                }).toList();
              });
            },
            decoration: const InputDecoration(
              hintText: 'Search Grocery Store',
              hintStyle: TextStyle(color: Colors.black54),
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Grocery Stores Near You',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredStores.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 18,
                  childAspectRatio: 3 / 4.5,
                ),
                itemBuilder: (context, index) {
                  final store = filteredStores[index];
                  final name = store['name'] ?? 'Unknown';
                  final address = store['vicinity'] ?? 'No Address';
                  final rating = (store['rating'] as num?)?.toDouble() ?? 0.0;
                  final photoReference = store['photos'] != null
                      ? store['photos'][0]['photo_reference']
                      : null;
                  final photoUrl = photoReference != null
                      ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=${Constants.API_KEY}'
                      : 'https://via.placeholder.com/400';
                  final openingHours = store['opening_hours'] ?? {};

                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        ResturentDetailsScreen(
                          name: name,
                          rating: rating,
                          desc: 'No Description Available',
                          openingTime:
                              openingHours['opening'] ?? 'Not Available',
                          closingTime:
                              openingHours['closing'] ?? 'Not Available',
                          address: address,
                          image: photoUrl,
                        ),
                        arguments: [
                          store['geometry']['location']['lat'],
                          store['geometry']['location']['lng'],
                        ],
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toString(),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
