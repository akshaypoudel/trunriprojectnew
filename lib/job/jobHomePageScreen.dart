import 'dart:math' as math;
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/job/addJobScreen.dart';
import 'package:trunriproject/job/jobDetailsScreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';

enum ActiveFilter { none, city, radius }

class JobHomePageScreen extends StatefulWidget {
  const JobHomePageScreen({super.key});
  @override
  State<JobHomePageScreen> createState() => _JobHomePageScreenState();
}

class _JobHomePageScreenState extends State<JobHomePageScreen> {
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  bool showOnlyMyJobs = false;

  String selectedCityGlobal = 'Sydney';
  double selectedRadiusGlobal = 50;
  ActiveFilter activeFilter = ActiveFilter.none;

  final List<String> australianCities = [
    'Sydney',
    'Melbourne',
    'Brisbane',
    'Perth',
    'Putney',
    'Adelaide',
    'Gold Coast',
    'Canberra',
    'Hobart',
    'Darwin',
    'Newcastle',
    'Murlong',
    'Parramatta',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double? parseCoord(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Future<void> _preloadLatLngsIfMissing(List<Map<String, dynamic>> jobs) async {
    for (final item in jobs) {
      if ((item['latitude'] == null || item['longitude'] == null) &&
          (item['fullAddress'] != null)) {
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

  void _showLocationFilterDialog() {
    String selectedCity = selectedCityGlobal;
    double selectedRadius = selectedRadiusGlobal;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
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
                          setStateDialog(() {
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
                          setStateDialog(() {
                            selectedRadius = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.clear, color: Colors.red),
                        label: const Text('Cancel',
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
                          // Here, use logic like your accommodation screen:
                          final cityChanged =
                              selectedCity != selectedCityGlobal;
                          final radiusChanged =
                              selectedRadius != selectedRadiusGlobal;
                          setState(() {
                            if (cityChanged && !radiusChanged) {
                              activeFilter = ActiveFilter.city;
                              selectedCityGlobal = selectedCity;
                              selectedRadiusGlobal = selectedRadius;
                            } else if (radiusChanged && !cityChanged) {
                              activeFilter = ActiveFilter.radius;
                              selectedCityGlobal = selectedCity;
                              selectedRadiusGlobal = selectedRadius;
                            } else if (cityChanged && radiusChanged) {
                              activeFilter = ActiveFilter.city;
                              selectedCityGlobal = selectedCity;
                              selectedRadiusGlobal = selectedRadius;
                            } else if (!cityChanged && !radiusChanged) {
                              // Ask: What should happen if user changes nothing? You can keep none, or keep as is.
                              activeFilter = ActiveFilter.city;
                              selectedCityGlobal = selectedCity;
                            }
                          });
                          Navigator.pop(context);
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

  bool get _hasActiveFilter =>
      showOnlyMyJobs ||
      _searchQuery.isNotEmpty ||
      activeFilter != ActiveFilter.none;

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
              : (customColor ?? (isPrimary ? Colors.orange : Colors.white)),
          foregroundColor: isOutlined
              ? (customColor ?? Colors.orange)
              : (isPrimary ? Colors.white : Colors.orange),
          elevation: 0,
          side: isOutlined
              ? BorderSide(color: customColor ?? Colors.orange, width: 1.5)
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

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationData>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Jobs',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, size: 27, color: Colors.orange),
            onPressed: _showLocationFilterDialog,
          ),
          if (_hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () {
                setState(() {
                  showOnlyMyJobs = false;
                  searchController.clear();
                  _searchQuery = '';
                  activeFilter = ActiveFilter.none;
                  selectedCityGlobal = 'Sydney';
                  selectedRadiusGlobal = 50;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Column(
              children: [
                //search bar
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.search,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search Jobs',
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
                                _searchQuery = query.toLowerCase().trim();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildStyledButton(
                        text: 'Post a Job',
                        icon: Icons.add_circle_outline,
                        onPressed: () => Get.to(
                          () => const AddJobScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStyledButton(
                        text: showOnlyMyJobs ? 'Show All' : 'My Posts',
                        icon: Icons.list_alt,
                        onPressed: () {
                          setState(() {
                            showOnlyMyJobs = !showOnlyMyJobs;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StreamBuilder(
                  stream:
                      FirebaseFirestore.instance.collection('jobs').snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator(
                          color: Colors.orange);
                    }

                    var jobsDocs = snapshot.data!.docs;
                    // Convert to Map for filtering and optional geocode
                    List<Map<String, dynamic>> jobs = jobsDocs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    // Step 1: Text Search
                    List<Map<String, dynamic>> filtered = _searchQuery.isEmpty
                        ? jobs
                        : jobs.where((job) {
                            var position = (job['positionName'] ?? '')
                                .toString()
                                .toLowerCase();
                            return position.contains(_searchQuery);
                          }).toList();

                    // Step 2: My Posts
                    if (showOnlyMyJobs) {
                      final uid = AuthServices().getCurrentUser()!.uid;
                      filtered =
                          filtered.where((job) => job['uid'] == uid).toList();
                    }

                    // Step 3: City/Radius filter (if any)
                    if (activeFilter == ActiveFilter.city) {
                      filtered = filtered.where((job) {
                        var city = (job['city'] ?? '').toString().toLowerCase();
                        return city.contains(selectedCityGlobal.toLowerCase());
                      }).toList();
                    } else if (activeFilter == ActiveFilter.radius) {
                      final uLat = locationProvider.getLatitude;
                      final uLng = locationProvider.getLongitude;
                      // We must ensure all jobs have lat/lng before filtering.
                      // This can be slow, so show a loader via FutureBuilder.
                      return FutureBuilder(
                        future: _preloadLatLngsIfMissing(filtered),
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.orange)),
                            );
                          }
                          final filteredRadius = filtered.where((job) {
                            final lat = parseCoord(job['latitude']);
                            final lng = parseCoord(job['longitude']);
                            if (lat == null || lng == null) return false;
                            final dist = _haversine(uLat, uLng, lat, lng);
                            return dist <= selectedRadiusGlobal;
                          }).toList();
                          if (filteredRadius.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                  child: Text(
                                '😕 No matching jobs found.',
                                style:
                                    TextStyle(fontSize: 20, color: Colors.grey),
                              )),
                            );
                          }
                          return _jobList(filteredRadius);
                        },
                      );
                    }

                    if (filtered.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            '😕 No matching jobs found.',
                            style: TextStyle(fontSize: 20, color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return _jobList(filtered);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _jobList(List<Map<String, dynamic>> jobs) {
    return ListView.builder(
      itemCount: jobs.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var data = jobs[index];
        final postDate = data['postDate'] is Timestamp
            ? (data['postDate'] as Timestamp).toDate()
            : null;
        final timeAgo =
            postDate != null ? _getTimeAgo(postDate) : 'Date unknown';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['positionName'] ?? 'Position',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.bookmark_border,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['companyName'] ?? 'Company',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['city'] ?? 'Location',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      data['experience'] ?? '-',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.monetization_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      data['salary'] ?? '-',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['jobDescription'] ?? '-',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepOrange,
                            Colors.orange.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Get.to(
                          () => JobDetailsScreen(
                            data: data,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime postDate) {
    final now = DateTime.now();
    final diff = now.difference(postDate);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }
}
