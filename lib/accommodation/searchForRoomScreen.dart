import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/accommodation/propertyFeturesScreen.dart';

import '../home/search_field.dart';
import '../home/section_title.dart';
import '../widgets/appTheme.dart';
import '../widgets/commomButton.dart';

class Searchforroomscreen extends StatefulWidget {
  const Searchforroomscreen({super.key});

  @override
  State<Searchforroomscreen> createState() => _SearchforroomscreenState();
}

class _SearchforroomscreenState extends State<Searchforroomscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // title: const SearchField(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "What kind of property are you seeking?",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 15),
                )),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        height: 80,
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
                        height: 80,
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
                        height: 80,
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
                        height: 80,
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
                        height: 80,
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
                        height: 80,
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
                        height: 80,
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
                        height: 80,
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
            const SizedBox(
              height: 10,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 15, right: 15),
              child: Text(
                "When user click search rooms and houses above optionsds options should appear",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.all(15.0).copyWith(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: CommonButton(
                    text: 'Return',
                    color: const Color(0xffFF730A),
                    textColor: Colors.white,
                    onPressed: () {
                      // Add your logic for button press
                    },
                  ),
                ),
                Expanded(
                  child: CommonButton(
                    text: 'Next',
                    color: AppTheme.primaryColor,
                    textColor: Colors.white,
                    onPressed: () {
                      Get.to(const Propertyfeturesscreen());
                    },
                  ),
                )
              ],
            )),
      ),
    );
  }
}
