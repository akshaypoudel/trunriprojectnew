import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/accommodationHomeScreen.dart';
import 'package:trunriproject/accommodation/lookingForAPlaceScreen.dart';
import 'package:trunriproject/events/eventHomeScreen.dart';
import 'package:trunriproject/home/groceryStoreListScreen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
import 'package:trunriproject/job/jobHomePageScreen.dart';
import 'package:trunriproject/temple/templeHomePageScreen.dart';

import '../notificatioonScreen.dart';
import '../widgets/appTheme.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.focusNode});
  final FocusNode focusNode;

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;
  List<String> _allItems = [];
  List<String> _filteredItems = [];
  RxBool showSuggestions = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchItems();

    _focusNode = widget.focusNode;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // When losing focus, hide suggestions and clear filtered items
      showSuggestions.value = false;
      setState(() {
        _filteredItems.clear();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('search').get();
      final items =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _allItems = items;
      });
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  void _filterItems(String query) {
    final filtered = _allItems
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      _filteredItems = filtered;
    });
  }

  void _navigateToScreen(String selectedItem) {
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final item = selectedItem.toLowerCase();

    if (item.contains("restaurant")) {
      Get.to(
        ResturentItemListScreen(
          restaurant_List: Provider.of<LocationData>(context, listen: false)
              .getRestaurauntList,
        ),
      );
    } else if (item.contains("grocery")) {
      Get.to(
        GroceryStoreListScreen(
          groceryStores:
              Provider.of<LocationData>(context, listen: false).getGroceryList,
        ),
      );
    } else if (item.contains("accommodation")) {
      Get.to(
        LookingForAPlaceScreen(
          accommodationList: Provider.of<LocationData>(context, listen: false)
              .getAccomodationList,
        ),
      );
    } else if (item.contains("temple")) {
      Get.to(
        TempleHomePageScreen(
          templesList:
              Provider.of<LocationData>(context, listen: false).getTemplesList,
        ),
      );
    } else if (item.contains("job")) {
      Get.to(const JobHomePageScreen());
    } else if (item.contains("event")) {
      Get.to(
        EventDiscoveryScreen(
          eventList:
              Provider.of<LocationData>(context, listen: false).getEventList,
        ),
      );
    } else {
      Get.snackbar("Error", "No matching screen found for '$selectedItem'");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Form(
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _filterItems(value);
                        showSuggestions.value = true;
                        setState(() {});
                      } else {
                        showSuggestions.value = false;
                      }
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      counterStyle: GoogleFonts.roboto(
                          color: AppTheme.secondaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400),
                      counter: const Offstage(),
                      errorMaxLines: 2,
                      hintText: "Search TruNri Services",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.orange,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          Get.to(const NotificationScreen());
                        },
                        icon: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.orange.shade50,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.orange,
                            size: 27,
                          ),
                        ),
                      ),
                      hintStyle: GoogleFonts.urbanist(
                          color: const Color(0xFF86888A),
                          fontSize: 17,
                          fontWeight: FontWeight.w400),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      disabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.orange, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.orange, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.orange, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      border: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.orange, width: 1),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          ),
          if (_filteredItems.isNotEmpty)
            Obx(() {
              return showSuggestions.value
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.only(left: 15, right: 15),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: const Icon(Icons.search),
                                title: Text(_filteredItems[index]),
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();

                                  String selectedItem = _filteredItems[index];
                                  _controller.text = selectedItem;
                                  setState(() {
                                    _filteredItems.clear();
                                  });
                                  _navigateToScreen(selectedItem);
                                  _controller.clear();
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : const SizedBox.shrink();
            }),
        ],
      ),
    );
  }
}

const searchOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(1)),
  borderSide: BorderSide.none,
);
