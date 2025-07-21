import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';

class SearchResturentField extends StatefulWidget {
  const SearchResturentField({super.key});

  @override
  _SearchResturentFieldState createState() => _SearchResturentFieldState();
}

class _SearchResturentFieldState extends State<SearchResturentField> {
  final TextEditingController _controller = TextEditingController();
  List<String> _allItems = [];
  List<String> _filteredItems = [];

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          child: TextFormField(
            controller: _controller,
            onChanged: (value) {
              _filterItems(value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF979797).withOpacity(0.1),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: "Search product",
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        if (_filteredItems.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_filteredItems[index]),
                onTap: () {
                  _controller.text = _filteredItems[index];
                  setState(() {
                    _filteredItems.clear();
                  });
                  if (index == 0) {
                    Get.to(
                      ResturentItemListScreen(
                        restaurant_List:
                            Provider.of<LocationData>(context, listen: false)
                                .getRestaurauntList,
                      ),
                    );
                  }
                },
              );
            },
          ),
      ],
    );
  }
}

const searchOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide.none,
);
