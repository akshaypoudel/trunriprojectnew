import 'dart:developer';
import 'dart:math' as Math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/events/eventDetailsScreen.dart';
import 'package:trunriproject/events/postEventScreen.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'package:trunriproject/subscription/subscription_screen.dart';

enum ActiveFilter { none, city, radius }

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
  String? selectedCityGlobal = 'Sydney';
  double selectedRadiusGlobal = 50;
  ActiveFilter activeFilter = ActiveFilter.none;

  final List<String> categories = [
    'All',
    'Traditional',
    'Business',
    'Culture',
  ];

  @override
  void initState() {
    super.initState();
    filteredEvents = List.from(widget.eventList);
    selectedCategories.add('All'); // Default selected category
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _applyLocationFilter(String city) {
    setState(() {
      selectedCityGlobal = city;
      final list = widget.eventList;
      filteredEvents = list.where((event) {
        final eventCity = event['city']?.toString().toLowerCase() ?? '';
        return eventCity.contains(city.toLowerCase());
      }).toList();
    });
  }

  void _applyRadiusFilter(double radiusKm) {
    final provider = Provider.of<LocationData>(context, listen: false);
    setState(() {
      selectedRadiusGlobal = radiusKm;
      log('calling radius filter....... \n selected radius = $selectedRadiusGlobal');

      filteredEvents = widget.eventList.where((event) {
        final evLat = event['latitude'] as double?;
        final evLng = event['longitude'] as double?;
        if (evLat == null || evLng == null) return false;

        final distance = haversineDistance(
            provider.getLatitude, provider.getLongitude, evLat, evLng);
        return distance <= radiusKm;
      }).toList();

      log('filter events = $filteredEvents');
    });
  }

  double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * Math.pi / 180;

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
                      Icon(
                        Icons.location_on,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Filter by Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 2,
                        width: 100,
                        color: Colors.black12,
                      ),
                      const Text(
                        "  Or  ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff6F6B7A),
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        height: 2,
                        width: 100,
                        color: Colors.black12,
                      ),
                    ],
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
                        divisions: 99,
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
                          setState(() {
                            selectedCityGlobal = 'Sydney';
                            selectedRadiusGlobal = 50;
                            filteredEvents = List.from(widget.eventList);
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear, color: Colors.red),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
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
                          final cityChanged =
                              selectedCity != selectedCityGlobal;
                          final radiusChanged =
                              selectedRadius != selectedRadiusGlobal;

                          if (cityChanged && !radiusChanged) {
                            activeFilter = ActiveFilter.city;
                            _applyLocationFilter(selectedCity);
                          } else if (radiusChanged && !cityChanged) {
                            activeFilter = ActiveFilter.radius;
                            _applyRadiusFilter(selectedRadius);
                          } else if (cityChanged && radiusChanged) {
                            activeFilter = ActiveFilter.city;
                            _applyLocationFilter(selectedCity);
                          } else {
                            activeFilter = ActiveFilter.city;
                            _applyLocationFilter(selectedCity);
                          }

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
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Events Near You',
              style: TextStyle(
                color: Colors.black,
                fontSize: 21,
                // fontWeight: FontWeight.bold,
              ),
            ),
            // centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: IconButton(
                  icon: const Icon(
                    Icons.location_on,
                    color: Colors.deepOrangeAccent,
                    size: 27,
                  ),
                  onPressed: () => _showLocationFilterDialog(),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Category Chips

                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected =
                            selectedCategories.contains(category);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFE5CC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedCategories.clear();
                                  selectedCategories.add(category);

                                  if (category == 'All') {
                                    filteredEvents =
                                        List.from(widget.eventList);
                                  } else {
                                    final query =
                                        searchController.text.toLowerCase();
                                    filteredEvents =
                                        widget.eventList.where((event) {
                                      final name = event['eventName']
                                              ?.toString()
                                              .toLowerCase() ??
                                          '';
                                      final matchesQuery = name.contains(query);
                                      final matchesCategory =
                                          event['category'] != null &&
                                              (event['category'] as List).any(
                                                  (cat) => selectedCategories
                                                      .contains(cat));
                                      return matchesQuery && matchesCategory;
                                    }).toList();
                                  }
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.deepOrangeAccent
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  //search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.deepOrangeAccent.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.deepOrangeAccent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(
                              Icons.search,
                              color: Colors.deepOrangeAccent,
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search Events',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                              ),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                              onChanged: (query) {
                                setState(() {
                                  filteredEvents =
                                      widget.eventList.where((event) {
                                    final name = event['eventName']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    return name.contains(query.toLowerCase());
                                  }).toList();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (selectedCategories.length > 1 ||
                      selectedCityGlobal != 'Sydney' ||
                      searchController.text.isNotEmpty ||
                      activeFilter != ActiveFilter.none)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              selectedCategories.clear();
                              selectedCategories.add('All');
                              selectedCityGlobal = 'Sydney';
                              selectedRadiusGlobal = 50;
                              filteredEvents = List.from(widget.eventList);
                              activeFilter = ActiveFilter.none;
                            });
                          },
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Clear Filters',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  (filteredEvents.isEmpty)
                      ? Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Center(
                            child: Text(
                              'No Events found for this category!',
                              style: GoogleFonts.poppins(fontSize: 18),
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
                            childAspectRatio: 3 / 5.5,
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

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrl is List
                                          ? photoUrl[0]
                                          : photoUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 120,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.deepOrangeAccent,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        height: 120,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_month_sharp,
                                                size: 15,
                                                color: Colors.deepOrangeAccent,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  "${formatEventDate(date)} - $time",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        Colors.deepOrangeAccent,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 15,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  address,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              Get.to(
                                                EventDetailsScreen(
                                                  eventData: event,
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                // color: Colors.deepOrange,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.deepOrange,
                                                    Colors.orange.shade600,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: const Text(
                                                'View Details',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          floatingActionButton: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 7, right: 7),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange,
                      Colors.orange.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  // Multi-layered border effect
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    // Outer glow effect
                    BoxShadow(
                      color: Colors.deepOrange.withValues(alpha: 0.6),
                      blurRadius: 25,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                    // Sharp shadow for depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    // Inner highlight
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 5,
                      spreadRadius: -2,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                // Add an inner container for additional border layers
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(21), // Slightly smaller radius
                    border: Border.all(
                      color: Colors.orange.shade200.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      if (provider.isUserSubscribed) {
                        Get.to(() => const PostEventScreen());
                      } else {
                        _showSubscriptionDialog();
                      }
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            // Border for the icon container
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 27,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String formatEventDate(String inputDate) {
    try {
      // Extract only the date part
      final parts = inputDate.split(' ');
      final datePart = parts.length > 1 ? parts[1] : inputDate;

      // Parse the date
      final parsedDate = DateTime.parse(datePart);

      // Format to desired string
      final formatted = '${_getWeekday(parsedDate.weekday)}, '
          '${_getMonth(parsedDate.month)} ${parsedDate.day}';

      return formatted;
    } catch (e) {
      return inputDate; // Fallback in case of error
    }
  }

// Helper: Convert weekday number to short name
  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[(weekday - 1) % 7];
  }

// Helper: Convert month number to short name
  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[(month - 1) % 12];
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
              const Icon(Icons.lock_outline_rounded,
                  size: 48, color: Colors.deepOrange),
              const SizedBox(height: 12),
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Posting Events is a premium feature.\nSubscribe now to unlock this and more!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.event_available_outlined,
                          color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Post Events and Restaurants'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
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
