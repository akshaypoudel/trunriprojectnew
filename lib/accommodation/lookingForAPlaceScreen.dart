import 'dart:developer';
import 'dart:math' as Math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/accomodationDetailsScreen.dart';
import 'package:trunriproject/accommodation/whichYouListScreen.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'filterOptionScreen.dart';

enum ActiveFilter { none, city, radius }

class LookingForAPlaceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> accommodationList;

  const LookingForAPlaceScreen({super.key, required this.accommodationList});

  @override
  State<LookingForAPlaceScreen> createState() => _LookingForAPlaceScreenState();
}

class _LookingForAPlaceScreenState extends State<LookingForAPlaceScreen>
    with TickerProviderStateMixin {
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  final List<String> cityList = [
    'All',
    'New South Wales',
    'Victoria',
    'Queensland',
    'Western Australia',
    'South Australia',
    'Tasmania',
    'Canberra',
    'Darwin',
  ];
  final List<String> cityImages = [
    'assets/images/australia.jpg',
    'assets/images/sydney.jpg',
    'assets/images/melbourne.jpg',
    'assets/images/brisbane_river.jpg',
    'assets/images/perth_city.jpg',
    'assets/images/adelaide.jpg',
    'assets/images/tasmania.jpg',
    'assets/images/canberra.jpg',
    'assets/images/darwin.jpg',
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

  void _showFilterBottomSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: const FilterOptionScreen(),
          ),
        );
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      _applyAdvancedFilters(result);
    }
  }

  void _applyAdvancedFilters(Map<String, dynamic> filters) {
    setState(() {
      displayedList = widget.accommodationList.where((item) {
        if (filters['state'] != null &&
            filters['state'].toString().isNotEmpty &&
            item['state'] != filters['state']) {
          return false;
        }

        if (filters['city'] != null &&
            filters['city'].toString().isNotEmpty &&
            item['city'] != filters['city']) {
          return false;
        }

        if (item['price'] != null) {
          final price = double.tryParse(item['price'].toString()) ?? 0;
          if (price < filters['priceMin'] || price > filters['priceMax']) {
            return false;
          }
        }

        if (filters['singleBadRoom'] > 0 &&
            (item['singleBadRoom'] ?? 0) < filters['singleBadRoom'])
          return false;
        if (filters['doubleBadRoom'] > 0 &&
            (item['doubleBadRoom'] ?? 0) < filters['doubleBadRoom'])
          return false;
        if (filters['bathrooms'] > 0 &&
            (item['bathrooms'] ?? 0) < filters['bathrooms']) return false;
        if (filters['toilets'] > 0 &&
            (item['toilets'] ?? 0) < filters['toilets']) return false;

        bool hasAllAmenities(List<String> filterList, List<dynamic>? itemList) {
          if (filterList.isEmpty) return true;
          if (itemList == null || itemList.isEmpty) return false;
          final itemStrings = itemList.map((e) => e.toString()).toList();
          return filterList.every((element) => itemStrings.contains(element));
        }

        if (!hasAllAmenities(filters['roomAmenities'], item['roomAmenities']))
          return false;
        if (!hasAllAmenities(
            filters['propertyAmenities'], item['propertyAmenities']))
          return false;
        if (!hasAllAmenities(filters['homeRules'], item['homeRules']))
          return false;

        if (filters['isLiftAvailable'] == true) {
          if (item['isLiftAvailable'] != true) return false;
        }

        return true;
      }).toList();

      activeFilter = ActiveFilter.none;
      if (displayedList.length != widget.accommodationList.length) {
        searchController.text = "Filtered";
      }
    });
  }

  Widget _buildStyledButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isOutlined = false,
    Color? customColor,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined
              ? Colors.transparent
              : (customColor ??
                  (isPrimary ? Colors.deepOrangeAccent : cardColor)),
          foregroundColor: isOutlined
              ? (customColor ?? Colors.deepOrangeAccent)
              : (isPrimary ? cardColor : Colors.deepOrangeAccent),
          elevation: 0,
          side: isOutlined
              ? BorderSide(
                  color: customColor ?? Colors.deepOrangeAccent, width: 1.5)
              : BorderSide(color: Colors.grey.shade200, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
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
                  hintText: 'Search Accomodations',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 17,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                ),
                onChanged: (query) {
                  setState(() {
                    displayedList =
                        widget.accommodationList.where((accomodation) {
                      final name =
                          accomodation['city']?.toString().toLowerCase() ?? '';
                      return name.contains(query.toLowerCase());
                    }).toList();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStyledButton(
              text: "Filter",
              icon: Icons.tune,
              onPressed: _showFilterBottomSheet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStyledButton(
              text: showOnlyMyPost ? 'Show All' : 'My Posts',
              icon: Icons.home_outlined,
              onPressed: () {
                setState(() {
                  showOnlyMyPost = !showOnlyMyPost;
                });
                searchAccommodations();
              },
            ),
          ),
          if (selectedCityGlobal != 'Sydney' ||
              searchController.text.isNotEmpty ||
              activeFilter != ActiveFilter.none) ...[
            const SizedBox(width: 12),
            _buildStyledButton(
              text: "Clear",
              icon: Icons.clear,
              onPressed: () {
                setState(() {
                  searchController.clear();
                  selectedCityGlobal = 'Sydney';
                  selectedRadiusGlobal = 50;
                  displayedList = List.from(widget.accommodationList);
                  activeFilter = ActiveFilter.none;
                  selectedCity = 'All';
                });
              },
              isOutlined: true,
              customColor: Colors.red.shade400,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCityList() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cityList.length,
        itemBuilder: (context, index) {
          final isSelected = selectedCity == cityList[index];
          return GestureDetector(
            onTap: () => filterByCity(cityList[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(cityImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          cityList[index],
                          style: TextStyle(
                            color: cardColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccommodationCard(Map<String, dynamic> data, int index) {
    List images = data['images'] ?? [];
    String imageUrl = images.isNotEmpty ? images.first.toString() : '';

    return GestureDetector(
      onTap: () {
        Get.to(() => AccommodationDetailsScreen(accommodation: data));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // data['city'] ?? 'Unknown City',
                      data['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        data['fullAddress'] ?? 'Address not available',
                        style: const TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            "No image",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              "No accommodations found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try adjusting your search criteria",
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingFAB() {
    return Positioned(
      bottom: 16,
      right: 16,
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
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.6),
              blurRadius: 25,
              spreadRadius: 3,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const WhichYouListScreen()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 27,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Accomodations',
          style: TextStyle(
            fontSize: 21,
            // fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.location_on,
                size: 26,
                color: Colors.deepOrangeAccent,
              ),
              onPressed: () => _showLocationFilterDialog(),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              _buildActionButtonsRow(),
              _buildCityList(),
              Expanded(
                child: displayedList.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10,
                          bottom: 50,
                        ),
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: displayedList.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, index) {
                            return _buildAccommodationCard(
                                displayedList[index], index);
                          },
                        ),
                      ),
              ),
              // const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildGlowingFAB(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _applyLocationFilter(String city) {
    setState(() {
      selectedCityGlobal = city;
      final list = widget.accommodationList;
      displayedList = list.where((event) {
        final eventCity = event['city']?.toString().toLowerCase() ?? '';
        return eventCity.contains(city.toLowerCase());
      }).toList();
    });
  }

  Future<void> _applyRadiusFilter(double radiusKm) async {
    final provider = Provider.of<LocationData>(context, listen: false);
    await _preloadLatLngsIfMissing();
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
                        label: const Text(
                          'Apply Filter',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
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
