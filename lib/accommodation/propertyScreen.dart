import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/commomButton.dart';
import '../widgets/helper.dart';
import 'availabilityAndPriceScreen.dart';

class PropertyScreen extends StatefulWidget {
  final String formID;
  const PropertyScreen({super.key, required this.formID});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  int singleBadRoom = 0;
  int doubleBadRoom = 0;
  int bathrooms = 0;
  int toilets = 0;
  int livingFemale = 0;
  int livingMale = 0;
  bool livingNonBinary = false;
  List<String> roomAmenities = [];
  List<String> propertyAmenities = [];
  List<String> homeRules = [];

  bool isLiftAvailable = false;
  String bedroomFacing = '';
  bool isBedInRoom = false;

  bool showError = false;

  void _updateCounter(String key, bool increment) {
    setState(() {
      switch (key) {
        case 'singleBadRoom':
          singleBadRoom = increment
              ? singleBadRoom + 1
              : (singleBadRoom > 0 ? singleBadRoom - 1 : 0);
          break;
        case 'doubleBadRoom':
          doubleBadRoom = increment
              ? doubleBadRoom + 1
              : (doubleBadRoom > 0 ? doubleBadRoom - 1 : 0);
          break;
        case 'bathrooms':
          bathrooms =
              increment ? bathrooms + 1 : (bathrooms > 0 ? bathrooms - 1 : 0);
          break;
        case 'toilets':
          toilets = increment ? toilets + 1 : (toilets > 0 ? toilets - 1 : 0);
          break;
        case 'livingFemale':
          livingFemale = increment
              ? livingFemale + 1
              : (livingFemale > 0 ? livingFemale - 1 : 0);
          break;
        case 'livingMale':
          livingMale = increment
              ? livingMale + 1
              : (livingMale > 0 ? livingMale - 1 : 0);
          break;
      }
    });
  }

  Widget _buildCounterRow(String label, String key, int value) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        GestureDetector(
          onTap: () => _updateCounter(key, false),
          child: const CircleAvatar(
            maxRadius: 15,
            minRadius: 15,
            backgroundColor: Color(0xffFF730A),
            child: Icon(
              Icons.remove,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$value'),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _updateCounter(key, true),
          child: const CircleAvatar(
            maxRadius: 15,
            minRadius: 15,
            backgroundColor: Color(0xffFF730A),
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  bool isFormComplete() {
    if (singleBadRoom == 0 &&
        doubleBadRoom == 0 &&
        bathrooms == 0 &&
        toilets == 0 &&
        livingFemale == 0 &&
        livingMale == 0 &&
        !livingNonBinary) {
      return false;
    }
    return true;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePropertyData() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('accommodation')
          .where('formID', isEqualTo: widget.formID)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await _firestore.collection('accommodation').doc(doc.id).update({
            'singleBadRoom': singleBadRoom,
            'doubleBadRoom': doubleBadRoom,
            'bathrooms': bathrooms,
            'toilets': toilets,
            'livingFemale': livingFemale,
            'livingMale': livingMale,
            'livingNonBinary': livingNonBinary,
            'isLiftAvailable': isLiftAvailable,
            'isBedInRoom': isBedInRoom,
            'roomAmenities': roomAmenities,
            'propertyAmenities': propertyAmenities,
            'homeRules': homeRules,
          });
        }
        Get.to(() => AvailabilityAndPriceScreen(formID: widget.formID));
        NewHelper.hideLoader(loader);
        showSnackBar(context, 'Property saved');
      } else {
        NewHelper.hideLoader(loader);
        log('No matching document found');
      }
    } else {
      NewHelper.hideLoader(loader);
      log('No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Step 2: Property',
          style: TextStyle(color: Colors.black, fontSize: 17),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Is there a lift?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Radio<bool>(
                    value: true,
                    activeColor: const Color(0xffFF730A),
                    groupValue: isLiftAvailable,
                    onChanged: (value) {
                      setState(() {
                        isLiftAvailable = value!;
                      });
                    },
                  ),
                  const Text('Yes'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Radio<bool>(
                    value: false,
                    activeColor: const Color(0xffFF730A),
                    groupValue: isLiftAvailable,
                    onChanged: (value) {
                      setState(() {
                        isLiftAvailable = value!;
                      });
                    },
                  ),
                  const Text('No'),
                ],
              ),
              if (showError && !isLiftAvailable)
                const Text(
                  'Please specify if there is a lift',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              const Text(
                'How many bedrooms are available?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              const SizedBox(height: 10),
              _buildCounterRow(
                  'Single Bedrooms', 'singleBadRoom', singleBadRoom),
              const SizedBox(height: 5),
              Divider(thickness: 1, color: Colors.grey.shade300),
              const SizedBox(height: 5),
              _buildCounterRow(
                  'Double Bedrooms', 'doubleBadRoom', doubleBadRoom),
              if (showError && singleBadRoom == 0 && doubleBadRoom == 0)
                const Text(
                  'Please add at least one bedroom',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              const Text(
                'How many bathrooms are available?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              const SizedBox(height: 10),
              _buildCounterRow('Bathrooms', 'bathrooms', bathrooms),
              const SizedBox(height: 5),
              Divider(thickness: 1, color: Colors.grey.shade300),
              const SizedBox(height: 5),
              _buildCounterRow('Toilets', 'toilets', toilets),
              if (showError && bathrooms == 0 && toilets == 0)
                const Text(
                  'Please add at least one bathroom or toilet',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              const Text(
                'Who is currently living in the property?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              const SizedBox(height: 10),
              _buildCounterRow('Female', 'livingFemale', livingFemale),
              const SizedBox(height: 5),
              Divider(thickness: 1, color: Colors.grey.shade300),
              const SizedBox(height: 5),
              _buildCounterRow('Male', 'livingMale', livingMale),
              const SizedBox(height: 5),
              Divider(thickness: 1, color: Colors.grey.shade300),
              const SizedBox(height: 5),
              Row(
                children: [
                  Checkbox(
                    value: livingNonBinary,
                    activeColor: const Color(0xffFF730A),
                    onChanged: (value) {
                      setState(() {
                        livingNonBinary = value!;
                      });
                    },
                  ),
                  const Text('Non-Binary'),
                ],
              ),
              if (showError &&
                  livingFemale == 0 &&
                  livingMale == 0 &&
                  !livingNonBinary)
                const Text(
                  'Please add at least one occupant',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              const Text(
                'Is there a bed in the room?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Radio<bool>(
                    value: true,
                    activeColor: const Color(0xffFF730A),
                    groupValue: isBedInRoom,
                    onChanged: (value) {
                      setState(() {
                        isBedInRoom = value!;
                      });
                    },
                  ),
                  const Text('Yes'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Radio<bool>(
                    value: false,
                    activeColor: const Color(0xffFF730A),
                    groupValue: isBedInRoom,
                    onChanged: (value) {
                      setState(() {
                        isBedInRoom = value!;
                      });
                    },
                  ),
                  const Text('No'),
                ],
              ),
              if (showError && !isBedInRoom)
                const Text(
                  'Please specify if there is a bed in the room',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              const Text(
                'Room amenities',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  for (String amenity in [
                    'Wardrobe',
                    'Air conditioning',
                    'Heating controls',
                    'WI-FI',
                    'Curtains',
                    'Shelves'
                  ])
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (roomAmenities.contains(amenity)) {
                            roomAmenities.remove(amenity);
                          } else {
                            roomAmenities.add(amenity);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: roomAmenities.contains(amenity)
                              ? const Color(0xffFF730A)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(amenity),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Property amenities',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  for (String amenity in [
                    'Gym',
                    'Garden',
                    'Laundry facilities',
                    'Swimming pool',
                    'Garage',
                    'Parking space',
                    'Television',
                    'Iron',
                    'Refrigerator',
                    'Microwave',
                    'Dishwasher',
                    'Bath tub',
                    'Grill',
                    'Fire pit',
                    'Smoke alarm',
                    'Security system',
                    'Balcony',
                    'Deck',
                    'Sound system',
                  ])
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (propertyAmenities.contains(amenity)) {
                            propertyAmenities.remove(amenity);
                          } else {
                            propertyAmenities.add(amenity);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: propertyAmenities.contains(amenity)
                              ? const Color(0xffFF730A)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(amenity),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Are there any house rules',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  for (String amenity in [
                    'No smoking',
                    'No loud music after 9pm',
                    'No drinking',
                    'No pets',
                    'No guests',
                    'No parties'
                  ])
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (homeRules.contains(amenity)) {
                            homeRules.remove(amenity);
                          } else {
                            homeRules.add(amenity);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: homeRules.contains(amenity)
                              ? const Color(0xffFF730A)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(amenity),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              if (showError &&
                  (roomAmenities.isEmpty ||
                      propertyAmenities.isEmpty ||
                      homeRules.isEmpty))
                const Text(
                  'Please fill all the fields before continuing',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 30),
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
                    text: 'Continue',
                    color: const Color(0xffFF730A),
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        showError = true;
                      });

                      if (isFormComplete()) {
                        savePropertyData();
                      } else {
                        showSnackBar(context, 'Please fill all the fields');
                      }
                    },
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
