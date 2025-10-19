import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trunriproject/chat_module/community/components/chat_provider.dart';
import 'package:trunriproject/currentLocation.dart';
import 'package:trunriproject/events/test.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/favourites/favourites_screen.dart';
import 'package:trunriproject/home/home_screen_visuals/custom_app_drawer.dart';
import 'package:trunriproject/home/home_screen_visuals/get_banners_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/get_categories_visuals.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_accomodation_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_events_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_grocery_stores_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_jobs_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_restauraunts_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_temples_visual.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/notificatioonScreen.dart';
import 'package:trunriproject/profile/show_address_text.dart';
import 'package:trunriproject/widgets/helper.dart';
import '../job/jobHomePageScreen.dart';
import '../temple/templeHomePageScreen.dart';
import 'Controller.dart';
import 'search_field.dart';
import 'section_title.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  static String routeName = "/home";

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController addressController = TextEditingController();

  bool isInAustralia = false;
  bool isNavigating = false;
  bool _isLoading = false;

  List<dynamic> _restaurants = [];
  List<dynamic> _groceryStores = [];
  final serviceController = Get.put(ServiceController());

  RxDouble sliderIndex = (0.0).obs;

  int currentIndex = 0;
  List<dynamic> _temples = [];
  List<String> imageUrls = [];

  String addressText = '';
  String usersLatitude = '';
  String usersLongitude = '';
  int usersRadiusFilter = 50;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Set loading state
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Step 1: Handle location source first
      await _handleLocationSource();

      // Step 2: Fetch user address and location data
      if (mounted) {
        await Provider.of<LocationData>(context, listen: false)
            .fetchUserAddressAndLocation(isInAustralia: isInAustralia);
      }

      // Step 3: Fetch address data and set initial values
      if (mounted) {
        await fetchAddressData();
      }

      // Step 4: Fetch user profile image (non-blocking)
      if (mounted) {
        Provider.of<ChatProvider>(context, listen: false)
            .fetchUserProfileImage();
      }

      // Step 5: Fetch image data for banners
      await fetchImageData();

      // All initialization complete
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Initialization error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(context, 'Failed to initialize app data');
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> fetchAddressData() async {
    final provider = Provider.of<LocationData>(context, listen: false);
    setState(() {
      addressText = provider.getUsersAddress;
      addressController.text = provider.getShortFormAddress;
      usersLatitude = provider.getLatitude.toString();
      usersLongitude = provider.getLongitude.toString();
      usersRadiusFilter = provider.getNativeRadiusFilter;
    });
  }

  void onLocationChanged(
    String address,
    int radiusFilter,
    String latitude,
    String longitude,
  ) async {
    if (isNavigating) return;
    isNavigating = true;

    try {
      Map<String, dynamic> selectedAddress = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CurrentAddress(
            isProfileScreen: true,
            savedAddress: address,
            latitude: latitude,
            longitude: longitude,
            radiusFilter: radiusFilter,
            isInAustralia: isInAustralia,
          ),
        ),
      );

      if (!mounted || selectedAddress.isEmpty) return;

      final provider = Provider.of<LocationData>(context, listen: false);

      String lat = selectedAddress['latitude'];
      String lon = selectedAddress['longitude'];
      final shortFormAddress =
          '📍 ${selectedAddress['city']}, ${provider.getStateShortForm(selectedAddress['state'])}';

      provider.setAllLocationData(
        lat: lat.toNum.toDouble(),
        long: lon.toNum.toDouble(),
        fullAddress: selectedAddress['address'],
        shortFormAddress: shortFormAddress,
        radiusFilter: selectedAddress['radiusFilter'],
        isLocationFetched: false,
      );
      if (!provider.isLocationFetched) {
        await fetchAddressData();
        _fetchAllNearbyPlaces(
          lat.toNum.toDouble(),
          lon.toNum.toDouble(),
          selectedAddress['radiusFilter'],
        );
        provider.setIsLocationFetched(true);
      }
    } catch (e) {
      log("Navigation Error: $e");
    } finally {
      isNavigating = false;
    }
  }

  Future<void> _handleLocationSource() async {
    final provider = Provider.of<LocationData>(context, listen: false);

    if (provider.getUserCountry == "Australia") {
      setState(() {
        isInAustralia = true;
      });
      _getCurrentLocation();
    } else {
      setState(() {
        isInAustralia = false;
      });
      getCurrentLocationByAddress();
    }

    // if (!isShownLocationInfoDialog) {
    //   isShownLocationInfoDialog = true;
    //   _showLocationInfoDialog(isInAustralia: isInAustralia);
    // }
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool("hasShownLocationInfoDialog") ?? false;

    if (!hasShown) {
      // Show dialog
      _showLocationInfoDialog(isInAustralia: isInAustralia);

      // Save preference so it won't show again
      await prefs.setBool("hasShownLocationInfoDialog", true);
    }
  }

  void _showLocationInfoDialog({required bool isInAustralia}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              isInAustralia
                  ? 'You are in Australia'
                  : 'You are outside Australia',
            ),
            content: Text(
              isInAustralia
                  ? 'You are in Australia. You will get all the listings (restaurants, grocery stores, events, temples, jobs, accommodations) based on your current location.'
                  : 'You are outside Australia. All listings will be shown based on your saved address. You can change your address from the profile screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> getCurrentLocationByAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await FirebaseFirestore.instance
        .collection('nativeAddress')
        .doc(uid)
        .get();

    final nativeAddress = doc.data()?['nativeAddress'];
    final lat = nativeAddress['latitude'];
    final lng = nativeAddress['longitude'];
    final radiusFilter = nativeAddress['radiusFilter'];

    double latitude = 0;
    double longitude = 0;

    if (lat is double || lng is double) {
      latitude = lat;
      longitude = lng;
    } else if (lat is String || lng is String) {
      latitude = double.parse(lat);
      longitude = double.parse(lng);
    }

    // log('final lat and log in native addr === $latitude, $longitude, $radiusFilter');

    if (radiusFilter is int) {
      await _fetchAllNearbyPlaces(latitude, longitude, radiusFilter);
    } else if (radiusFilter is double) {
      await _fetchAllNearbyPlaces(latitude, longitude, radiusFilter.toInt());
    }
  }

  Future<void> _getCurrentLocation() async {
    // bool isServiceEnabled;
    // LocationPermission permission;
    double lat = 0;
    double long = 0;

    // isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    // if (!isServiceEnabled) {
    //   //showSnackBar(context, 'Location Service Not Enabled');
    // }

    // permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   permission = await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     // showSnackBar(context, 'Location Permission Not Given.');
    //   }
    // }

    // if (permission == LocationPermission.deniedForever) {
    //   showSnackBar(
    //     context,
    //     'Location Permission is Denied Forever. Please give location permission from your phone settings.',
    //   );
    // }

    dynamic addressSnapshot = await firestore
        .collection('currentLocation')
        .doc(auth.currentUser!.uid)
        .get();

    setState(() {
      if (addressSnapshot.exists) {
        usersLatitude = addressSnapshot.data()['latitude'] ?? '';
        usersLongitude = addressSnapshot.data()['longitude'] ?? '';
        usersRadiusFilter = addressSnapshot.data()['radiusFilter'] ?? 50;
      }

      if (usersLatitude.isEmpty || usersLongitude.isEmpty) {
        //showSnackBar(context, 'Cannot Fetch Users Location Data');
        return;
      }

      serviceController.currentlat = usersLatitude.toNum.toDouble();
      serviceController.currentlong = usersLongitude.toNum.toDouble();
      lat = usersLatitude.toNum.toDouble();
      long = usersLongitude.toNum.toDouble();
    });

    await _fetchAllNearbyPlaces(lat, long, usersRadiusFilter);
  }

  Future<List<dynamic>> _fetchIndianRestaurants(
    double latitude,
    double longitude,
    int radiusFilter,
  ) async {
    List<dynamic> allResults = [];
    String? nextPageToken;

    try {
      final radiusInMeters = radiusFilter * 1000;

      do {
        String url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=restaurant&keyword=indian&key=${Constants.API_KEY}';

        if (nextPageToken != null) {
          url += '&pagetoken=$nextPageToken';
        }

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          allResults.addAll(data['results']);

          nextPageToken = data['next_page_token'];

          if (nextPageToken != null) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          log('Restaurants - HTTP Error: ${response.statusCode}');
          break;
        }
      } while (nextPageToken != null);
    } catch (e) {
      log('Restaurants fetch error: $e');
    }

    return allResults;
  }

  Future<List<dynamic>> _fetchGroceryStores(
    double latitude,
    double longitude,
    int radiusFilter,
  ) async {
    List<dynamic> allResults = [];
    String? nextPageToken;

    try {
      final radiusInMeters = radiusFilter * 1000;

      do {
        String url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=grocery_or_supermarket&keyword=indian&key=${Constants.API_KEY}';

        if (nextPageToken != null) {
          url += '&pagetoken=$nextPageToken';
        }

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          allResults.addAll(data['results']);

          nextPageToken = data['next_page_token'];

          if (nextPageToken != null) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          log('Grocery - HTTP Error: ${response.statusCode}');
          break;
        }
      } while (nextPageToken != null);
    } catch (e) {
      log('Grocery fetch error: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to Fetch Grocery Stores Data');
      }
    }

    return allResults;
  }

  Future<List<dynamic>> _fetchTemples(
    double latitude,
    double longitude,
    int radiusFilter,
  ) async {
    List<dynamic> allResults = [];
    String? nextPageToken;

    try {
      final radiusInMeters = radiusFilter * 1000;

      do {
        String url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=hindu_temple&keyword=temple&key=${Constants.API_KEY}';

        if (nextPageToken != null) {
          url += '&pagetoken=$nextPageToken';
        }

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> currentBatch = data['results'];

          // Filter temples with photos (as per your original logic)
          List<dynamic> filteredBatch = currentBatch.where((temple) {
            return temple['photos'] != null &&
                temple['photos'].isNotEmpty &&
                temple['photos'][0]['photo_reference'] != null;
          }).toList();

          allResults.addAll(filteredBatch);

          nextPageToken = data['next_page_token'];

          if (nextPageToken != null) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          log('Temples - HTTP Error: ${response.statusCode}');
          break;
        }
      } while (nextPageToken != null);
    } catch (e) {
      log('Temples fetch error: $e');
      if (mounted) {
        showSnackBar(context, 'Failed to Fetch Temples Data');
      }
    }

    return allResults;
  }

  Future<List<String>> fetchImageData() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('banners').get();

      for (var document in querySnapshot.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        String imageUrl = data['imageUrl'];
        imageUrls.add(imageUrl);
      }
    } catch (e) {
      print("Error fetching image data: $e");
    }

    return imageUrls;
  }

  Future<void> isUserinAustraliaOrNot() async {
    final provider = Provider.of<LocationData>(context, listen: false);

    if (provider.getUserCountry == "Australia") {
      isInAustralia = true;
      _getCurrentLocation();
    } else {
      isInAustralia = false;
      getCurrentLocationByAddress();
    }
  }

  Future<void> _fetchAllNearbyPlaces(
      double lat, double long, int radiusFilter) async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Fetch all data simultaneously
      final results = await Future.wait([
        _fetchIndianRestaurants(lat, long, radiusFilter),
        _fetchGroceryStores(lat, long, radiusFilter),
        _fetchTemples(lat, long, radiusFilter),
      ]);

      // Update all data in a single setState to minimize rebuilds
      if (mounted) {
        setState(() {
          _restaurants = results[0];
          _groceryStores = results[1];
          _temples = results[2];
          _isLoading = false;
        });

        // Log final counts
        // log('Final counts - Restaurants: ${_restaurants.length}, Grocery: ${_groceryStores.length}, Temples: ${_temples.length}');

        // Update providers after state is set
        final provider = Provider.of<LocationData>(context, listen: false);
        provider.setRestaurauntList(_restaurants);
        provider.setGroceryList(_groceryStores);
        provider.setTemplessList(_temples);
      }
    } catch (e) {
      log('Error fetching nearby places: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Wait for the location determination
    await isUserinAustraliaOrNot();

    // Add a small delay to ensure all state updates are complete
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationData = Provider.of<LocationData>(context, listen: false);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      // drawer: const CustomAppDrawer(),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Stack(
            children: [
              (_isLoading || _isRefreshing)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.orange),
                          const SizedBox(height: 16),
                          Text(
                            (_isRefreshing) ? 'Refreshing...' : 'Loading...',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Positioned.fill(
                      top: 140,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: RefreshIndicator(
                        backgroundColor: Colors.white,
                        color: Colors.orange,
                        onRefresh: _handleRefresh,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [],
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              const BannerWithDotsWidget(),
                              const SizedBox(height: 10),
                              GetCategoriesVisuals(
                                restaurants: _restaurants,
                                temples: _temples,
                                groceryStores: _groceryStores,
                                eventList: locationData.getEventList,
                                accomodationList:
                                    locationData.getAccomodationList,
                              ),
                              NearbyEventsVisual(isInAustralia: isInAustralia),
                              const SizedBox(height: 20),
                              NearbyRestaurauntsVisual(
                                  restaurants: _restaurants,
                                  isInAustralia: isInAustralia),
                              const SizedBox(height: 20),
                              NearbyGroceryStoresVisual(
                                groceryStores: _groceryStores,
                                isInAustralia: isInAustralia,
                              ),
                              const SizedBox(height: 20),
                              NearbyAccomodationVisual(
                                isInAustralia: isInAustralia,
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: SectionTitle(
                                  title: "Find Your Job",
                                  press: () {
                                    Get.to(const JobHomePageScreen());
                                  },
                                ),
                              ),
                              NearbyJobsVisual(isInAustralia: isInAustralia),
                              const SizedBox(height: 20),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: SectionTitle(
                                      title: (isInAustralia)
                                          ? "Near By Temples"
                                          : "Temples",
                                      press: () {
                                        Get.to(
                                          TempleHomePageScreen(
                                            templesList: _temples,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  NearbyTemplesVisual(
                                    templesList: _temples,
                                    isInAustralia: isInAustralia,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ShowAddressText(
                              controller: addressController,
                              onTap: () {
                                onLocationChanged(
                                  addressController.text,
                                  usersRadiusFilter,
                                  usersLatitude,
                                  usersLongitude,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: CircleAvatar(
                              backgroundColor: Colors.orange.shade50,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                            ),
                            onPressed: () {
                              Get.to(() => const FavouritesScreen());
                            },
                          ),
                          IconButton(
                            icon: CircleAvatar(
                              backgroundColor: Colors.orange.shade50,
                              child: const Icon(
                                Icons.notifications_sharp,
                                color: Colors.grey,
                              ),
                            ),
                            onPressed: () {
                              Get.to(() => const NotificationScreen());
                            },
                          ),
                        ],
                      ),
                      SearchField(focusNode: _focusNode),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
