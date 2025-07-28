import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import '../multiImageWidget.dart';
import '../widgets/appTheme.dart';
import '../widgets/customTextFormField.dart';
import '../widgets/helper.dart';
import 'eventHomeScreen.dart';

class PostEventScreen extends StatefulWidget {
  const PostEventScreen({super.key});

  @override
  State<PostEventScreen> createState() => _PostEventScreenState();
}

class _PostEventScreenState extends State<PostEventScreen> {
  TextEditingController addressController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  TextEditingController eventNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController ticketPriceController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController contactInformationController = TextEditingController();

  Rx<File> profileImage = Rx<File>(File(''));
  List<File> selectedFiles = [];
  String? selectedDate;
  String? selectedTime;
  // String? selectedState;
  var borderColor = const Color(0xff99B2C6).obs;
  List<String> selectedCategories = [];
  List<String> selectedEventTypes = [];
  String selectedEventTypePrice = 'Paid';
  double? selectedLat;
  double? selectedLng;

  @override
  void dispose() {
    addressController.dispose();
    pincodeController.dispose();
    eventNameController.dispose();
    descriptionController.dispose();
    ticketPriceController.dispose();
    locationController.dispose();
    stateController.dispose();

    contactInformationController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() async {
        profileImage.value = File(pickedFile.path);
        borderColor.value = const Color(0xff99B2C6);
      });
    } else {
      showSnackBar(context, "No image selected");
    }
  }

  void showAddressModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => GestureDetector(
        onVerticalDragDown: (_) {}, // 🔒 Prevent drag to avoid conflict
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: const MapLocationPicker(
            config: MapLocationPickerConfig(
              apiKey: Constants.API_KEY,
              initialMapType: MapType.normal,
              zoomControlsEnabled: true,
              liteModeEnabled: false, // ensure full interactivity
            ),
          ),
        ),
      ),
    );
  }

  void showAddressModal2(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: const MapLocationPicker(
          config: MapLocationPickerConfig(
            apiKey: Constants.API_KEY,
            initialMapType: MapType.normal,
            zoomControlsEnabled: true,
          ),
        ),
      ),
    );
  }

  void showAddressModal1(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter Address",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Country (Fixed: Australia)
                TextFormField(
                  initialValue: "India",
                  enabled: false,
                  decoration: const InputDecoration(labelText: "Country"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  // initialValue: "India",
                  controller: stateController,
                  enabled: true,
                  decoration: const InputDecoration(labelText: "State"),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: pincodeController,
                  decoration: const InputDecoration(labelText: "Pincode"),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    locationController.text =
                        "Country: India\nState: ${stateController.text.trim().toString()}\nAddress: ${addressController.text}\nPincode: ${pincodeController.text}";

                    Get.back(); // Close modal
                  },
                  child: const Text("Save Address"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('EEE yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked.format(context);
      });
    }
  }

  void submitEvent() async {
    if (selectedFiles.isEmpty) {
      showSnackBar(context, 'Please upload at least one image');
      return;
    }

    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    try {
      List<String> imageUrls = [];
      for (var file in selectedFiles) {
        String fileName = 'events/${DateTime.now().millisecondsSinceEpoch}.jpg';
        var ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      await FirebaseFirestore.instance.collection('MakeEvent').doc().set({
        'eventName': eventNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': selectedCategories, // Should be a List<String>
        'ticketPrice': ticketPriceController.text.trim(),
        'eventType': selectedEventTypes, // Should be a List<String>
        'eventDate': selectedDate,
        'eventTime': selectedTime,
        'location': locationController.text.trim(),
        'contactInformation': contactInformationController.text.trim(),
        'photo': imageUrls, // Sending multiple images
      }).then((value) async {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection('MakeEvent').get();

        // ✅ Convert to List<Map<String, dynamic>>
        List<Map<String, dynamic>> eventList = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        Provider.of<LocationData>(context, listen: false)
            .setEventList(eventList);
        // Get.to(EventDiscoveryScreen(eventList: eventList));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (c) => EventDiscoveryScreen(
              eventList: eventList,
            ),
          ),
        );
      });

      NewHelper.hideLoader(loader);
      showSnackBar(context, 'Event submitted successfully');
    } catch (e) {
      NewHelper.hideLoader(loader);
      showSnackBar(context, 'Error submitting event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          leading: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: const Icon(Icons.arrow_back_ios)),
          title: const Text('Post Your Event')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              CommonTextField(
                controller: eventNameController,
                hintText: 'Event Name',
                keyboardType: TextInputType.text,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Event Name is required'),
                ]).call,
              ),
              CommonTextField(
                controller: descriptionController,
                hintText: 'Description',
                // controller: passwordController,
                keyboardType: TextInputType.text,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Description is required'),
                ]).call,
              ),

              Padding(
                padding: const EdgeInsets.only(
                    left: 25, right: 25, top: 8.0, bottom: 8),
                child: DropdownButtonFormField(
                  items: [
                    'Music',
                    'Traditional',
                    'Business',
                    'Community & Culture',
                    'Health & Fitness',
                    'Fashion',
                    'other'
                  ]
                      .map((category) => DropdownMenuItem(
                          value: category, child: Text(category)))
                      .toList(),
                  dropdownColor: Colors.white,
                  onChanged: (value) {
                    selectedCategories.add(value!);
                  },
                  decoration: InputDecoration(
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      counterStyle: GoogleFonts.roboto(
                          color: AppTheme.secondaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400),
                      counter: const Offstage(),
                      errorMaxLines: 2,
                      labelStyle: GoogleFonts.roboto(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      hintStyle: GoogleFonts.urbanist(
                          color: const Color(0xFF86888A),
                          fontSize: 13,
                          fontWeight: FontWeight.w400),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(15)),
                      hintText: "Select Category"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 25, right: 25, top: 8.0, bottom: 8),
                child: DropdownButtonFormField<String>(
                  value: selectedEventTypePrice,
                  items: ['Free', 'Paid']
                      .map((category) => DropdownMenuItem(
                          value: category, child: Text(category)))
                      .toList(),
                  dropdownColor: Colors.white,
                  onChanged: (value) {
                    setState(() {
                      selectedEventTypePrice = value!;
                    });
                  },
                  decoration: InputDecoration(
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      counterStyle: GoogleFonts.roboto(
                          color: AppTheme.secondaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400),
                      counter: const Offstage(),
                      errorMaxLines: 2,
                      labelStyle: GoogleFonts.roboto(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      hintStyle: GoogleFonts.urbanist(
                          color: const Color(0xFF86888A),
                          fontSize: 13,
                          fontWeight: FontWeight.w400),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(15)),
                      hintText: "Event Type"),
                ),
              ),

              // Show TextFormField only if "Paid" is selected
              if (selectedEventTypePrice == 'Paid')
                CommonTextField(
                  controller: ticketPriceController,
                  hintText: 'Ticket Price',
                  prefix:
                      const Text("\$ ", style: TextStyle(color: Colors.grey)),
                  keyboardType: TextInputType.number,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Ticket Price is required'),
                  ]).call,
                ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 25, right: 25, top: 8.0, bottom: 8),
                child: DropdownButtonFormField(
                  items: ['Online', 'Offline']
                      .map((category) => DropdownMenuItem(
                          value: category, child: Text(category)))
                      .toList(),
                  dropdownColor: Colors.white,
                  onChanged: (value) {
                    selectedEventTypes.add(value!);
                  },
                  decoration: InputDecoration(
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      counterStyle: GoogleFonts.roboto(
                          color: AppTheme.secondaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400),
                      counter: const Offstage(),
                      errorMaxLines: 2,
                      labelStyle: GoogleFonts.roboto(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      hintStyle: GoogleFonts.urbanist(
                          color: const Color(0xFF86888A),
                          fontSize: 13,
                          fontWeight: FontWeight.w400),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(15)),
                      hintText: "Event Type"),
                ),
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: CommonTextField(
                    hintText: selectedDate ?? 'Event Date',
                    keyboardType: TextInputType.text,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Event Date is required'),
                    ]).call,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: CommonTextField(
                    hintText: selectedTime ?? 'Event Time',
                    keyboardType: TextInputType.text,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Event Time is required'),
                    ]).call,
                  ),
                ),
              ),

              CommonTextField(
                onTap: () => showAddressModal(context),
                controller: locationController,
                hintText: 'Location',
                // controller: passwordController,
                keyboardType: TextInputType.text,
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Location is required'),
                ]).call,
              ),
              CommonTextField(
                controller: contactInformationController,
                hintText: 'Contact Information',
                // controller: passwordController,
                keyboardType: TextInputType.text,
                validator: MultiValidator([
                  RequiredValidator(
                      errorText: 'Contact Information is required'),
                ]).call,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25),
                child: MultiImageWidget(
                  files: selectedFiles,
                  title: 'Upload Business Photos'.tr,
                  validation: true,
                  imageOnly: true,
                  filesPicked: (List<File> pickedFiles) {
                    setState(() {
                      selectedFiles = pickedFiles;
                    });
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  submitEvent();
                },
                child: Container(
                  margin: const EdgeInsets.only(
                      left: 25, right: 25, top: 30, bottom: 10),
                  width: size.width,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF730A),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      "Publish Event",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
