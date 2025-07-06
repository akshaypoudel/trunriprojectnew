import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:trunriproject/events/postEventScreen.dart';

import 'eventDetailsScreen.dart';

class EventDiscoveryScreen extends StatefulWidget {
  const EventDiscoveryScreen({super.key});

  @override
  State<EventDiscoveryScreen> createState() => _EventDiscoveryScreenState();
}

class _EventDiscoveryScreenState extends State<EventDiscoveryScreen> {
  final List<String> categories = [
    'Music',
    'Traditional',
    'Business',
    'Community & Culture',
    'Health & Fitness',
    'Fashion',
    'Other & Meetup & Sports',
  ];

  RxString selectedDateFilter = 'any'.obs;
  RxList<String> selectedCategories = <String>[].obs;
  TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;

  Widget _buildRadioOption(String text, String value,
      {bool showArrow = false}) {
    return Obx(() {
      return ListTile(
        title: Text(text),
        trailing: showArrow ? const Icon(Icons.chevron_right) : null,
        leading: Radio<String>(
          value: value,
          activeColor: Colors.orange,
          groupValue: selectedDateFilter.value,
          onChanged: (val) {
            selectedDateFilter.value = val!;
          },
        ),
      );
    });
  }

  Widget _buildCheckboxOption(String text) {
    return Obx(() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            activeColor: Colors.orange,
            value: selectedCategories.contains(text),
            onChanged: (val) {
              if (val == true) {
                selectedCategories.add(text);
              } else {
                selectedCategories.remove(text);
              }
            },
          ),
          Text(text),
        ],
      );
    });
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Date',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Column(
                      children: [
                        _buildRadioOption('Any date', 'any'),
                        _buildRadioOption('Today', 'today'),
                        _buildRadioOption('Tomorrow', 'tomorrow'),
                        _buildRadioOption('This week', 'this_week'),
                        _buildRadioOption('This weekend', 'this_weekend'),
                        _buildRadioOption('Choose a date', 'custom_date',
                            showArrow: true),
                      ],
                    ),
                    const Divider(),
                    const Text('Category',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 10,
                      children: categories
                          .map((category) => _buildCheckboxOption(category))
                          .toList(),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            selectedCategories.clear();
                            selectedDateFilter.value = 'any';
                          },
                          child: const Text('Reset',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Apply filters',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> getFilteredEvents() {
    Query query = FirebaseFirestore.instance.collection('MakeEvent');

    // Search by eventName
    if (searchQuery.value.isNotEmpty) {
      query = query
          .where('eventName', isGreaterThanOrEqualTo: searchQuery.value)
          .where('eventName', isLessThan: '${searchQuery.value}z');
    }

    // Date Filter
    if (selectedDateFilter.value != 'any') {
      DateTime now = DateTime.now();
      String startDateStr, endDateStr;

      switch (selectedDateFilter.value) {
        case 'today':
          startDateStr = DateFormat('yyyy-MM-dd').format(now);
          endDateStr =
              DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
          query = query
              .where('eventDate', isGreaterThanOrEqualTo: startDateStr)
              .where('eventDate', isLessThan: endDateStr);
          break;
        case 'tomorrow':
          startDateStr =
              DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
          endDateStr =
              DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 2)));
          query = query
              .where('eventDate', isGreaterThanOrEqualTo: startDateStr)
              .where('eventDate', isLessThan: endDateStr);
          break;
        case 'this_week':
          DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
          startDateStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
          endDateStr = DateFormat('yyyy-MM-dd').format(endOfWeek);
          query = query
              .where('eventDate', isGreaterThanOrEqualTo: startDateStr)
              .where('eventDate', isLessThan: endDateStr);
          break;
        case 'this_weekend':
          DateTime startOfWeekend =
              now.subtract(Duration(days: now.weekday - 6)); // Saturday
          DateTime endOfWeekend =
              startOfWeekend.add(const Duration(days: 2)); // Sunday
          startDateStr = DateFormat('yyyy-MM-dd').format(startOfWeekend);
          endDateStr = DateFormat('yyyy-MM-dd').format(endOfWeekend);
          query = query
              .where('eventDate', isGreaterThanOrEqualTo: startDateStr)
              .where('eventDate', isLessThan: endDateStr);
          break;
        case 'custom_date':
          break;
      }
    }

    // Category Filter
    if (selectedCategories.isNotEmpty) {
      query = query.where('category', arrayContainsAny: selectedCategories);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Discover Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
              onChanged: (value) {
                searchQuery.value = value.trim();
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedCategories.contains(categories[index])) {
                          selectedCategories.remove(categories[index]);
                        } else {
                          selectedCategories.add(categories[index]);
                        }
                      });
                    },
                    child: Chip(
                      label: Text(categories[index],
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor:
                          selectedCategories.contains(categories[index])
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Obx(() => StreamBuilder<QuerySnapshot>(
                  stream: getFilteredEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text("Error fetching data"));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No events available"));
                    }

                    var events = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        var event = events[index];
                        return GestureDetector(
                          onTap: () {
                            Get.to(EventDetailsScreen(
                              eventDate: event['eventDate'],
                              eventName: event['eventName'],
                              eventTime: event['eventTime'],
                              location: event['location'],
                              photo: event['photo'][0],
                              Price: event['ticketPrice'],
                            ));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        bottomLeft: Radius.circular(20)),
                                    child: event['photo'].isNotEmpty
                                        ? Image.network(
                                            event['photo'][0],
                                            height: 150,
                                            width: 150,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            "assets/images/singing.jpeg",
                                            height: 150,
                                            width: 150,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event['eventName'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                              "${event['eventDate']} at ${event['eventTime']}"),
                                          const SizedBox(height: 2),
                                          Text(
                                            event['location'],
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(PostEventScreen()),
        tooltip: "Post Your Event",
        child: const Icon(Icons.add),
      ),
    );
  }
}
