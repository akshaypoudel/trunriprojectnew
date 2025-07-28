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
  String? selectedCityGlobal;
  double selectedRadiusGlobal = 50;

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

  void _applyLocationFilter(String city, double radius) {
    setState(() {
      selectedCityGlobal = city;
      selectedRadiusGlobal = radius;

      filteredEvents = widget.eventList.where((event) {
        final eventCity = event['city']?.toString().toLowerCase() ?? '';
        return eventCity.contains(city.toLowerCase());
      }).toList();
    });
  }

  void _showLocationFilterDialog() {
    String selectedCity = selectedCityGlobal ?? 'Sydney';
    double selectedRadius = selectedRadiusGlobal ?? 50;

    final List<String> australianCities = [
      'Sydney',
      'Melbourne',
      'Brisbane',
      'Perth',
      'Adelaide',
      'Gold Coast',
      'Canberra',
      'Hobart',
      'Darwin',
      'Newcastle'
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Filter by Location',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // City Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCity,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: australianCities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCity = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Radius Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Radius (in km)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: selectedRadius,
                        min: 1,
                        max: 100,
                        divisions: 10,
                        activeColor: Colors.orange,
                        label: '${selectedRadius.round()} km',
                        onChanged: (value) {
                          setState(() {
                            selectedRadius = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            selectedCityGlobal = null;
                            selectedRadiusGlobal = 50;
                            filteredEvents = widget.eventList;
                          });
                        },
                        icon: const Icon(Icons.clear, color: Colors.red),
                        label: const Text('Clear Filter',
                            style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.filter_alt, color: Colors.white),
                        label: const Text('Apply Filter',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(context);
                          _applyLocationFilter(selectedCity, selectedRadius);
                          selectedCityGlobal = selectedCity;
                          selectedRadiusGlobal = selectedRadius;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
            title: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    // your search logic
                    decoration: const InputDecoration(
                      hintText: 'Search Event',
                      hintStyle: TextStyle(color: Colors.black54),
                      prefixIcon: Icon(Icons.search, color: Colors.black54),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.location_on_sharp,
                    color: Colors.orange,
                    size: 30,
                  ),
                  onPressed: () => _showLocationFilterDialog(),
                )
              ],
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
                            // Get.to(() => const SubscriptionScreen());
                            _showSubscriptionDialog();
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

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Icon or Image
              const Icon(Icons.lock_outline_rounded,
                  size: 48, color: Colors.deepOrange),

              const SizedBox(height: 12),

              // Title
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              const Text(
                'Posting Events is a premium feature.\nSubscribe now to unlock this and more!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),

              const SizedBox(height: 16),

              // Feature Highlights
              const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.event_available_outlined,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Post Events and Restauraunts'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Post & Promote Listings'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.group_add_sharp,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text(
                          'Send Friend Requests & \nCreate Groups with your friends'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.stars_sharp, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('And More...'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
                  // const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.workspace_premium, size: 20),
                    label: const Text('Subscribe Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.to(() => const SubscriptionScreen());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
