import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/accommodation/tellUsAboutYourselfScreen.dart';

import '../home/search_field.dart';
import '../widgets/appTheme.dart';
import '../widgets/commomButton.dart';

class Propertyfeturesscreen extends StatefulWidget {
  const Propertyfeturesscreen({super.key});

  @override
  State<Propertyfeturesscreen> createState() => _PropertyfeturesscreenState();
}

class _PropertyfeturesscreenState extends State<Propertyfeturesscreen> {
  String selectedValue = '1 week';

  List<String> selectedValueList = ['1 week', '2 weeks'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // title: const SearchField(),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              const Text(
                "Property Features preferences",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 15),
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Room amenities",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'Mandatory',
                      color: const Color(0xffFF730A),
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'Not Mandatory',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Internet",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'Mandatory',
                      color: const Color(0xffFF730A),
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'Not Mandatory',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Bath Room",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'Common Bath room',
                      color: const Color(0xffFF730A),
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'Private',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Transport and shopping centers near by ",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'Mandatory',
                      color: const Color(0xffFF730A),
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'Not Mandatory',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Number of Houses mates",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: '1',
                      color: const Color(0xffFF730A),
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: '2 or more',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'flexible',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Weekly budget",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              CommonButton(
                text: '\$${135}',
                color: AppTheme.primaryColor,
                textColor: Colors.white,
                onPressed: () {},
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Preferred dates",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.only(left: 50, right: 50),
                child: CommonButton(
                  text: '\$${135}',
                  color: AppTheme.primaryColor,
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Duration of Stay",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.only(left: 50, right: 50),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedValue,
                    isExpanded: true,
                    dropdownColor: AppTheme.primaryColor,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: selectedValueList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedValue = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Residential Area",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.only(left: 15, right: 15),
                height: 100,
                width: Get.width,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey),
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "We suggest selecting at least 2 or more areas",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
            ],
          ),
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
                      Get.to(const Tellusaboutyourselfscreen());
                    },
                  ),
                )
              ],
            )),
      ),
    );
  }
}
