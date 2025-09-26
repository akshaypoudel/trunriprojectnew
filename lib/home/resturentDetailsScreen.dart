import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trunriproject/home/favourites/favourite_model.dart';
import 'package:trunriproject/home/favourites/favourite_provider.dart';
import 'package:trunriproject/widgets/appTheme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Controller.dart';

class ResturentDetailsScreen extends StatefulWidget {
  final String name;
  final double rating;
  final String desc;
  final String openingTime;
  final String closingTime;
  final String address;
  final String image;
  final bool isOpenNow;
  final FavouriteType type; // Add this to specify restaurant/grocery/temple

  const ResturentDetailsScreen({
    super.key,
    required this.name,
    required this.desc,
    required this.rating,
    required this.openingTime,
    required this.closingTime,
    required this.address,
    required this.image,
    required this.isOpenNow,
    required this.type, // Add this parameter
  });

  @override
  State<ResturentDetailsScreen> createState() => _ResturentDetailsScreenState();
}

class _ResturentDetailsScreenState extends State<ResturentDetailsScreen> {
  final serviceController = Get.put(ServiceController());
  double resturentLat = 0.0;
  double resturentlong = 0.0;

  Future<void> _launchMap(double lat, double lng) async {
    final currentLat = serviceController.currentlat;
    final currentLng = serviceController.currentlong;

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$currentLat,$currentLng&destination=$lat,$lng&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Generate unique ID for the item based on name and address
  String get itemId =>
      '${widget.name}_${widget.address}'.replaceAll(' ', '_').toLowerCase();

  @override
  void initState() {
    super.initState();
    if (Get.arguments != null) {
      resturentLat = Get.arguments[0];
      resturentlong = Get.arguments[1];
    }
  }

  Future<File> _downloadImage(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/temp_image.jpg';
    await Dio().download(url, filePath);
    return File(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.mainColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.mainColor),
            onPressed: () async {
              try {
                final file = await _downloadImage(widget.image);
                await Share.shareXFiles([
                  XFile(file.path),
                ], text: '${widget.name}\nAddress: ${widget.address}');
              } catch (e) {
                log('Error sharing image: $e');
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        widget.image,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 20,
                      child: Consumer<FavouritesProvider>(
                        builder: (context, favProvider, child) {
                          final isFavorite =
                              favProvider.isFavouriteLocal(itemId, widget.type);

                          return GestureDetector(
                            onTap: () async {
                              if (!isFavorite) {
                                // Create FavouriteItem with all the data
                                final favouriteItem = FavouriteItem(
                                  id: itemId,
                                  name: widget.name,
                                  location: widget.address,
                                  type: widget.type,
                                  addedAt: DateTime.now(),
                                  imageUrl: widget.image,
                                  extraData: {
                                    'rating': widget.rating,
                                    'description': widget.desc,
                                    'openingTime': widget.openingTime,
                                    'closingTime': widget.closingTime,
                                    'isOpenNow': widget.isOpenNow,
                                    'address': widget.address,
                                    'image': widget.image,
                                    'latitude': resturentLat,
                                    'longitude': resturentlong,
                                  },
                                );

                                final success = await favProvider
                                    .addToFavouritesWithData(favouriteItem);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.favorite,
                                              color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Added to favorites!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                final success = await favProvider
                                    .removeFromFavourites(itemId, widget.type);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.heart_broken,
                                              color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Removed from favorites!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.buttonColor,
                              ),
                            ),
                          ),
                          Consumer<FavouritesProvider>(
                            builder: (context, favProvider, child) {
                              final isFavorite = favProvider.isFavouriteLocal(
                                  itemId, widget.type);
                              return IconButton(
                                onPressed: () async {
                                  if (!isFavorite) {
                                    final favouriteItem = FavouriteItem(
                                      id: itemId,
                                      name: widget.name,
                                      location: widget.address,
                                      type: widget.type,
                                      addedAt: DateTime.now(),
                                      imageUrl: widget.image,
                                      extraData: {
                                        'rating': widget.rating,
                                        'description': widget.desc,
                                        'openingTime': widget.openingTime,
                                        'closingTime': widget.closingTime,
                                        'isOpenNow': widget.isOpenNow,
                                        'address': widget.address,
                                        'image': widget.image,
                                        'latitude': resturentLat,
                                        'longitude': resturentlong,
                                      },
                                    );
                                    await favProvider
                                        .addToFavouritesWithData(favouriteItem);
                                  } else {
                                    await favProvider.removeFromFavourites(
                                        itemId, widget.type);
                                  }
                                },
                                icon: Icon(
                                  isFavorite
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: AppTheme.mainColor,
                                  size: 30,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      (widget.isOpenNow)
                          ? const Chip(
                              side: BorderSide(color: Colors.green),
                              backgroundColor: Colors.green,
                              label: Text(
                                'Open Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const Chip(
                              side: BorderSide(color: Colors.red),
                              backgroundColor: Colors.red,
                              label: Text(
                                'Closed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      const SizedBox(height: 12),
                      _infoRow('assets/images/address.png', 'Address',
                          widget.address),
                      _infoRow('assets/images/rating.png', 'Rating',
                          '${widget.rating}'),
                      _infoRow(
                        'assets/images/time.png',
                        'Opening Time',
                        widget.openingTime.isNotEmpty
                            ? (widget.openingTime != 'null')
                                ? widget.openingTime
                                : 'Not Available'
                            : 'Not Available',
                      ),
                      _infoRow(
                          'assets/images/time.png',
                          'Closing Time',
                          widget.closingTime.isNotEmpty
                              ? widget.closingTime
                              : 'Not Available'),
                      _infoRow('assets/images/description.png', 'Description',
                          widget.desc),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(resturentLat, resturentlong),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('resturentLocation'),
                                position: LatLng(resturentLat, resturentlong),
                              ),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _launchMap(resturentLat, resturentlong),
              backgroundColor: AppTheme.mainColor,
              child: const Icon(Icons.directions, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String iconPath, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(iconPath, height: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.blackColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.blackColor,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
