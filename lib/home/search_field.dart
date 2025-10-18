import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/lookingForAPlaceScreen.dart';
import 'package:trunriproject/events/eventHomeScreen.dart';
import 'package:trunriproject/home/groceryStoreListScreen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
import 'package:trunriproject/job/jobHomePageScreen.dart';
import 'package:trunriproject/temple/templeHomePageScreen.dart';
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
    if (query.isEmpty) {
      setState(() {
        _filteredItems.clear();
      });
      return;
    }

    final queryLower = query.toLowerCase().trim();

    final filtered = _allItems.where((item) {
      final itemLower = item.toLowerCase().trim();

      // Direct starts with check
      if (itemLower.startsWith(queryLower)) {
        return true;
      }

      // Check if first few characters are similar
      int checkLength = queryLower.length < 4 ? queryLower.length : 4;
      checkLength =
          checkLength > itemLower.length ? itemLower.length : checkLength;

      if (checkLength >= 3) {
        String querySubstring = queryLower.substring(0, checkLength);
        String itemSubstring = itemLower.substring(0, checkLength);

        // Calculate similarity for the substring
        int differences = 0;
        for (int i = 0; i < checkLength; i++) {
          if (querySubstring[i] != itemSubstring[i]) {
            differences++;
          }
        }

        // Allow up to 1 difference in first 3-4 characters
        return differences <= 1;
      }

      return false;
    }).toList();

    // Sort to prioritize exact matches first
    filtered.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();

      if (aLower.startsWith(queryLower) && !bLower.startsWith(queryLower)) {
        return -1;
      } else if (!aLower.startsWith(queryLower) &&
          bLower.startsWith(queryLower)) {
        return 1;
      }

      return 0;
    });

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
          const SizedBox(height: 5),
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Form(
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _filterItems(value);
                        showSuggestions.value = true;
                      } else {
                        showSuggestions.value = false;
                      }
                    },
                    onFieldSubmitted: (value) {
                      if (_filteredItems.isNotEmpty && showSuggestions.value) {
                        String selectedItem = _filteredItems[0];
                        _controller.text = selectedItem;
                        showSuggestions.value = false;
                        setState(() {
                          _filteredItems.clear();
                        });
                        _navigateToScreen(selectedItem);
                        _controller.clear();
                      }
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: "Search TruNri Services",
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.orange),
                      hintStyle: GoogleFonts.urbanist(
                        color: const Color(0xFF86888A),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 14),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 15),
          if (_filteredItems.isNotEmpty)
            Obx(
              () {
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.search),
                                  title: Text(_filteredItems[index]),
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
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
              },
            ),
        ],
      ),
    );
  }
}
