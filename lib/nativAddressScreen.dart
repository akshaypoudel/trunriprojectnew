import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/visaTypeScreen.dart';
import 'package:trunriproject/widgets/commomButton.dart';
import 'package:trunriproject/widgets/customTextFormField.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'package:trunriproject/home/provider/location_data.dart'; // <-- You must create this

class PickUpAddressScreen extends StatefulWidget {
  const PickUpAddressScreen({super.key});

  @override
  State<PickUpAddressScreen> createState() => _PickUpAddressScreenState();
}

class _PickUpAddressScreenState extends State<PickUpAddressScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController suburbController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  double _radiusFilter = 50.0;

  final List<String> australianStates = [
    'New South Wales',
    'Victoria',
    'Queensland',
    'Western Australia',
    'South Australia',
    'Tasmania',
    'Northern Territory',
    'Australian Capital Territory',
  ];

  final Map<String, List<String>> citiesByState = {
    'New South Wales': ['Sydney', 'Newcastle', 'Wollongong'],
    'Victoria': ['Melbourne', 'Geelong', 'Ballarat'],
    'Queensland': ['Brisbane', 'Gold Coast', 'Cairns'],
    'Western Australia': ['Perth', 'Fremantle', 'Albany'],
    'South Australia': ['Adelaide', 'Mount Gambier', 'Whyalla'],
    'Tasmania': ['Hobart', 'Launceston', 'Devonport'],
    'Northern Territory': ['Darwin', 'Alice Springs'],
    'Australian Capital Territory': ['Canberra'],
  };

  @override
  void dispose() {
    stateController.dispose();
    cityController.dispose();
    suburbController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  Future<void> addNativeAddress() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final fullAddress =
          "${suburbController.text}, ${cityController.text}, ${stateController.text}, Australia";
      final location = await locationFromAddress(fullAddress);
      final latitude = location.first.latitude;
      final longitude = location.first.longitude;

      await FirebaseFirestore.instance
          .collection('nativeAddress')
          .doc(uid)
          .set({
        'nativeAddress': {
          'state': stateController.text,
          'city': cityController.text,
          'suburb': suburbController.text,
          'country': countryController.text,
          'pincode': pincodeController.text,
          'latitude': latitude,
          'longitude': longitude,
          'radiusFilter': _radiusFilter,
        },
        'uid': uid,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .set({'city': cityController.text}, SetOptions(merge: true));

      Provider.of<LocationData>(context, listen: false).setNativeLocation(
        state: stateController.text,
        city: cityController.text,
        suburb: suburbController.text,
        zipcode: pincodeController.text,
        radiusFilter: _radiusFilter.toInt(),
      );

      Get.offAll(() => const VisaTypeScreen());
      showSnackBar(context, "Address updated successfully");
    } catch (e) {
      showSnackBar(context, "Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    countryController.text = 'Australia';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Native Address",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Text("State", style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  value: stateController.text.isNotEmpty
                      ? stateController.text
                      : null,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: australianStates
                      .map(
                        (state) => DropdownMenuItem(
                          value: state,
                          child: Text(
                            state,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      stateController.text = value!;
                      cityController.clear();
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'State is required'
                      : null,
                ),
                const SizedBox(height: 20),
                Text("City", style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  value: cityController.text.isNotEmpty
                      ? cityController.text
                      : null,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: (citiesByState[stateController.text] ?? [])
                      .map((city) =>
                          DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      cityController.text = value!;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'City is required'
                      : null,
                ),
                const SizedBox(height: 20),
                Text("Suburb", style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 8),
                CommonTextField(
                  hintText: 'Enter suburb',
                  controller: suburbController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Suburb is required'
                      : null,
                ),
                const SizedBox(height: 20),
                Text("Country", style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 8),
                CommonTextField(
                  hintText: 'Australia',
                  controller: countryController,
                  readOnly: true,
                  prefixicon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/aus_flag.png',
                      height: 20,
                      width: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Pincode", style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 8),
                CommonTextField(
                  hintText: 'Enter pincode',
                  controller: pincodeController,
                  keyboardType: TextInputType.number,
                ),
                Text(
                  "Radius Filter (km)",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _radiusFilter,
                  min: 1,
                  max: 100,
                  activeColor: Colors.orange,
                  inactiveColor: Colors.deepOrange.shade100,
                  divisions: 20,
                  label: "${_radiusFilter.round()}",
                  onChanged: (value) {
                    setState(() {
                      _radiusFilter = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("1 km"),
                    Text("${_radiusFilter.round()} km",
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    const Text("100 km"),
                  ],
                ),
                const SizedBox(height: 40),
                CommonButton(
                  text: "Save",
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      addNativeAddress();
                    }
                  },
                  color: Colors.orange,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
