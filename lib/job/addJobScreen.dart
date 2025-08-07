import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/events/event_location_picker.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'package:uuid/uuid.dart';

import '../widgets/customTextFormField.dart';
import 'jobHomePageScreen.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  TextEditingController positionNameController = TextEditingController();
  TextEditingController companyNameController = TextEditingController();
  TextEditingController salaryController = TextEditingController();
  TextEditingController minimumSalaryController = TextEditingController();
  TextEditingController maximunSalaryController = TextEditingController();
  TextEditingController openingsController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController industryTypeController = TextEditingController();
  TextEditingController departmentController = TextEditingController();
  TextEditingController employmentTypeController = TextEditingController();
  TextEditingController roleCategoryController = TextEditingController();
  TextEditingController eductionController = TextEditingController();
  TextEditingController keySkillsController = TextEditingController();
  TextEditingController jobDescriptionController = TextEditingController();
  TextEditingController aboutCompanyController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController fullAddressController = TextEditingController();

  final formKey1 = GlobalKey<FormState>();
  final uuid = const Uuid();

  double? selectedLat;
  double? selectedLng;
  String? selectedAddress;
  String? selectedCity;
  String? selectedState;

  String? experience;

  final List<String> experienceOptions = [
    '0-1 years',
    '1-3 years',
    '3-5 years',
    '5+ years'
  ];
  String? employmentType;

  final List<String> employmentTypeOption = [
    'Casual',
    'Temporary',
    'Contract',
    'Part time',
    'Full time',
    'Permanent',
    'Freelance',
    'Apprenticeship',
    'Internship'
  ];

  String? schedule;

  final List<String> scheduleOption = [
    '8 Hour shift',
    '10 Hour shift',
    '12 Hour shift',
    'Less than 8 hours',
    'shift work',
    'morning shift',
    'day shift',
    'afternoon shift',
    'evening shift',
    'night shift',
    'rotating roster',
    'fixed shift',
    'monday to friday',
    'every weekend',
  ];

  String? timeOfAdd;

  final List<String> timeOfAddOption = [
    '1 to 3 days',
    '3 to 7 days',
    '1 to 2 weeks',
    '2 to 4 weeks',
    'more Then 4 weeks',
  ];

  String? industryType;

  final List<String> industryTypeOption = [
    'Media, Advertising & Online',
    'Transport & Logistics',
    'Manufacturing',
    'Construction, Design & Engineering',
    'Information & Communication Technology (ICT)',
    'Financial & Insurance Services',
    'Real Estate & Property Services',
    'Professional Services',
    'Healthcare & Social Assistance',
    'Education, Training',
  ];
  String salaryType = 'Hourly';

  final List<String> salaryTypes = [
    'Daily',
    'Hourly',
    'Monthly',
    'Weekly',
    'Yearly'
  ];

  @override
  void dispose() {
    positionNameController.dispose();
    categoryController.dispose();
    companyNameController.dispose();
    salaryController.dispose();
    minimumSalaryController.dispose();
    maximunSalaryController.dispose();
    openingsController.dispose();
    roleController.dispose();
    industryTypeController.dispose();
    departmentController.dispose();
    employmentTypeController.dispose();
    roleCategoryController.dispose();
    eductionController.dispose();
    keySkillsController.dispose();
    jobDescriptionController.dispose();
    aboutCompanyController.dispose();
    cityController.dispose();
    stateController.dispose();
    fullAddressController.dispose();
    super.dispose();
  }

  void addJobs() {
    final postID = uuid.v4();
    FirebaseFirestore.instance.collection('jobs').doc().set({
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'postID': postID,
      'postDate': DateTime.now(),
      'posterName': AuthServices().getCurrentUserDisplayName()!,
      'positionName': positionNameController.text,
      'companyName': companyNameController.text,
      'experience': experience,
      'salary':
          '$salaryType: \$${minimumSalaryController.text} - \$${maximunSalaryController.text}',
      'openings': openingsController.text,
      'category': categoryController.text,
      'role': roleController.text,
      'industryType': industryType,
      'department': departmentController.text,
      'employmentType': employmentType,
      'roleCategory': roleCategoryController.text,
      'eduction': eductionController.text,
      'keySkills': keySkillsController.text,
      'jobDescription': jobDescriptionController.text,
      'aboutCompany': aboutCompanyController.text,
      'timeOfAdd': timeOfAdd,
      'city': cityController.text,
      'state': stateController.text,
      'fullAddress': fullAddressController.text,
      'latitude': selectedLat,
      'longitude': selectedLng,
      'status': 'pending',
      'isReported': false,
    }).then((value) {
      showSnackBar(context, 'Job Added Successfully');
      // Get.to(const JobHomePageScreen());
      Get.back();
    });
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
      fullAddressController.clear();
      cityController.clear();
      stateController.clear();
      fullAddressController.text = selectedAddress!;
      cityController.text = selectedCity!;
      stateController.text = selectedState!;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Add Job'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Position Name'),
                ),
                CommonTextField(
                    hintText: 'Position Name',
                    controller: positionNameController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Position Name is required'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Company Name'),
                ),
                CommonTextField(
                  hintText: 'Company Name',
                  controller: companyNameController,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Company Name is required'),
                  ]).call,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('City'),
                ),
                CommonTextField(
                  hintText: 'Enter City',
                  controller: cityController,
                  validator:
                      RequiredValidator(errorText: 'City is required').call,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('State'),
                ),
                CommonTextField(
                  hintText: 'Enter State',
                  controller: stateController,
                  validator:
                      RequiredValidator(errorText: 'State is required').call,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Full Address'),
                ),
                CommonTextField(
                  hintText: 'Enter Full Address',
                  readOnly: true,
                  onTap: () {
                    showAddressModal(context);
                  },
                  controller: fullAddressController,
                  validator:
                      RequiredValidator(errorText: 'Address is required').call,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Required Work Experience'),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: DropdownButtonFormField<String>(
                    value: experience,
                    dropdownColor: Colors.white,
                    items: experienceOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        experience = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Work Experience',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        RequiredValidator(errorText: 'Experience is required')
                            .call,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Schedule'),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: DropdownButtonFormField<String>(
                    value: schedule,
                    dropdownColor: Colors.white,
                    items: scheduleOption.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        schedule = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'schedule',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        RequiredValidator(errorText: 'schedule is required')
                            .call,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Salary'),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: salaryType,
                        dropdownColor: Colors.white,
                        items: salaryTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            salaryType = newValue!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Salary Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                          hintText: 'AU\$ 0.00',
                          labelText: 'Min Salary',
                          keyboardType: const TextInputType.numberWithOptions(),
                          controller: minimumSalaryController,
                          validator: MultiValidator([
                            RequiredValidator(
                              errorText: 'minimum Salary is required',
                            ),
                          ]).call),
                    ),
                    Expanded(
                      child: CommonTextField(
                          hintText: 'AU\$ 0.00',
                          labelText: 'Max Salary',
                          keyboardType: const TextInputType.numberWithOptions(),
                          controller: maximunSalaryController,
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: 'maximun Salary is required'),
                          ]).call),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('How many positions are open ?'),
                ),
                CommonTextField(
                    hintText: '10',
                    controller: openingsController,
                    validator: MultiValidator([
                      RequiredValidator(
                          errorText: 'How many positions are open is required'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('What is the Job Category?'),
                ),
                CommonTextField(
                    hintText: 'eg. Developer/Analyst',
                    controller: categoryController,
                    validator: MultiValidator([
                      RequiredValidator(
                        errorText: 'Please Enter a Job Category',
                      ),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Role'),
                ),
                CommonTextField(
                    hintText: 'Role',
                    controller: roleController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Role is required'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Industry Type'),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: DropdownButtonFormField<String>(
                    value: industryType,
                    dropdownColor: Colors.white,
                    items: industryTypeOption.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        industryType = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Industry Type',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        RequiredValidator(errorText: 'Industry Type').call,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Department'),
                ),
                CommonTextField(
                    hintText: 'Department',
                    controller: departmentController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Department is required'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Job Type'),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: DropdownButtonFormField<String>(
                    value: employmentType,
                    dropdownColor: Colors.white,
                    items: employmentTypeOption.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        employmentType = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Job Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: RequiredValidator(errorText: 'Job Type').call,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Education'),
                ),
                CommonTextField(
                    hintText: 'Education',
                    controller: eductionController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Education is required'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Key Skills'),
                ),
                CommonTextField(
                    hintText: 'Key Skills',
                    controller: keySkillsController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Key Skills is required'),
                    ]).call),
                const SizedBox(
                  height: 15,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('How long should this job posting be active?'),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: timeOfAdd,
                        dropdownColor: Colors.white,
                        items: timeOfAddOption.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            timeOfAdd = newValue!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'How long this add will show',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('Job description'),
                ),
                CommonTextField(
                    hintText: 'Job description',
                    controller: jobDescriptionController,
                    minLines: 5,
                    maxLines: 5,
                    validator: MultiValidator([
                      RequiredValidator(
                          errorText: 'Job description is required'),
                      MinLengthValidator(30,
                          errorText:
                              'Job description must be at least 30 characters'),
                    ]).call),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text('About company'),
                ),
                CommonTextField(
                    hintText: 'About company',
                    controller: aboutCompanyController,
                    maxLines: 5,
                    minLines: 5,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'About company is required'),
                    ]).call),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () {
                    if (formKey1.currentState!.validate()) {
                      addJobs();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 25, right: 25),
                    width: size.width,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffFF730A),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Add Job",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
