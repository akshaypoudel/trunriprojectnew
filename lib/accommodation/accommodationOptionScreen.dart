import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/whichYouListScreen.dart';
import 'package:trunriproject/home/provider/location_data.dart';

import 'lookingForAPlaceScreen.dart';

class Accommodationoptionscreen extends StatefulWidget {
  const Accommodationoptionscreen({super.key});

  @override
  State<Accommodationoptionscreen> createState() =>
      _AccommodationoptionscreenState();
}

class _AccommodationoptionscreenState extends State<Accommodationoptionscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // title: const Text('Accomodations'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Hi there, how can i help you?',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 30),
              ),
              const Text(
                'To get started, let us know what brings to you to TruNri',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w300,
                    fontSize: 15),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Get.to(const WhichYouListScreen());
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(11)),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/room.png',
                        height: 70,
                        width: 70,
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      const Text(
                        'I want to publish a listing',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {
                  Get.to(
                    LookingForAPlaceScreen(
                      accommodationList:
                          Provider.of<LocationData>(context, listen: false)
                              .getAccomodationList,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(11)),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/house.png',
                        height: 70,
                        width: 70,
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      const Text(
                        'I am looking for a place to live',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
