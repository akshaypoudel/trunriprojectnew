import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShowFilterDataScreen extends StatefulWidget {
  final List<String>? propertyAmenities;
  final List<String>? homeRules;
  final String? selectedCity;
  final String? bedroomFacing;
  final int? bathrooms;

  const ShowFilterDataScreen(
      {super.key,
      this.propertyAmenities,
      this.homeRules,
      this.selectedCity,
      this.bedroomFacing,
      this.bathrooms});

  @override
  State<ShowFilterDataScreen> createState() => _ShowFilterDataScreenState();
}

class _ShowFilterDataScreenState extends State<ShowFilterDataScreen> {
  late Future<List<Map<String, dynamic>>> _filteredData;

  @override
  void initState() {
    super.initState();
    _filteredData = _fetchFilteredData();
    log('bathrooms${widget.bathrooms.toString()}');
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredData() async {
    List<Map<String, dynamic>> filteredList = [];
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('accommodation').get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> amenities = data['propertyAmenities'] ?? [];
        List<dynamic> rules = data['homeRules'] ?? [];
        String city = data['city'] ?? '';
        String bedroomFacing = data['bedroomFacing'] ?? '';
        int bathrooms = data['bathrooms'] ?? 0;

        bool amenitiesMatch = widget.propertyAmenities!
            .every((amenity) => amenities.contains(amenity));
        bool rulesMatch =
            widget.homeRules!.every((rule) => rules.contains(rule));
        bool cityMatch =
            widget.selectedCity == null || widget.selectedCity == city;
        bool bedroomFacingMatch = widget.bedroomFacing == null ||
            widget.bedroomFacing == bedroomFacing;
        bool bathroomsMatch =
            widget.bathrooms == null || widget.bathrooms == bathrooms;

        if (amenitiesMatch &&
            rulesMatch &&
            cityMatch &&
            bedroomFacingMatch &&
            bathroomsMatch) {
          filteredList.add(data);
        }
      }
    } catch (e) {
      log('Error fetching data: $e');
    }
    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtered Data'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _filteredData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                color: Colors.orange,
              ));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data found'));
            } else {
              return GridView.builder(
                itemCount: snapshot.data!.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 10, // Spacing between columns
                  mainAxisSpacing: 10, // Spacing between rows
                  childAspectRatio: 0.8, // Aspect ratio of each grid item
                ),
                itemBuilder: (context, index) {
                  Map<String, dynamic> item = snapshot.data![index];
                  String name = item['address'];
                  String imageUrl = item['images'].toString();
                  imageUrl = imageUrl.replaceAll('[', '').replaceAll(']', '');

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Image failed to load');
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Address: ${item['address'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
