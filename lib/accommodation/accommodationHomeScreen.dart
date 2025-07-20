import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/accommodation/searchForRoomScreen.dart';

import '../home/section_title.dart';

class Accommodationhomescreen extends StatefulWidget {
  const Accommodationhomescreen({super.key});

  @override
  State<Accommodationhomescreen> createState() =>
      _AccommodationhomescreenState();
}

class _AccommodationhomescreenState extends State<Accommodationhomescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 30,
              child: ListView.builder(
                  itemCount: 5,
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      margin: const EdgeInsets.only(right: 5, left: 5),
                      height: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black),
                      child: const Center(
                          child: Text(
                        'sydney',
                        style: TextStyle(color: Colors.white),
                      )),
                    );
                  }),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.to(const Searchforroomscreen());
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          height: 130,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey.shade200),
                          child: Image.asset('assets/images/house.png'),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 20, right: 15),
                          child: Text('Search for rooms & houses'),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        height: 130,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade200),
                        child: Image.asset('assets/images/property.png'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 20, right: 15),
                        child: Text('I have a property/list my property'),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        height: 130,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade200),
                        child: Image.asset('assets/images/room.png'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 20, right: 15),
                        child: Text('Search for rooms & houses'),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        height: 130,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade200),
                        child: Image.asset('assets/images/communite.png'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 20, right: 15),
                        child: Text('I have a property/list my property'),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionTitle(
                    title: "Upcoming Events",
                    press: () {},
                  ),
                ),
                ListView.builder(
                    itemCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                                left: 15, right: 15, bottom: 10),
                            width: Get.width,
                            height: 100,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    'assets/images/fashion.jpeg',
                                    fit: BoxFit.cover,
                                    width: double
                                        .infinity, // Ensures the image stretches across the container width
                                    height: double.infinity,
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black54,
                                          Colors.black38,
                                          Colors.black26,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 10,
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(color: Colors.white),
                                        children: [
                                          TextSpan(
                                            text: "Villa For Family\n",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: "\$${135}")
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    })
              ],
            ),
          ],
        ),
      ),
    );
  }
}
