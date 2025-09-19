import 'dart:developer';
import 'dart:math' as Math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/events/eventDetailsScreen.dart';
import 'package:trunriproject/events/postEventScreen.dart';
import 'package:trunriproject/home/constants.dart';
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

class _EventDiscoveryScreenState extends State<EventDiscoveryScreen>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  late List<Map<String, dynamic>> filteredEvents;
  List<String> selectedCategories = [];
  String? selectedCityGlobal = 'Sydney';
  double selectedRadiusGlobal = 50;
  ActiveFilter activeFilter = ActiveFilter.none;
  String selectedTimeFilter = 'Upcoming';
  late AnimationController _animationController;

  // NEW: Filter state variables
  String selectedTimeOfDay = 'Any time';
  String selectedVenue = 'Any venue';
  String selectedDistance = 'Any distance';

  final List<String> timeFilters = [
    'Upcoming',
    'Today',
    'Tomorrow',
    'Weekend',
  ];

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'All',
      'icon': Icons.apps_rounded,
      'color': Colors.blue,
      'gradient': [Colors.blue.shade400, Colors.blue.shade600],
    },
    {
      'name': 'Traditional',
      'icon': Icons.temple_hindu_rounded,
      'color': Colors.orange,
      'gradient': [Colors.orange.shade400, Colors.orange.shade600],
    },
    {
      'name': 'Business',
      'icon': Icons.business_center_rounded,
      'color': Colors.green,
      'gradient': [Colors.green.shade400, Colors.green.shade600],
    },
    {
      'name': 'Culture',
      'icon': Icons.theater_comedy_rounded,
      'color': Colors.purple,
      'gradient': [Colors.purple.shade400, Colors.purple.shade600],
    },
  ];

  // NEW: Filter options
  final List<String> timeOfDayOptions = [
    'Any time',
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
  ];

  final List<String> venueOptions = [
    'Any venue',
    'In person',
    'Online',
  ];

  final List<String> distanceOptions = [
    'Any distance',
    '5 km',
    '10 km',
    '25 km',
    '50 km',
    '100 km',
    '150 km',
  ];

  @override
  void initState() {
    super.initState();
    filteredEvents = List.from(widget.eventList);
    selectedCategories.add('All');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _applyTimeFilter('Upcoming');
  }

  @override
  void dispose() {
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // NEW: Show filter modal
  void _showFilterModal() {
    // Store current filter states for potential reset
    final tempTimeOfDay = selectedTimeOfDay;
    final tempVenue = selectedVenue;
    final tempDistance = selectedDistance;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Reset to original values and close
                            selectedTimeOfDay = tempTimeOfDay;
                            selectedVenue = tempVenue;
                            selectedDistance = tempDistance;
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Text(
                          'Filters',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedTimeOfDay = 'Any time';
                              selectedVenue = 'Any venue';
                              selectedDistance = 'Any distance';
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Time of day section
                          const Text(
                            'Time of day',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...timeOfDayOptions.map((option) {
                            final isSelected = selectedTimeOfDay == option;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedTimeOfDay = option;
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      option,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black54
                                            : Colors.black45,
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: Colors.cyan,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 32),

                          // Venue section
                          const Text(
                            'Venue',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...venueOptions.map((option) {
                            final isSelected = selectedVenue == option;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedVenue = option;
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      option,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black54
                                            : Colors.black45,
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: Colors.cyan,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 32),

                          // Distance section
                          const Text(
                            'Distance',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...distanceOptions.map((option) {
                            final isSelected = selectedDistance == option;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedDistance = option;
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      option,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black54
                                            : Colors.black45,
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: Colors.cyan,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // Apply filters button
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: () {
                        _applyAdvancedFilters();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.cyan, Colors.cyan.shade600],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Apply filters',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // NEW: Apply advanced filters
  void _applyAdvancedFilters() {
    setState(() {
      // Start with current time filtered events
      List<Map<String, dynamic>> baseEvents =
          _getEventsForTimeFilter(selectedTimeFilter);

      // Apply additional filters
      filteredEvents = baseEvents.where((event) {
        // Time of day filter
        if (selectedTimeOfDay != 'Any time') {
          if (!_matchesTimeOfDay(event['eventTime'], selectedTimeOfDay)) {
            return false;
          }
        }

        // Venue filter
        if (selectedVenue != 'Any venue') {
          if (!_matchesVenue(event['eventType'][0], selectedVenue)) {
            return false;
          }
        }

        // Distance filter
        if (selectedDistance != 'Any distance') {
          if (!_matchesDistance(event, selectedDistance)) {
            return false;
          }
        }

        // Category filter
        if (!selectedCategories.contains('All')) {
          if (event['category'] == null ||
              !(event['category'] as List)
                  .any((cat) => selectedCategories.contains(cat))) {
            return false;
          }
        }

        // Search filter
        final query = searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          final name = event['eventName']?.toString().toLowerCase() ?? '';
          if (!name.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  // NEW: Helper methods for advanced filtering
  bool _matchesTimeOfDay(String? eventTime, String timeOfDay) {
    if (eventTime == null || eventTime.isEmpty) return true;

    try {
      // Parse time (assuming format like "14:30" or "2:30 PM")
      int hour;
      if (eventTime.contains('PM') || eventTime.contains('AM')) {
        // 12-hour format
        final parts = eventTime.replaceAll(RegExp(r'[APM\s]'), '').split(':');
        hour = int.parse(parts[0]);
        if (eventTime.contains('PM') && hour != 12) hour += 12;
        if (eventTime.contains('AM') && hour == 12) hour = 0;
      } else {
        // 24-hour format
        final parts = eventTime.split(':');
        hour = int.parse(parts[0]);
      }

      switch (timeOfDay) {
        case 'Morning':
          return hour >= 6 && hour < 12;
        case 'Afternoon':
          return hour >= 12 && hour < 17;
        case 'Evening':
          return hour >= 17 && hour < 22;
        case 'Night':
          return hour >= 22 || hour < 6;
        default:
          return true;
      }
    } catch (e) {
      return true; // If parsing fails, include the event
    }
  }

  bool _matchesVenue(String? venue, String venueType) {
    if (venue == null) return true;

    final venueLower = venue.toLowerCase();
    switch (venueType) {
      case 'In person':
        return !venueLower.contains('online') &&
            !venueLower.contains('virtual') &&
            !venueLower.contains('zoom');
      case 'Online':
        return venueLower.contains("online") ||
            venueLower.contains('virtual') ||
            venueLower.contains('zoom');
      default:
        return true;
    }
  }

  bool _matchesDistance(Map<String, dynamic> event, String distance) {
    if (distance == 'Any distance') return true;

    final provider = Provider.of<LocationData>(context, listen: false);
    final evLat = event['latitude'] as double?;
    final evLng = event['longitude'] as double?;

    if (evLat == null || evLng == null) return true;

    final eventDistance = haversineDistance(
        provider.getLatitude, provider.getLongitude, evLat, evLng);

    log('my lat = ${provider.getLatitude},,,,,, evt lat == $evLat');

    final maxDistance = double.parse(distance.replaceAll(' km', ''));
    return eventDistance <= maxDistance;
  }

  void _applyTimeFilter(String timeFilter) {
    setState(() {
      selectedTimeFilter = timeFilter;
      final now = DateTime.now();

      switch (timeFilter) {
        case 'Today':
          filteredEvents = widget.eventList.where((event) {
            return _isEventToday(event['eventDate'], now);
          }).toList();
          break;

        case 'Tomorrow':
          filteredEvents = widget.eventList.where((event) {
            return _isEventTomorrow(event['eventDate'], now);
          }).toList();
          break;

        case 'Weekend':
          filteredEvents = widget.eventList.where((event) {
            return _isEventThisWeekend(event['eventDate'], now);
          }).toList();
          break;

        case 'Upcoming':
        default:
          filteredEvents = widget.eventList.where((event) {
            return _isEventUpcoming(event['eventDate'], now);
          }).toList();
          break;
      }

      // Apply advanced filters after time filter
      _applyAdvancedFilters();
    });
  }

  bool _isEventToday(String? eventDate, DateTime now) {
    if (eventDate == null || eventDate.isEmpty) return false;
    try {
      DateTime eventDateTime = _parseEventDate(eventDate);
      return eventDateTime.year == now.year &&
          eventDateTime.month == now.month &&
          eventDateTime.day == now.day;
    } catch (e) {
      return false;
    }
  }

  bool _isEventTomorrow(String? eventDate, DateTime now) {
    if (eventDate == null || eventDate.isEmpty) return false;
    try {
      DateTime eventDateTime = _parseEventDate(eventDate);
      DateTime tomorrow = now.add(const Duration(days: 1));
      return eventDateTime.year == tomorrow.year &&
          eventDateTime.month == tomorrow.month &&
          eventDateTime.day == tomorrow.day;
    } catch (e) {
      return false;
    }
  }

  bool _isEventThisWeekend(String? eventDate, DateTime now) {
    if (eventDate == null || eventDate.isEmpty) return false;
    try {
      DateTime eventDateTime = _parseEventDate(eventDate);

      DateTime saturday =
          now.add(Duration(days: DateTime.saturday - now.weekday));
      DateTime sunday = now.add(Duration(days: DateTime.sunday - now.weekday));

      if (now.weekday >= DateTime.saturday) {
        saturday = now.weekday == DateTime.saturday
            ? now
            : now.add(const Duration(days: 1));
        sunday = now.weekday == DateTime.sunday
            ? now
            : now.add(Duration(days: DateTime.sunday - now.weekday));
      }

      return (eventDateTime.year == saturday.year &&
              eventDateTime.month == saturday.month &&
              eventDateTime.day == saturday.day) ||
          (eventDateTime.year == sunday.year &&
              eventDateTime.month == sunday.month &&
              eventDateTime.day == sunday.day);
    } catch (e) {
      return false;
    }
  }

  bool _isEventUpcoming(String? eventDate, DateTime now) {
    if (eventDate == null || eventDate.isEmpty) return false;
    try {
      DateTime eventDateTime = _parseEventDate(eventDate);
      return eventDateTime.isAfter(now.subtract(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  DateTime _parseEventDate(String eventDate) {
    try {
      if (eventDate.contains(' ')) {
        final parts = eventDate.split(' ');
        final datePart = parts.length > 1 ? parts[1] : parts[0];
        return DateTime.parse(datePart);
      } else {
        return DateTime.parse(eventDate);
      }
    } catch (e) {
      log('Date parsing error for: $eventDate, Error: $e');
      rethrow;
    }
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
      filteredEvents = widget.eventList.where((event) {
        final evLat = event['latitude'] as double?;
        final evLng = event['longitude'] as double?;
        if (evLat == null || evLng == null) return false;

        final distance = haversineDistance(
            provider.getLatitude, provider.getLongitude, evLat, evLng);
        return distance <= radiusKm;
      }).toList();
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    return StatefulBuilder(
      builder: (context, setState) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Compact App Bar with Search
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 80,
                  leading: const SizedBox.shrink(),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Column(
                          children: [
                            // Compact Search Bar
                            Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 14),
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      style: const TextStyle(
                                          color: Colors.black87, fontSize: 14),
                                      decoration: const InputDecoration(
                                        hintText: 'Explore events near you',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onChanged: (query) {
                                        _applyAdvancedFilters();
                                      },
                                    ),
                                  ),
                                  // UPDATED: Filter button that opens modal
                                  GestureDetector(
                                    onTap: _showFilterModal,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 14),
                                      child: Icon(
                                        Icons.tune,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                    ),
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

                // Time Filter Tabs
                SliverToBoxAdapter(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: timeFilters.length,
                      itemBuilder: (context, index) {
                        final filter = timeFilters[index];
                        final isSelected = selectedTimeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: GestureDetector(
                            onTap: () {
                              _applyTimeFilter(filter);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? Colors.orange : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.grey[300]!,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Interactive Category Tabs
                SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: categories.map((category) {
                        final isSelected =
                            selectedCategories.contains(category['name']);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategories.clear();
                                  selectedCategories.add(category['name']);
                                  _applyAdvancedFilters();
                                });

                                _animationController.forward().then((_) {
                                  _animationController.reverse();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: isSelected ? 64 : 56,
                                      height: isSelected ? 64 : 56,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: category['gradient'],
                                              )
                                            : null,
                                        color:
                                            !isSelected ? Colors.white : null,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? (category['color'] as Color)
                                                    .withOpacity(0.4)
                                                : Colors.grey.withOpacity(0.1),
                                            blurRadius: isSelected ? 12 : 6,
                                            offset:
                                                Offset(0, isSelected ? 6 : 2),
                                          ),
                                        ],
                                      ),
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.1 : 1.0,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Icon(
                                          category['icon'],
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: isSelected ? 28 : 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        color: isSelected
                                            ? category['color']
                                            : Colors.grey[600],
                                        fontSize: isSelected ? 11 : 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      child: Text(
                                        category['name'].toString(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Event Cards
                filteredEvents.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Events found!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or search terms.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final event = filteredEvents[index];
                            final name = event['eventName'] ?? 'No Title';
                            final address = event['location'] ?? 'No Location';
                            final photoUrl = event['photo'] != null &&
                                    event['photo'].isNotEmpty
                                ? event['photo']
                                : Constants.PLACEHOLDER_IMAGE;
                            final date = event['eventDate'] ?? '';
                            final time = event['eventTime'] ?? '';

                            final peopleGoing = 50 + (index * 23) % 200;

                            return GestureDetector(
                              onTap: () {
                                Get.to(
                                  EventDetailsScreen(
                                    eventData: event,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image Section
                                    Container(
                                      height: 200,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: CachedNetworkImage(
                                                imageUrl: photoUrl is List
                                                    ? photoUrl[0] ??
                                                        Constants
                                                            .PLACEHOLDER_IMAGE
                                                    : photoUrl ??
                                                        Constants
                                                            .PLACEHOLDER_IMAGE,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.event,
                                                      color: Colors.grey,
                                                      size: 50),
                                                ),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.black
                                                          .withOpacity(0.1),
                                                      Colors.black
                                                          .withOpacity(0.7),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.share,
                                                      color: Colors.orange,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.bookmark_border,
                                                      color: Colors.orange,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              left: 16,
                                              right: 16,
                                              bottom: 16,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: const Text(
                                                        'club',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Content Section
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 80,
                                                height: 30,
                                                child: Stack(
                                                  children: [
                                                    for (int i = 0; i < 3; i++)
                                                      Positioned(
                                                        left: i * 20.0,
                                                        child: Container(
                                                          width: 30,
                                                          height: 30,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  Colors.orange,
                                                              width: 2,
                                                            ),
                                                            color: Colors
                                                                .orange[50],
                                                          ),
                                                          child: const Icon(
                                                            Icons.person,
                                                            color:
                                                                Colors.orange,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$peopleGoing going',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Interested',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "${formatEventDate(date)} • $time",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            address,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                      color: Colors.blue[200]!),
                                                ),
                                                child: Text(
                                                  'Available',
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[50],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Traditional',
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'See map',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: filteredEvents.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          floatingActionButton: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 7, right: 7),
              child: FloatingActionButton.extended(
                onPressed: () {
                  if (provider.isUserSubscribed) {
                    Get.to(() => const PostEventScreen());
                  } else {
                    _showSubscriptionDialog();
                  }
                },
                backgroundColor: Colors.orange,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Post Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getEventsForTimeFilter(String timeFilter) {
    final now = DateTime.now();

    switch (timeFilter) {
      case 'Today':
        return widget.eventList.where((event) {
          return _isEventToday(event['eventDate'], now);
        }).toList();

      case 'Tomorrow':
        return widget.eventList.where((event) {
          return _isEventTomorrow(event['eventDate'], now);
        }).toList();

      case 'Weekend':
        return widget.eventList.where((event) {
          return _isEventThisWeekend(event['eventDate'], now);
        }).toList();

      case 'Upcoming':
      default:
        return widget.eventList.where((event) {
          return _isEventUpcoming(event['eventDate'], now);
        }).toList();
    }
  }

  String formatEventDate(String inputDate) {
    try {
      final eventDateTime = _parseEventDate(inputDate);
      final formatted = '${_getWeekday(eventDateTime.weekday)}, '
          '${_getMonth(eventDateTime.month)} ${eventDateTime.day}';
      return formatted;
    } catch (e) {
      return inputDate;
    }
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[(weekday - 1) % 7];
  }

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
