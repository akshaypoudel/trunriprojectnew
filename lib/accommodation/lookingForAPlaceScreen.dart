import 'dart:developer';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/accomodationDetailsScreen.dart';
import 'package:trunriproject/accommodation/whichYouListScreen.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'filterOptionScreen.dart';

enum ActiveFilter { none, city, radius }

class LookingForAPlaceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> accommodationList;

  const LookingForAPlaceScreen({super.key, required this.accommodationList});

  @override
  State<LookingForAPlaceScreen> createState() => _LookingForAPlaceScreenState();
}

class _LookingForAPlaceScreenState extends State<LookingForAPlaceScreen> {
  final List<String> cityList = [
    'All',
    'Delhi',
    'Mumbai',
    'Bangalore',
    'Noida',
    'Kolkata',
    'Chennai',
    'Hyderabad'
  ];

  final List<String> cityImages = [
    'https://cdn.pixabay.com/photo/2019/04/07/07/52/taj-mahal-4109110_1280.jpg',
    'https://cdn.pixabay.com/photo/2022/08/19/15/21/akshardham-7397135_1280.jpg',
    'https://cdn.pixabay.com/photo/2010/11/29/india-294_1280.jpg',
    'https://cdn.pixabay.com/photo/2017/12/17/13/10/architecture-3024174_1280.jpg',
    'https://cdn.pixabay.com/photo/2023/06/08/05/36/sunset-8048741_1280.jpg',
    'https://cdn.pixabay.com/photo/2017/06/12/08/29/victoria-memorial-2394784_1280.jpg',
    'https://cdn.pixabay.com/photo/2018/05/16/10/44/chennai-3405413_1280.jpg',
    'https://cdn.pixabay.com/photo/2019/02/12/14/53/golconda-fort-3992421_1280.jpg',
  ];

  List<Map<String, dynamic>> displayedList = [];
  String? selectedCity = 'All';
  final TextEditingController searchController = TextEditingController();
  bool showOnlyMyPost = false;

  String? selectedCityGlobal = 'Sydney';
  double selectedRadiusGlobal = 50;
  ActiveFilter activeFilter = ActiveFilter.none;

  @override
  void initState() {
    super.initState();
    displayedList = widget.accommodationList;
    searchController.addListener(searchAccommodations);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterByCity(String city) {
    selectedCity = city;
    searchAccommodations();
  }

  void searchAccommodations() {
    final query = searchController.text.toLowerCase();
    final currentUserId = AuthServices().getCurrentUser()!.uid;

    setState(() {
      displayedList = widget.accommodationList.where((item) {
        final matchesCity = selectedCity == 'All' ||
            (item['state'] ?? '').toString().toLowerCase() ==
                selectedCity!.toLowerCase();

        final name = item['fullAddress']?.toString().toLowerCase() ?? '';
        final city = item['city']?.toString().toLowerCase() ?? '';
        final state = item['state']?.toString().toLowerCase() ?? '';

        final matchesSearch = name.contains(query) ||
            city.contains(query) ||
            state.contains(query);

        final matchesUser =
            !showOnlyMyPost || item['uid']?.toString() == currentUserId;

        return matchesCity && matchesSearch && matchesUser;
      }).toList();
    });
  }

  void searchAccommodations1() {
    final query = searchController.text.toLowerCase();
    setState(() {
      displayedList = widget.accommodationList.where((item) {
        final matchesCity = selectedCity == 'All' ||
            (item['state'] ?? '').toString().toLowerCase() ==
                selectedCity!.toLowerCase();

        final name = item['fullAddress']?.toString().toLowerCase() ?? '';
        final city = item['city']?.toString().toLowerCase() ?? '';
        final state = item['state']?.toString().toLowerCase() ?? '';

        final matchesSearch = name.contains(query) ||
            city.contains(query) ||
            state.contains(query);

        return matchesCity && matchesSearch;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const FilterOptionScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search accommodations...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
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
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showFilterBottomSheet,
                        icon: const Icon(Icons.filter_list),
                        label: const Text("Filter"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark),
                        label: const Text("Saved"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (selectedCityGlobal != 'Sydney' ||
                        searchController.text.isNotEmpty ||
                        activeFilter != ActiveFilter.none)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              // selectedCategories.clear();
                              selectedCityGlobal = 'Sydney';
                              selectedRadiusGlobal = 50;
                              displayedList =
                                  List.from(widget.accommodationList);
                              activeFilter = ActiveFilter.none;
                            });
                          },
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Clear\nFilters',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.red,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                // width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_home_outlined),
                                  label: const Text(
                                    'Post an Accommodation',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Get.to(() => const WhichYouListScreen());
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.home_sharp),
                                  label: Text(
                                    showOnlyMyPost ? 'Show All' : 'My Posts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showOnlyMyPost = !showOnlyMyPost;
                                    });
                                    searchAccommodations();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // SizedBox(
                        //   height: 70,
                        //   child: ListView.builder(
                        //     scrollDirection: Axis.horizontal,
                        //     itemCount: cityList.length,
                        //     itemBuilder: (context, index) {
                        //       return GestureDetector(
                        //         onTap: () => filterByCity(cityList[index]),
                        //         child: Container(
                        //           margin: const EdgeInsets.only(right: 10),
                        //           width: 80,
                        //           decoration: BoxDecoration(
                        //             borderRadius: BorderRadius.circular(12),
                        //             image: DecorationImage(
                        //               image: NetworkImage(cityImages[index]),
                        //               fit: BoxFit.cover,
                        //             ),
                        //             border: selectedCity == cityList[index]
                        //                 ? Border.all(
                        //                     color: Colors.orange, width: 2)
                        //                 : null,
                        //           ),
                        //           child: Stack(
                        //             children: [
                        //               Positioned.fill(
                        //                 child: Container(
                        //                   decoration: BoxDecoration(
                        //                     borderRadius:
                        //                         BorderRadius.circular(12),
                        //                     color: Colors.black
                        //                         .withValues(alpha: 0.4),
                        //                   ),
                        //                 ),
                        //               ),
                        //               Center(
                        //                 child: Text(
                        //                   cityList[index],
                        //                   style: const TextStyle(
                        //                     color: Colors.white,
                        //                     fontWeight: FontWeight.bold,
                        //                     fontSize: 15,
                        //                   ),
                        //                   textAlign: TextAlign.center,
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ),

                        // const SizedBox(height: 12),
                        displayedList.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Text("No accommodations found"),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedList.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemBuilder: (context, index) {
                                  final data = displayedList[index];
                                  List images = data['images'] ?? [];
                                  String imageUrl = images.isNotEmpty
                                      ? images.first.toString()
                                      : '';

                                  return GestureDetector(
                                    onTap: () {
                                      Get.to(
                                        () => AccommodationDetailsScreen(
                                          accommodation: displayedList[index],
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 2,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(14),
                                            ),
                                            child: imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: 120,
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                        child:
                                                            Text("No image")),
                                                  ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              data['city'] ?? 'Unknown City',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              data['fullAddress'] ??
                                                  'Address not available',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyLocationFilter(String city) {
    setState(() {
      selectedCityGlobal = city;
      // selectedRadiusGlobal = radius;
      final list = widget.accommodationList;
      displayedList = list.where((event) {
        final eventCity = event['city']?.toString().toLowerCase() ?? '';
        return eventCity.contains(city.toLowerCase());
      }).toList();
    });
  }

  Future<void> _applyRadiusFilter(double radiusKm) async {
    final provider = Provider.of<LocationData>(context, listen: false);
    await _preloadLatLngsIfMissing(); // ensure all items have lat/lng
    setState(() {
      selectedRadiusGlobal = radiusKm;
      displayedList = widget.accommodationList.where((accommodation) {
        final evLat = accommodation['latitude'] as double?;
        final evLng = accommodation['longitude'] as double?;
        if (evLat == null || evLng == null) return false;
        final distance = haversineDistance(
            provider.getLatitude, provider.getLongitude, evLat, evLng);
        return distance <= radiusKm;
      }).toList();
    });
  }

  Future<void> _preloadLatLngsIfMissing() async {
    for (final item in widget.accommodationList) {
      if (item['latitude'] == null || item['longitude'] == null) {
        final LatLng? coords = await _geocodeAddress(item['fullAddress']);
        if (coords != null) {
          item['latitude'] = coords.latitude;
          item['longitude'] = coords.longitude;
        }
      }
    }
  }

// This returns (latitude, longitude) for an address, or null if not found.
  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      log('Geocode failed: $e');
    }
    return null;
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
      'Newcastle',
      'Putney'
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
                            displayedList = List.from(widget.accommodationList);
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
}
