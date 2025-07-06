import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/home/resturentDetailsScreen.dart';

import 'bottom_bar.dart';

class FavoriteRestaurantsScreen extends StatefulWidget {
  const FavoriteRestaurantsScreen({super.key});

  @override
  _FavoriteRestaurantsScreenState createState() =>
      _FavoriteRestaurantsScreenState();
}

class _FavoriteRestaurantsScreenState extends State<FavoriteRestaurantsScreen> {
  Future<List<FavoriteRestaurant>> _fetchFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('favorite')
        .doc(userId)
        .collection('restaurants')
        .get();

    return snapshot.docs
        .map((doc) => FavoriteRestaurant.fromFirestore(doc))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Favorite Restaurants'),
        leading: GestureDetector(
            onTap: () {
              Get.off(const MyBottomNavBar());
            },
            child: const Icon(Icons.arrow_back_ios)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<FavoriteRestaurant>>(
          future: _fetchFavorites(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                color: Colors.orange,
              ));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text('No favorite restaurants found.'));
            }

            final favoriteRestaurants = snapshot.data!;

            return ListView.builder(
              itemCount: favoriteRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = favoriteRestaurants[index];
                final photoUrl = restaurant.image.isNotEmpty
                    ? restaurant.image
                    : 'https://via.placeholder.com/400'; // Path to your default image

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        margin:
                            const EdgeInsets.only(bottom: 8, left: 10, top: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xfff1cbe2),
                            borderRadius: BorderRadius.circular(5)),
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          height: 100,
                          width: Get.width,
                          fit: BoxFit.fill,
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                            color: Colors.orange,
                          )),
                          errorWidget: (context, url, error) {
                            return Image.network(
                                'https://via.placeholder.com/400'); // Path to your default image
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.to(
                            ResturentDetailsScreen(
                              name: restaurant.name,
                              desc: restaurant.desc,
                              rating: restaurant.rating,
                              openingTime: restaurant.opentime,
                              closingTime: restaurant.closetime,
                              address: restaurant.address,
                              image: restaurant.image,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Text(restaurant.address)
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class FavoriteRestaurant {
  final String name;
  final String address;
  final String image;
  final String desc;
  final double rating;
  final String opentime;
  final String closetime;

  FavoriteRestaurant({
    required this.name,
    required this.address,
    required this.image,
    required this.desc,
    required this.rating,
    required this.opentime,
    required this.closetime,
  });

  factory FavoriteRestaurant.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FavoriteRestaurant(
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      image: data['image'] ?? '',
      desc: data['desc'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      opentime: data['opentime'] ?? '',
      closetime: data['closetime'] ?? '',
    );
  }
}
