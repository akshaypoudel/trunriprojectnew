import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  String? photo;
  String? eventName;
  String? eventDate;
  String? eventTime;
  String? location;
  String? Price;

  EventDetailsScreen(
      {super.key,
      this.eventDate,
      this.eventName,
      this.eventTime,
      this.location,
      this.photo,
      this.Price});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool issaved = false;
  bool isFavorite = false;

  // Future<void> _toggleFavorite() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     final docRef = FirebaseFirestore.instance
  //         .collection('favorite')
  //         .doc(user.uid)
  //         .collection('restaurants')
  //         .doc(widget.eventName);
  //
  //     if (isFavorite) {
  //       await docRef.delete();
  //     } else {
  //       await docRef.set({
  //         'favorite': true,
  //         'uid': user.uid,
  //         'name': widget.name,
  //         'address': widget.address,
  //         'image': widget.image,
  //         'rating':widget.rating,
  //         'openingTime': widget.openingTime,
  //         'closingTime' : widget.closingTime,
  //         'desc': widget.desc
  //       });
  //     }
  //
  //     setState(() {
  //       isFavorite = !isFavorite;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              color: Colors.white,
              margin: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.photo!.isNotEmpty
                      ? Image.network(
                          widget.photo.toString(),
                          fit: BoxFit.fill,
                          width: double.infinity,
                        )
                      : Image.asset("assets/images/singing.jpeg",
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.eventName!,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("${widget.eventDate!} at ${widget.eventTime!}"),
                        Text(widget.location!,
                            style: const TextStyle(color: Colors.blue)),
                        Text('Price: ${widget.Price!}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 30,
                                ),
                              ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  Share.share(
                                      "${widget.eventName} at ${widget.eventTime}${widget.eventDate}");
                                }),
                            IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () async {
                                  final Uri uri =
                                      Uri.parse(widget.location.toString());

                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    throw 'Could not open the map.';
                                  }
                                }),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 100,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFF730A),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Buy Ticket",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
