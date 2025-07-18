import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NearbyAccomodationVisual extends StatelessWidget {
  const NearbyAccomodationVisual({super.key});

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Container(
      height: height * .35,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('accommodation').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.orange,
            ));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No accommodations found'));
          }
          return ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: snapshot.data!.docs.map((DocumentSnapshot doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              List<dynamic> images;
              if (data['images'] != null) {
                images = data['images'];
              } else {
                images = [];
              }

              return Container(
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
                      child: images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: images[0],
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
                        "City -  ${data['city'] ?? 'No Address'}",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        "State -  ${data['state'] ?? 'No Address'}",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        "FullAddress -  ${data['fullAddress'] ?? 'No Address'}",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
