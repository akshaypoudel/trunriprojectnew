import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/home_screen_visuals/get_banners_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/get_categories_visuals.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_accomodation_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_events_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_grocery_stores_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_jobs_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_restauraunts_visual.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_temples_visual.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/widgets/helper.dart';
import '../accommodation/lookingForAPlaceScreen.dart';
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

  String usersLatitude = '';
  String usersLongitude = '';
  int usersRadiusFilter = 50;

  List<dynamic> _restaurants = [];
  List<dynamic> _groceryStores = [];
  final serviceController = Get.put(ServiceController());

  RxDouble sliderIndex = (0.0).obs;

  int currentIndex = 0;
  List<dynamic> _temples = [];
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchImageData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _fetchBasedOn(
    double lat,
    double long,
    int radiusFilter,
  ) {
    serviceController.currentlat = lat;
    serviceController.currentlong = long;

    _fetchIndianRestaurants(lat, long, radiusFilter);
    _fetchGroceryStores(lat, long, radiusFilter);
    _fetchTemples(lat, long, radiusFilter);
  }

  Future<void> _getCurrentLocation() async {
    bool isServiceEnabled;
    LocationPermission permission;
    double lat = 0;
    double long = 0;

    isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isServiceEnabled) {
      //showSnackBar(context, 'Location Service Not Enabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // showSnackBar(context, 'Location Permission Not Given.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showSnackBar(
        context,
        'Location Permission is Denied Forever. Can\'t Access Location',
      );
    }

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

    _fetchIndianRestaurants(lat, long, usersRadiusFilter);
    _fetchGroceryStores(lat, long, usersRadiusFilter);
    _fetchTemples(lat, long, usersRadiusFilter);
  }

  Future<void> _fetchIndianRestaurants(
    double latitude,
    double longitude,
    int radiusFilter,
  ) async {
    final provider = Provider.of<LocationData>(context, listen: false);
    final radiusInMeters = radiusFilter * 1000;
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=restaurant&keyword=indian&key=${Constants.API_KEY}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _restaurants = data['results'];
        provider.setRestaurauntList(_restaurants);
      });
    } else {
      // throw Exception('Failed to fetch data');
      showSnackBar(context, 'Failed to Fetch Restauraunt Data');
    }
  }

  Future<void> _fetchGroceryStores(
    double latitude,
    double longitude,
    int radiusFilter,
  ) async {
    final provider = Provider.of<LocationData>(context, listen: false);

    final radiusInMeters = radiusFilter * 1000;
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=grocery_or_supermarket&keyword=indian&key=${Constants.API_KEY}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _groceryStores = data['results'];
          provider.setGroceryList(_groceryStores);
        });
      }
    } else {
      showSnackBar(context, 'Failed to Fetch Grocery Stores Data');
    }
  }

  Future<void> _fetchTemples(
    double latitude,
    double longitude,
    int radiusFilter,
  ) async {
    final provider = Provider.of<LocationData>(context, listen: false);

    final radiusInMeters = radiusFilter * 1000;
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=hindu_temple&keyword=temple&key=${Constants.API_KEY}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _temples = data['results'];
          _temples = _temples.where((temple) {
            return temple['photos'] != null &&
                temple['photos'][0]['photo_reference'] != null;
          }).toList();
          provider.setTemplessList(_temples);
        });
      }
    } else {
      // throw Exception('Failed to fetch data');
      showSnackBar(context, 'Failed to Fetch Temples Data');
    }
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

  @override
  Widget build(BuildContext context) {
    final locationData = Provider.of<LocationData>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!locationData.isLocationFetched) {
        _fetchBasedOn(
          locationData.getLatitude,
          locationData.getLongitude,
          locationData.getRadiusFilter,
        );
        locationData.setIsLocationFetched(true);
      }
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Stack(
            children: [
              Positioned.fill(
                top: 90,
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    _getCurrentLocation();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        GetBannersVisual(
                          onPageChanged: (value, _) {
                            sliderIndex.value = value.toDouble();
                          },
                        ),
                        Obx(
                          () => DotsIndicator(
                            dotsCount: 3,
                            position: sliderIndex.value.toInt(),
                            decorator: DotsDecorator(
                              activeColor: Colors.orange,
                              size: const Size.square(8.0),
                              activeSize: const Size(18.0, 8.0),
                              activeShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GetCategoriesVisuals(
                          restaurants: _restaurants,
                          temples: _temples,
                          groceryStores: _groceryStores,
                          eventList: locationData.getEventList,
                          accomodationList: locationData.getAccomodationList,
                        ),
                        const NearbyEventsVisual(),
                        const SizedBox(height: 20),
                        NearbyRestaurauntsVisual(restaurants: _restaurants),
                        const SizedBox(height: 20),
                        NearbyGroceryStoresVisual(
                          groceryStores: _groceryStores,
                        ),
                        const SizedBox(height: 20),
                        const NearbyAccomodationVisual(),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SectionTitle(
                            title: "Find Your Job",
                            press: () {
                              Get.to(const JobHomePageScreen());
                            },
                          ),
                        ),
                        const NearbyJobsVisual(),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: SectionTitle(
                                title: "Near By Temples",
                                press: () {
                                  Get.to(
                                    TempleHomePageScreen(
                                      templesList: _temples,
                                    ),
                                  );
                                },
                              ),
                            ),
                            NearbyTemplesVisual(templesList: _temples),
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
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(focusNode: _focusNode),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
