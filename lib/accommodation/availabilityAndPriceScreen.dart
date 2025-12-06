import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../widgets/commomButton.dart';
import '../widgets/helper.dart';
import 'addMediaScreen.dart';

class AvailabilityAndPriceScreen extends StatefulWidget {
  final String formID;
  final Map<String, dynamic> data;
  const AvailabilityAndPriceScreen({
    super.key,
    required this.formID,
    required this.data,
  });

  @override
  State<AvailabilityAndPriceScreen> createState() =>
      _AvailabilityAndPriceScreenState();
}

class _AvailabilityAndPriceScreenState
    extends State<AvailabilityAndPriceScreen> {
  DateTime? selectedAvailabilityDate;
  DateTime? selectedNoDate;
  String selectedMinStay = '1 Month';
  String selectedMaxStay = 'No max';
  bool billsInclude = false;
  bool noDepositRequired = false;
  bool rentalContract = false;
  bool cleaningService = false;
  bool cityHallRegistrationSupport = false;
  bool maintenanceService = false;
  bool lawnCare = false;
  bool poolAccess = false;
  bool gym = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> savePriceData() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    User? user = _auth.currentUser;
    if (user != null) {
      Map<String, dynamic> newData = {
        'selectedAvailabilityDate': selectedAvailabilityDate,
        'selectedNoDate': selectedNoDate,
        'selectedMinStay': selectedMinStay,
        'selectedMaxStay': selectedMaxStay,
        'billsInclude': billsInclude,
        'noDepositRequired': noDepositRequired,
        'rentalContract': rentalContract,
        'cleaningService': cleaningService,
        'cityHallRegistrationSupport': cityHallRegistrationSupport,
        'maintenanceService': maintenanceService,
        'lawnCare': lawnCare,
        'poolAccess': poolAccess,
        'gym': gym,
      };

      widget.data.addAll(newData);

      Get.to(() => AddMediaScreen(formID: widget.formID, data: widget.data));
      NewHelper.hideLoader(loader);
      showSnackBar(context, 'Availability and price saved');
    } else {
      NewHelper.hideLoader(loader);
      log('No user logged in');
    }
  }

  Future<void> _selectDate(
      BuildContext context, bool isAvailabilityDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            dialogTheme: DialogThemeData(
                backgroundColor: Colors.white), // background color
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isAvailabilityDate) {
          selectedAvailabilityDate = picked;
        } else {
          selectedNoDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No Date';
    return DateFormat('d MMMM yyyy').format(date);
  }

  List<String> _generateMonths(int count) {
    return List<String>.generate(
        count, (int index) => '${index + 1} Month${index + 1 > 1 ? 's' : ''}');
  }

  List<String> _generateYears(int count) {
    return List<String>.generate(
        count, (int index) => '${index + 1} Year${index + 1 > 1 ? 's' : ''}');
  }

  bool isFormComplete() {
    if (selectedAvailabilityDate == null ||
        selectedNoDate == null ||
        selectedMinStay.isEmpty ||
        selectedMaxStay.isEmpty) {
      return false;
    }
    return true;
  }

  void showToast(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> months = _generateMonths(12);
    List<String> years = _generateYears(20);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Step 3: Availability and price',
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the availability',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 10, left: 25, right: 25),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(_formatDate(selectedAvailabilityDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 10, left: 25, right: 25),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(_formatDate(selectedNoDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedAvailabilityDate == null || selectedNoDate == null)
                  const Text(
                    'Please select availability dates',
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Minimum stay',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () async {
                            String? selectedValue = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('Select Minimum Stay'),
                                  content: SizedBox(
                                    width: double.minPositive,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: months.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return ListTile(
                                          title: Text(months[index]),
                                          onTap: () {
                                            Navigator.pop(
                                                context, months[index]);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                            if (selectedValue != null) {
                              setState(() {
                                selectedMinStay = selectedValue;
                              });
                            }
                          },
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.only(
                                top: 10, bottom: 10, left: 25, right: 25),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(selectedMinStay),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maximum stay',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () async {
                            String? selectedValue = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('Select Maximum Stay'),
                                  content: SizedBox(
                                    width: double.minPositive,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: years.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return ListTile(
                                          title: Text(years[index]),
                                          onTap: () {
                                            Navigator.pop(
                                                context, years[index]);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                            if (selectedValue != null) {
                              setState(() {
                                selectedMaxStay = selectedValue;
                              });
                            }
                          },
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.only(
                                top: 10, bottom: 10, left: 25, right: 25),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(selectedMaxStay),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Are the amenities and utilities included in the rental price?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: rentalContract,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          rentalContract = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Rental contract',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: cleaningService,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          cleaningService = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Cleaning Service',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: maintenanceService,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          maintenanceService = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Maintenance service',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: lawnCare,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          lawnCare = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Lawn care',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: poolAccess,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          poolAccess = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Pool access',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: gym,
                      activeColor: const Color(0xffFF730A),
                      onChanged: (value) {
                        setState(() {
                          gym = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Gym',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
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
                    if (isFormComplete()) {
                      savePriceData();
                    } else {
                      showToast('Please fill in all required fields');
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
