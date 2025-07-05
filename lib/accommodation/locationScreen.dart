import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trunriproject/accommodation/propertyScreen.dart';
import 'package:trunriproject/widgets/helper.dart';
import '../widgets/commomButton.dart';

class LocationScreen extends StatefulWidget {
  String? dateTime;
  LocationScreen({super.key, this.dateTime});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  TextEditingController cityController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController floorController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> stateList = [
    'Queensland',
    'Victoria',
    'NSW',
    'South Australia',
    'Western Australia',
    'Northern Territory',
    'Tasmania'
  ];

  final Map<String, List<String>> stateCityMap = {
    'Queensland': [
      'Brisbane',
      'Gold Coast',
      'Sunshine Coast',
      'Townsville',
      'Cairns',
      'Toowoomba',
      'Mackay',
      'Rockhampton',
      'Bundaberg',
      'Hervey Bay',
      'Gladstone',
      'Maryborough',
      'Mount Isa',
      'Gympie',
      'Warwick',
      'Emerald',
      'Dalby',
      'Bowen',
      'Charters Towers',
      'Kingaroy',
    ],
    'Victoria': [
      'Melbourne',
      'Geelong',
      'Ballarat',
      'Bendigo',
      'Shepparton',
      'Mildura',
      'Warrnambool',
      'Traralgon',
      'Wodonga',
      'Wangaratta',
      'Horsham',
      'Moe',
      'Morwell',
      'Sale',
      'Bairnsdale',
      'Benalla',
    ],
    'NSW': [
      'Sydney',
      'Newcastle',
      'Central Coast',
      'Wollongong',
      'Albury',
      'Armidale',
      'Bathurst',
      'Blue Mountains',
      'Broken Hill',
      'Campbelltown',
      'Cessnock',
      'Dubbo',
      'Goulburn',
      'Grafton',
      'Griffith',
      'Lake Macquarie',
      'Lismore',
      'Lithgow',
      'Maitland',
      'Nowra',
      'Orange',
      'Parramatta',
      'Penrith',
      'Port Macquarie',
      'Queanbeyan',
      'Richmond-Windsor',
      'Shellharbour',
      'Shoalhaven',
      'Tamworth',
      'Taree',
      'Tweed Heads',
      'Wagga Wagga',
      'Wyong',
      'Fairfield',
      'Hawkesbury',
      'Kiama',
      'Singleton',
      'Yass',
    ],
    'South Australia': [
      'Adelaide',
      'Mount Gambier',
      'Port Augusta',
      'Port Lincoln',
      'Port Pirie',
      'Whyalla',
    ],
    'Western Australia': [
      'Perth',
      'Albany',
      'Armadale',
      'Bunbury',
      'Busselton',
      'Fremantle',
      'Geraldton',
      'Kalgoorlie',
    ],
    'Northern Territory': [
      'Darwin',
      'Palmerston',
    ],
    'Tasmania': [
      'Hobart',
      'Launceston',
      'Devonport',
      'Burnie',
    ],
  };

  String? selectedCity;
  String? selectedState;
  List<String> cityList = [];
  final formKey = GlobalKey<FormState>();

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> saveLocationData() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    User? user = _auth.currentUser;
    log(widget.dateTime.toString());
    if (user != null) {
      QuerySnapshot querySnapshot =
          await _firestore.collection('accommodation').where('formID', isEqualTo: widget.dateTime).get();

      if (querySnapshot.docs.isNotEmpty) {
        Position position = await _getCurrentLocation();
        double latitude = position.latitude;
        double longitude = position.longitude;

        for (var doc in querySnapshot.docs) {
          await _firestore.collection('accommodation').doc(doc.id).update({
            'state': selectedState,
            'city': selectedCity,
            'fullAddress': addressController.text,
            'lat': latitude,
            'long': longitude,
          });
        }
        Get.to(PropertyScreen(dateTime: widget.dateTime));
        NewHelper.hideLoader(loader);
        showSnackBar(context,'Location saved');
      } else {
        NewHelper.hideLoader(loader);
        print('No matching document found');
      }
    } else {
      print('No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Step 1: Location',
          style: TextStyle(color: Colors.black, fontSize: 17),
        ),
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: const Icon(Icons.clear)),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'State',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<String>(
                  value: selectedState,
                  dropdownColor: Colors.white,
                  items: stateList.map((String state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedState = newValue;
                      cityList = stateCityMap[newValue] ?? [];
                      selectedCity = null; // Reset selected city
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select state',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  'City',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  dropdownColor: Colors.white,
                  items: cityList.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedCity = newValue;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select City',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  'Full Address',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                        hintText: 'Ex: H.No/Apartment no, street name, suburb name',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14)),
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Address is required'),
                      MinLengthValidator(6, errorText: 'Minimum 6 characters are required')
                    ])),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
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
                      if (formKey.currentState!.validate()) {
                        saveLocationData();
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
