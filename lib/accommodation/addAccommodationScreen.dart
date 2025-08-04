import 'dart:io';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/widgets/helper.dart';
import '../widgets/appTheme.dart';
import '../widgets/customTextFormField.dart';
import '../widgets/imageWidget.dart';

class AddAccommodationScreen extends StatefulWidget {
  const AddAccommodationScreen({super.key});

  @override
  State<AddAccommodationScreen> createState() => _AddAccommodationScreenState();
}

class _AddAccommodationScreenState extends State<AddAccommodationScreen> {
  String roomType = 'Single';
  List<String> roomTypeList = ['Single', 'Double', 'Triple'];
  List<File> selectedFiles = [];
  TextEditingController accommodationNameController = TextEditingController();
  TextEditingController accommodationEmailController = TextEditingController();
  TextEditingController accommodationNumberController = TextEditingController();
  TextEditingController accommodationAddressController =
      TextEditingController();
  TextEditingController accommodationFacilitiesController =
      TextEditingController();
  TextEditingController accommodationInformationController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final formKey1 = GlobalKey<FormState>();

  @override
  void dispose() {
    accommodationEmailController.dispose();
    accommodationAddressController.dispose();
    accommodationFacilitiesController.dispose();
    accommodationNameController.dispose();
    accommodationNumberController.dispose();
    accommodationInformationController.dispose();
    super.dispose();
  }

  Future<void> uploadImagesAndSaveData() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user logged in");
      }

      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (File file in selectedFiles) {
        String fileName = path.basename(file.path);
        Reference storageReference =
            _storage.ref().child('accommodations/${user.uid}/$fileName');
        UploadTask uploadTask = storageReference.putFile(file);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      await _firestore.collection('accommodations').add({
        'name': accommodationNameController.text,
        'email': accommodationEmailController.text,
        'contact_number': accommodationNumberController.text,
        'address': accommodationAddressController.text,
        'room_type': roomType,
        'facilities': accommodationFacilitiesController.text,
        'information': accommodationInformationController.text,
        'images': imageUrls,
        'created_at': FieldValue.serverTimestamp(),
        'userID': user.uid,
      });

      Get.to(const MyBottomNavBar());
      NewHelper.hideLoader(loader);
      showSnackBar(context, 'Accommodation added successfully!');
    } catch (e) {
      showSnackBar(context, "Error: $e");
    }
  }

  void showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Accommodation Details",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Name: ${accommodationNameController.text}"),
                Text("Email: ${accommodationEmailController.text}"),
                Text("Contact Number: ${accommodationNumberController.text}"),
                Text("Address: ${accommodationAddressController.text}"),
                Text("Room Type: $roomType"),
                Text("Facilities: ${accommodationFacilitiesController.text}"),
                Text("Information: ${accommodationInformationController.text}"),
                // Display selected images
                const Text('Images:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: selectedFiles.map((file) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Image.file(
                          file,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Edit"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                await uploadImagesAndSaveData();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Accommodation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    'Enter Your Accommodation Name',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
                CommonTextField(
                    hintText: 'Name',
                    controller: accommodationNameController,
                    validator: MultiValidator(
                            [RequiredValidator(errorText: 'Name is required')])
                        .call),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    'Enter Your Email',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
                CommonTextField(
                    hintText: 'Email',
                    controller: accommodationEmailController,
                    validator: MultiValidator(
                            [RequiredValidator(errorText: 'Email is required')])
                        .call),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    'Enter Your Contact Number',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
                CommonTextField(
                    hintText: 'Contact Number',
                    controller: accommodationNumberController,
                    keyboardType: TextInputType.number,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Contact Number is required')
                    ]).call),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    'Enter Your Accommodation Type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: DropdownButtonFormField<String>(
                    value: roomType,
                    onChanged: (String? newValue) {
                      setState(() {
                        roomType = newValue!;
                      });
                    },
                    items: roomTypeList
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: const Color(0xffE2E2E2).withOpacity(.35),
                      contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10)
                          .copyWith(right: 8),
                      focusedErrorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                          borderSide:
                              BorderSide(color: AppTheme.secondaryColor)),
                      errorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                          borderSide: BorderSide(color: Color(0xffE2E2E2))),
                      focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                          borderSide:
                              BorderSide(color: AppTheme.secondaryColor)),
                      disabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(11)),
                        borderSide: BorderSide(color: AppTheme.secondaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(11)),
                        borderSide: BorderSide(
                            color: const Color(0xffE2E2E2).withOpacity(.35)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an item';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    'Enter Your Address',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
                CommonTextField(
                    hintText: 'Address',
                    controller: accommodationAddressController,
                    maxLines: 2,
                    minLines: 2,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Address is required')
                    ]).call),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    'Enter Accommodation facilities',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
                CommonTextField(
                    hintText: 'Accommodation facilities',
                    controller: accommodationFacilitiesController,
                    maxLines: 5,
                    minLines: 5,
                    validator: MultiValidator([
                      RequiredValidator(
                          errorText: 'Accommodation facilities is required')
                    ]).call),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    'Enter Important Information',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
                CommonTextField(
                    hintText: 'Important Information',
                    controller: accommodationInformationController,
                    maxLines: 5,
                    minLines: 5,
                    validator: MultiValidator([
                      RequiredValidator(
                          errorText: 'Important Information is required')
                    ]).call),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: ImageWidget(
                    files: selectedFiles,
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
                    if (formKey1.currentState!.validate()) {
                      showConfirmationDialog();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 25, right: 25),
                    child: Container(
                      width: size.width,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xffFF730A),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
