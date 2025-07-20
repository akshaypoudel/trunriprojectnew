import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/propertyScreen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/widgets/helper.dart';
import '../widgets/commomButton.dart';

class LocationScreen extends StatefulWidget {
  final String formID;
  const LocationScreen({super.key, required this.formID});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final formKey = GlobalKey<FormState>();

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> saveLocationData() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    User? user = _auth.currentUser;

    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('accommodation')
          .where('formID', isEqualTo: widget.formID)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Position position = await _getCurrentLocation();

        final provider = Provider.of<LocationData>(context, listen: false);

        double latitude = provider.getLatitude;
        double longitude = provider.getLongitude;

        for (var doc in querySnapshot.docs) {
          await _firestore.collection('accommodation').doc(doc.id).update({
            'state': stateController.text.trim(),
            'city': cityController.text.trim(),
            'fullAddress': addressController.text.trim(),
            'lat': latitude,
            'long': longitude,
          });
        }

        NewHelper.hideLoader(loader);
        Get.to(() => PropertyScreen(formID: widget.formID));
        showSnackBar(context, 'Location saved');
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
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'State',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: stateController,
                  decoration: const InputDecoration(
                    hintText: 'Enter state name',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  validator:
                      RequiredValidator(errorText: 'State is required').call,
                ),
                const SizedBox(height: 30),
                const Text(
                  'City',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    hintText: 'Enter city name',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  validator:
                      RequiredValidator(errorText: 'City is required').call,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Full Address',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: H.No/Apartment no, street name, suburb name',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Address is required'),
                    MinLengthValidator(6,
                        errorText: 'Minimum 6 characters are required'),
                  ]).call,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
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
        ),
      ),
    );
  }
}
