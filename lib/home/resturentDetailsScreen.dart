// Full revised code with improved UI and better layout handling

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
import 'package:share_plus/share_plus.dart';
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
  });

  @override
  State<ResturentDetailsScreen> createState() => _ResturentDetailsScreenState();
}

class _ResturentDetailsScreenState extends State<ResturentDetailsScreen> {
  final serviceController = Get.put(ServiceController());
  bool isFavorite = false;
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

  void checkIfFavorite() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      var doc = await FirebaseFirestore.instance
          .collection('favorite')
          .doc(userId)
          .collection('restaurants')
          .doc(widget.name)
          .get();

      setState(() {
        isFavorite = doc.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('favorite')
          .doc(user.uid)
          .collection('restaurants')
          .doc(widget.name);

      if (isFavorite) {
        await docRef.delete();
      } else {
        await docRef.set({
          'favorite': true,
          'uid': user.uid,
          'name': widget.name,
          'address': widget.address,
          'image': widget.image,
          'rating': widget.rating,
          'openingTime': widget.openingTime,
          'closingTime': widget.closingTime,
          'desc': widget.desc
        });
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (Get.arguments != null) {
      resturentLat = Get.arguments[0];
      resturentlong = Get.arguments[1];
    }
    checkIfFavorite();
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
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.favorite,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.buttonColor,
                        ),
                      ),
                      (widget.isOpenNow)
                          ? const Chip(
                              side: BorderSide(color: Colors.red),
                              backgroundColor: Colors.orangeAccent,
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
                              backgroundColor: Colors.orangeAccent,
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
