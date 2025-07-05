import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trunriproject/accommodation/accommodationHomeScreen.dart';
import 'package:trunriproject/events/event_list_screen.dart';
import 'package:trunriproject/home/groceryStoreListScreen.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
import 'package:trunriproject/job/jobHomePageScreen.dart';
import 'package:trunriproject/temple/templeHomePageScreen.dart';

import '../notificatioonScreen.dart';
import '../widgets/appTheme.dart';
import 'icon_btn_with_counter.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  List<String> _allItems = [];
  List<String> _filteredItems = [];
  RxBool showSuggestions = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchItems();
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
    switch (selectedItem.toLowerCase()) {
      case "restaurants":
        Get.to(const ResturentItemListScreen());
        break;
      case "grocery stores":
        Get.to(const GroceryStoreListScreen());
        break;
      case "accommodation":
        Get.to(const Accommodationhomescreen());
        break;
      case "temple":
        Get.to(const TempleHomePageScreen());
        break;
      case "job":
        Get.to(const JobHomePageScreen());
        break;
      case "events":
        Get.to(EventListScreen());
        break;
      default:
        Get.snackbar("Error", "No matching screen found for '$selectedItem'");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    hintText: "Search product",
                    labelStyle: GoogleFonts.roboto(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.orange,
                    ),
                    suffixIcon: GestureDetector(
                        onTap: () {
                          Get.to(const Notificatioonscreen());
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications,
                              color: Colors.orange,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            // Icon(
                            //   Icons.location_on,
                            //   color: Colors.orange,
                            // ),
                            // SizedBox(
                            //   width: 10,
                            // )
                          ],
                        )),
                    hintStyle: GoogleFonts.urbanist(
                        color: const Color(0xFF86888A),
                        fontSize: 13,
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
                            margin: const EdgeInsets.only(left: 15, right: 15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: const Icon(Icons.search),
                              title: Text(_filteredItems[index]),
                              onTap: () {
                                FocusScope.of(context).unfocus();
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
    );
  }
}

const searchOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(1)),
  borderSide: BorderSide.none,
);
