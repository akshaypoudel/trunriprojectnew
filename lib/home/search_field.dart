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
    final normalizedQuery = _normalize(query);

    final filtered = _allItems.where((item) {
      final normalizedItem = _normalize(item);
      return normalizedItem.contains(normalizedQuery) ||
          _isFuzzyMatch(normalizedQuery, normalizedItem);
    }).toList();

    setState(() {
      _filteredItems = filtered;
    });
  }

  String _normalize(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  bool _isFuzzyMatch(String query, String item) {
    int distance = _levenshteinDistance(query, item);
    return distance <= 2;
  }

  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<List<int>> matrix = List.generate(
      s.length + 1,
      (_) => List.filled(t.length + 1, 0),
    );

    for (int i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s.length][t.length];
  }

  void _navigateToScreen(String selectedItem) {
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final item = selectedItem.toLowerCase();

    if (item.contains("restaurants")) {
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
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
