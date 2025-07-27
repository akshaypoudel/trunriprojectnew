import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/events/eventDetailsScreen.dart';
import 'package:trunriproject/events/postEventScreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';

class EventDiscoveryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> eventList;

  const EventDiscoveryScreen({super.key, required this.eventList});

  @override
  State<EventDiscoveryScreen> createState() => _EventDiscoveryScreenState();
}

class _EventDiscoveryScreenState extends State<EventDiscoveryScreen> {
  final TextEditingController searchController = TextEditingController();
  late List<Map<String, dynamic>> filteredEvents;
  List<String> selectedCategories = [];
  final List<String> categories = [
    'Music',
    'Traditional',
    'Business',
    'Community & Culture',
    'Health & Fitness',
    'Fashion',
    'Other & Meetup & Sports',
  ];

  @override
  void initState() {
    super.initState();
    filteredEvents = List.from(widget.eventList);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    return StatefulBuilder(
      builder: (context, setState) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: TextField(
              controller: searchController,
              onChanged: (value) {
                final query = value.toLowerCase();
                setState(() {
                  filteredEvents = widget.eventList.where((event) {
                    final name =
                        event['eventName']?.toString().toLowerCase() ?? '';
                    final matchesQuery = name.contains(query);
                    final matchesCategory = selectedCategories.isEmpty ||
                        (event['category'] != null &&
                            (event['category'] as List).any(
                                (cat) => selectedCategories.contains(cat)));
                    return matchesQuery && matchesCategory;
                  }).toList();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search Event',
                hintStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.search, color: Colors.black54),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Events Near You',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (provider.isUserSubscribed) {
                            Get.to(() => const PostEventScreen());
                          } else {
                            Get.to(() => const SubscriptionScreen());
                          }
                        },
                        icon: const Icon(Icons.event, color: Colors.white),
                        label: const Text(
                          'Post an Event',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.orangeAccent.shade200, // Button color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Rounded corners
                          ),
                          elevation: 4,
                          shadowColor:
                              Colors.orangeAccent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategories.contains(category);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: Colors.orange,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                              final query = searchController.text.toLowerCase();
                              filteredEvents = widget.eventList.where((event) {
                                final name = event['eventName']
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';
                                final matchesQuery = name.contains(query);

                                final matchesCategory = selectedCategories
                                        .isEmpty ||
                                    (event['category'] != null &&
                                        (event['category'] as List).any((cat) =>
                                            selectedCategories.contains(cat)));
                                return matchesQuery && matchesCategory;
                              }).toList();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                (filteredEvents.isEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Center(
                          child: Text(
                            'No Events, found for this category!',
                            style: GoogleFonts.poppins(fontSize: 20),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredEvents.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 18,
                          childAspectRatio: 3 / 4.5,
                        ),
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          final name = event['eventName'] ?? 'No Title';
                          final address = event['location'] ?? 'No Location';
                          final photoUrl = event['photo'] != null &&
                                  event['photo'].isNotEmpty
                              ? event['photo']
                              : 'https://via.placeholder.com/400';
                          final date = event['eventDate'] ?? '';
                          final time = event['eventTime'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              Get.to(
                                EventDetailsScreen(
                                  eventDate: date,
                                  eventName: name,
                                  eventTime: time,
                                  location: address,
                                  photoUrl: photoUrl,
                                  price: event['ticketPrice'],
                                  description: event['description'],
                                  category: event['category'][0],
                                  eventType: event['eventType'][0],
                                  contactInfo: event['contactInformation'],
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrl[0],
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$date at $time",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
