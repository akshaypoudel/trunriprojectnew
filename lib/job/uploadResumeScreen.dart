import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:trunriproject/job/jobHomePageScreen.dart';

import '../widgets/customTextFormField.dart';
import 'package:trunriproject/widgets/helper.dart';

class UploadResumeScreen extends StatefulWidget {
  const UploadResumeScreen({super.key});

  @override
  State<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController familyNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  String? selectedFileName;
  File? selectedFile;
  final formKey = GlobalKey<FormState>();
  String? fileUrl;

  @override
  void dispose() {
    firstNameController.dispose();
    familyNameController.dispose();
    emailController.dispose();
    cityController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> uploadData(BuildContext context) async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    if (selectedFile != null) {
      String fileName = basename(selectedFile!.path);
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child('resumes/$fileName')
          .putFile(selectedFile!);

      TaskSnapshot taskSnapshot = await uploadTask;
      fileUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('resumes').add({
        'first_name': firstNameController.text,
        'family_name': familyNameController.text,
        'email': emailController.text,
        'city': cityController.text,
        'phone_number': phoneNumberController.text,
        'resume_file': fileUrl,
      }).then((value) {
        NewHelper.hideLoader(loader);
        showSnackBar(context, 'Thanks for applying for this job');
        Get.to(const JobHomePageScreen());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Upload Your Information'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('First name'),
                ),
                CommonTextField(
                    hintText: 'First name',
                    controller: firstNameController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'First name is required'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Family name'),
                ),
                CommonTextField(
                    hintText: 'Family name',
                    controller: familyNameController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Family name is required'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Email'),
                ),
                CommonTextField(
                    hintText: 'Email',
                    controller: emailController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Email is required'),
                      EmailValidator(errorText: 'Please enter valid email'.tr),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('City,State/Territory(Optional)'),
                ),
                CommonTextField(
                    hintText: 'City,State/Territory(Optional)',
                    controller: cityController,
                    validator: MultiValidator([
                      RequiredValidator(
                        errorText: 'City,State/Territory is required',
                      ),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Phone Number'),
                ),
                CommonTextField(
                  hintText: 'Phone Number',
                  controller: phoneNumberController,
                  keyboardType: TextInputType.number,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Phone Number is required'),
                  ]).call,
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(2),
                    padding:
                        const EdgeInsets.only(left: 40, right: 40, bottom: 10),
                    color: Colors.red,
                    dashPattern: const [6],
                    strokeWidth: 1,
                    child: InkWell(
                      onTap: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'docx', 'trf', 'txt'],
                          allowMultiple: false,
                        );
                        if (result != null) {
                          setState(() {
                            selectedFileName = result.files.single.name;
                            selectedFile = File(result.files.single.path!);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.only(top: 8),
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        width: double.maxFinite,
                        height: 150,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/upload.png',
                              height: 60,
                              width: 50,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              selectedFileName ?? 'Upload a resume',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Text(
                              'Accepted file types: PDF, DOCX, TRF, TXT',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () async {
                    if (formKey.currentState!.validate()) {
                      await uploadData(context);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 15, right: 15),
                    width: size.width,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffFF730A),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Upload",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
