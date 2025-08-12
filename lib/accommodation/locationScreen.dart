import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/propertyScreen.dart';
import 'package:trunriproject/events/event_location_picker.dart';
// import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/widgets/helper.dart';
import '../widgets/commomButton.dart';

class LocationScreen extends StatefulWidget {
  final String formID;
  final Map<String, dynamic> data;
  const LocationScreen({super.key, required this.formID, required this.data});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  double? selectedLat;
  double? selectedLng;
  String? selectedAddress;
  String? selectedCity;
  String? selectedState;

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
      final Map<String, dynamic> newData = {
        'state': stateController.text.trim(),
        'city': cityController.text.trim(),
        'fullAddress': addressController.text.trim(),
        'lat': selectedLat,
        'long': selectedLng,
      };

      widget.data.addAll(newData);

      NewHelper.hideLoader(loader);
      Get.to(() => PropertyScreen(formID: widget.formID, data: widget.data));
      showSnackBar(context, 'Location saved');
    } else {
      NewHelper.hideLoader(loader);
      log('No user logged in');
    }
  }

  Future<void> _deleteAccommodationData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete by formID
        QuerySnapshot querySnapshot = await _firestore
            .collection('accommodation')
            .where('formID', isEqualTo: widget.formID)
            .get();

        // Also delete by user ID as backup
        QuerySnapshot userQuerySnapshot = await _firestore
            .collection('accommodation')
            .where('uid', isEqualTo: user.uid)
            .where('formID', isEqualTo: widget.formID)
            .get();

        // Delete documents found by formID

        if (querySnapshot.docs.isEmpty && userQuerySnapshot.docs.isEmpty) {
          return;
        }

        for (var doc in querySnapshot.docs) {
          await _firestore.collection('accommodation').doc(doc.id).delete();
          log('Deleted accommodation document: ${doc.id}');
        }

        // Delete documents found by user ID (if different from above)
        for (var doc in userQuerySnapshot.docs) {
          await _firestore.collection('accommodation').doc(doc.id).delete();
          log('Deleted user accommodation document: ${doc.id}');
        }
      }
    } catch (e) {
      log('Error deleting accommodation data: $e');
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Exit Warning',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'If you exit now, your accommodation details will not be saved and any progress will be lost. Are you sure you want to continue?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes, Exit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _handleBackPress() async {
    bool shouldExit = await _showExitDialog();
    if (shouldExit) {
      // Show loading while deleting data
      OverlayEntry loader = NewHelper.overlayLoader(context);
      Overlay.of(context).insert(loader);

      await _deleteAccommodationData();

      NewHelper.hideLoader(loader);

      // Pop the screen
      Get.back();

      // Show confirmation message
      // showSnackBar(context, 'Accommodation data deleted successfully');
    }
  }

  void showAddressModal(BuildContext context) async {
    Map<String, dynamic> result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );
    setState(() {
      selectedLat = result['lat'];
      selectedLng = result['lng'];
      selectedAddress = result['address'];
      selectedCity = result['city'];
      selectedState = result['state'];
      addressController.clear();
      cityController.clear();
      stateController.clear();
      addressController.text = selectedAddress!;
      cityController.text = selectedCity!;
      stateController.text = selectedState!;
    });

    log("Selected Location: $selectedLat, $selectedLng, $selectedAddress, $selectedCity, $selectedState");
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, d) async {
        if (!didPop) {
          await _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Step 1: Location',
            style: TextStyle(color: Colors.black, fontSize: 17),
          ),
          centerTitle: true,
          leading: GestureDetector(
            onTap: _handleBackPress,
            child: const Icon(Icons.clear),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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
                          RequiredValidator(errorText: 'State is required')
                              .call,
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
                      onTap: () {
                        showAddressModal(context);
                      },
                      readOnly: true,
                      controller: addressController,
                      decoration: const InputDecoration(
                        hintText:
                            'Ex: H.No/Apartment no, street name, suburb name',
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
      ),
    );
  }
}
