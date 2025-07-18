import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/home_screen_visuals/nearby_restauraunts_visual.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/home/resturentDetailsScreen.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
import 'package:trunriproject/job/jobDetailsScreen.dart';
import 'package:trunriproject/notificatioonScreen.dart';
import 'package:trunriproject/widgets/helper.dart';
import '../accommodation/lookingForAPlaceScreen.dart';
import '../events/eventDetailsScreen.dart';
import '../events/eventHomeScreen.dart';
import '../job/jobHomePageScreen.dart';
import '../model/bannerModel.dart';
import '../model/categoryModel.dart';
import '../temple/templeHomePageScreen.dart';
import 'Controller.dart';
import 'groceryStoreListScreen.dart';
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

  String usersLatitude = '';
  String usersLongitude = '';
  int usersRadiusFilter = 50;

  List<dynamic> _restaurants = [];
  List<dynamic> _groceryStores = [];
  final apiKey = 'AIzaSyDDl-_JOy_bj4MyQhYbKbGkZ0sfpbTZDNU';
  final serviceController = Get.put(ServiceController());

  RxDouble sliderIndex = (0.0).obs;

  int currentIndex = 0;
  String templeLat = '';
  String templeLong = '';
  List<dynamic> _temples = [];
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchImageData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locationData = Provider.of<LocationData>(context, listen: false);

    _fetchBasedOn(
      locationData.getLatitude,
      locationData.getLongitude,
      locationData.getRadiusFilter,
    );
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
      showSnackBar(context, 'Location Service Not Enabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showSnackBar(context, 'Location Permission Not Given.');
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
        showSnackBar(context, 'Cannot Fetch Users Location Data');
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
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=restaurant&keyword=indian&key=$apiKey';

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
    final radiusInMeters = radiusFilter * 1000;
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=grocery_or_supermarket&keyword=indian&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _groceryStores = data['results'];
        });
      }
    } else {
      // throw Exception('Failed to fetch data');
      showSnackBar(context, 'Failed to Fetch Grocery Stores Data');
    }
  }

  Future<void> _fetchTemples(
    double latitude,
    double longitude,
    int radiusFilter,
  ) async {
    final radiusInMeters = radiusFilter * 1000;
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radiusInMeters&type=hindu_temple&keyword=temple&key=$apiKey';

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
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              top: 70,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                    getBanners(),
                    Obx(() => DotsIndicator(
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
                        )),
                    const SizedBox(height: 10),
                    getCategoriesVisual(),
                    upcomingEventsVisual(),
                    const SizedBox(height: 20),
                    // nearbyRestarauntsVisual(),
                    NearbyRestaurauntsVisual(restaurants: _restaurants),
                    const SizedBox(height: 20),
                    nearbyGroceryStoresVisual(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionTitle(
                        title: "Near By Accommodations",
                        press: () {
                          Get.to(const LookingForAPlaceScreen());
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    nearbyAccomodationVisual(),
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
                    nearbyJobsVisual(),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SectionTitle(
                            title: "Near By Temples",
                            press: () {
                              Get.to(const TempleHomePageScreen());
                            },
                          ),
                        ),
                        nearbyTemplesVisual(),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  const Expanded(
                    child: SearchField(),
                  ),
                  // const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 13),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.orange,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget getBanners() {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error fetching products'),
          );
        }
        List<BannerModel> banner = snapshot.data!.docs.map((doc) {
          return BannerModel.fromMap(doc.id, doc.data());
        }).toList();
        final bannerLength = banner.length;

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                  viewportFraction: 1,
                  autoPlay: true,
                  onPageChanged: (value, _) {
                    sliderIndex.value = value.toDouble();
                  },
                  autoPlayCurve: Curves.ease,
                  height: height * .20),
              items: List.generate(
                  bannerLength,
                  (index) => Container(
                      width: width,
                      margin: EdgeInsets.symmetric(horizontal: width * .01),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: banner[index].imageUrl,
                          errorWidget: (_, __, ___) => const SizedBox(),
                          placeholder: (_, __) => const SizedBox(),
                          fit: BoxFit.cover,
                        ),
                      ))),
            ),
          ],
        );
      },
    );
  }

  Widget getCategoriesVisual() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error fetching products'),
          );
        }

        List<Category> category = snapshot.data!.docs.map((doc) {
          return Category.fromMap(doc.id, doc.data());
        }).toList();
        return Padding(
          padding: const EdgeInsets.only(left: 20),
          child: SizedBox(
            height: 100,
            child: CarouselSlider.builder(
              itemCount: category.length,
              itemBuilder: (context, index, realIndex) {
                return CategoryCard(
                    icon: category[index].imageUrl,
                    text: category[index].name,
                    press: () {
                      if (category[index].name == 'Temples') {
                        Get.to(const TempleHomePageScreen());
                      } else if (category[index].name == 'Grocery stores') {
                        Get.to(const GroceryStoreListScreen());
                      } else if (category[index].name == 'Accommodation') {
                        Get.to(const LookingForAPlaceScreen());
                      } else if (category[index].name == 'Restaurants') {
                        if (_restaurants.isNotEmpty) {
                          Get.to(ResturentItemListScreen(
                            restaurant_List: _restaurants,
                          ));
                        }
                      } else if (category[index].name == 'Jobs') {
                        Get.to(const JobHomePageScreen());
                      } else if (category[index].name == 'Events') {
                        Get.to(const EventDiscoveryScreen());
                      }
                    });
              },
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.2,
                enableInfiniteScroll: true,
                enlargeCenterPage: true,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget upcomingEventsVisual() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title: "Upcoming Events",
            press: () {
              Get.to(const EventDiscoveryScreen());
            },
          ),
        ),
        StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('MakeEvent').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No events available"));
            }
            var events = snapshot.data!.docs;
            return Container(
              height: 140,
              margin: const EdgeInsets.only(
                left: 20,
              ),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: CarouselSlider.builder(
                itemCount: events.length,
                itemBuilder: (context, index, realIndex) {
                  var event = events[index];
                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        EventDetailsScreen(
                          eventDate: event['eventDate'],
                          eventName: event['eventName'],
                          eventTime: event['eventTime'],
                          location: event['location'],
                          photo: event['photo'][0],
                          Price: event['ticketPrice'],
                        ),
                      );
                    },
                    child: Container(
                      width: 242,
                      margin: const EdgeInsets.only(
                        right: 10,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: event['photo'].isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: event['photo'][0],
                                height: 180,
                                width: 200,
                                fit: BoxFit.cover,
                              )
                            : Image.asset("assets/images/singing.jpeg",
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 450,
                  viewportFraction: 0.55,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayCurve: Curves.easeInOutCirc,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget nearbyRestarauntsVisual() {
    var height = MediaQuery.of(context).size.height;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title: "Near By Restaurants",
            press: () {
              Get.to(
                ResturentItemListScreen(restaurant_List: _restaurants),
              );
            },
          ),
        ),
        Container(
          height: height * .32,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = _restaurants[index];
              final name = restaurant['name'];
              final address = restaurant['vicinity'];
              final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0.0;
              final reviews = restaurant['reviews'];
              final description =
                  restaurant['description'] ?? 'No Description Available';
              final openingHours = restaurant['opening_hours'] != null
                  ? restaurant['opening_hours']['weekday_text']
                  : 'Not Available';
              final closingTime = restaurant['closing_time'] ?? 'Not Available';
              final photoReference = restaurant['photos'] != null
                  ? restaurant['photos'][0]['photo_reference']
                  : null;
              final photoUrl = photoReference != null
                  ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey'
                  : null;
              if (photoUrl == null || photoReference == null || name == null) {
                return const SizedBox.shrink();
              }
              final lat = restaurant['geometry']['location']['lat'];
              final lng = restaurant['geometry']['location']['lng'];

              return GestureDetector(
                onTap: () {
                  log('message');
                  Get.to(
                    ResturentDetailsScreen(
                      name: name.toString(),
                      rating: rating,
                      desc: description.toString(),
                      openingTime: openingHours.toString(),
                      closingTime: closingTime.toString(),
                      address: address.toString(),
                      image: photoUrl.toString(),
                    ),
                    arguments: [lat, lng],
                  );
                },
                child: Container(
                  height: 180,
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                height: 180,
                                width: 200,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          name,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          address,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget nearbyGroceryStoresVisual() {
    var height = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title: "Near By Grocery Stores",
            press: () {
              Get.to(const GroceryStoreListScreen());
            },
          ),
        ),
        Container(
          height: height * .32,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _groceryStores.length,
            itemBuilder: (context, index) {
              final groceryStore = _groceryStores[index];
              final name = groceryStore['name'];
              final address = groceryStore['vicinity'];
              final rating =
                  (groceryStore['rating'] as num?)?.toDouble() ?? 0.0;
              final description =
                  groceryStore['description'] ?? 'No Description Available';
              final openingHours = groceryStore['opening_hours'] != null
                  ? groceryStore['opening_hours']['weekday_text']
                  : 'Not Available';
              final closingTime =
                  groceryStore['closing_time'] ?? 'Not Available';
              final photoReference = groceryStore['photos'] != null
                  ? groceryStore['photos'][0]['photo_reference']
                  : null;
              final photoUrl = photoReference != null
                  ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey'
                  : null;

              if (photoUrl == null || photoReference == null || name == null) {
                return const SizedBox.shrink();
              }
              final lat = groceryStore['geometry']['location']['lat'];
              final lng = groceryStore['geometry']['location']['lng'];

              return GestureDetector(
                onTap: () {
                  Get.to(
                      ResturentDetailsScreen(
                        name: name.toString(),
                        rating: rating,
                        desc: description.toString(),
                        openingTime: openingHours.toString(),
                        closingTime: closingTime.toString(),
                        address: address.toString(),
                        image: photoUrl.toString(),
                      ),
                      arguments: [lat, lng]);
                },
                child: Container(
                  height: 180,
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                height: 180,
                                width: 200,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(),
                      ),
                      const SizedBox(
                          height:
                              10), // Add space between the image and the text
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          name,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Adjust the font size as needed
                          ),
                          // overflow: TextOverflow.ellipsis,
                          maxLines:
                              1, // Allow text to wrap to 2 lines if needed
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          address,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                            fontSize: 14, // Adjust the font size as needed
                          ),
                          // overflow: TextOverflow.ellipsis,
                          maxLines:
                              1, // Allow text to wrap to 2 lines if needed
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget nearbyAccomodationVisual() {
    var height = MediaQuery.of(context).size.height;

    return Container(
      height: height * .35,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('accommodation').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.orange,
            ));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No accommodations found'));
          }
          return ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: snapshot.data!.docs.map((DocumentSnapshot doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              List<dynamic> images;
              if (data['images'] != null) {
                images = data['images'];
              } else {
                images = [];
              }

              return Container(
                height: 180,
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: images[0],
                              height: 180,
                              width: 200,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(
                        height: 10), // Add space between the image and the text
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        "City -  ${data['city'] ?? 'No Address'}",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Adjust the font size as needed
                        ),
                        // overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Allow text to wrap to 2 lines if needed
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        "State -  ${data['state'] ?? 'No Address'}",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 14, // Adjust the font size as needed
                        ),
                        // overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Allow text to wrap to 2 lines if needed
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        "FullAddress -  ${data['fullAddress'] ?? 'No Address'}",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 14, // Adjust the font size as needed
                        ),
                        // overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Allow text to wrap to 2 lines if needed
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget nearbyJobsVisual1() {
    var height = MediaQuery.of(context).size.height;

    return Container(
      height: height * .16,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.orange,
            ));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No jobs found'));
          }
          return ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: snapshot.data!.docs.map((DocumentSnapshot doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              List<dynamic> images = data['images'] ?? [];

              return Container(
                height: 180,
                width: 200,
                margin: const EdgeInsets.only(right: 10, left: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Name - ${data['companyName'] ?? 'No companyName'}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12, // Adjust the font size as needed
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines:
                                2, // Allow text to wrap to 2 lines if needed
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Department - ${data['department'] ?? 'No department'}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12, // Adjust the font size as needed
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines:
                                2, // Allow text to wrap to 2 lines if needed
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Education - ${data['eduction'] ?? 'No education'}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12, // Adjust the font size as needed
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines:
                                2, // Allow text to wrap to 2 lines if needed
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "EmploymentType - ${data['employmentType'] ?? 'No employmentType'}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12, // Adjust the font size as needed
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines:
                                2, // Allow text to wrap to 2 lines if needed
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget nearbyTemplesVisual() {
    var height = MediaQuery.of(context).size.height;
    return Container(
      height: height * .32,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _temples.length,
        itemBuilder: (context, index) {
          final temples = _temples[index];
          final name = temples['name'];
          final address = temples['vicinity'];
          final rating = (temples['rating'] as num?)?.toDouble() ?? 0.0;
          final reviews = temples['reviews'];
          final description =
              temples['description'] ?? 'No Description Available';
          final openingHours = temples['opening_hours'] != null
              ? temples['opening_hours']['weekday_text']
              : 'Not Available';
          final closingTime = temples['closing_time'] ?? 'Not Available';
          final photoReference = temples['photos'] != null
              ? temples['photos'][0]['photo_reference']
              : temples['photos'][1]['photo_reference'];
          final photoUrl = photoReference != null
              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=35000&photoreference=$photoReference&key=$apiKey'
              : null;

          if (photoUrl == null || photoReference == null || name == null) {
            return const SizedBox.shrink();
          }

          final lat = temples['geometry']['location']['lat'];
          final lng = temples['geometry']['location']['lng'];

          // final resturentLat = lat.toString();
          // final resturentlong = lng.toString();

          return GestureDetector(
            onTap: () {
              log('message');
              Get.to(
                ResturentDetailsScreen(
                  name: name.toString(),
                  rating: rating,
                  desc: description.toString(),
                  openingTime: openingHours.toString(),
                  closingTime: closingTime.toString(),
                  address: address.toString(),
                  image: photoUrl.toString(),
                ),
                arguments: [lat, lng],
              );
            },
            child: Container(
              height: 180,
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(11)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            height: 180,
                            width: 200,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                  ),
                  const SizedBox(
                      height: 10), // Add space between the image and the text
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      name,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Adjust the font size as needed
                      ),
                      // overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Allow text to wrap to 2 lines if needed
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      address,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w300,
                        fontSize: 14, // Adjust the font size as needed
                      ),
                      // overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Allow text to wrap to 2 lines if needed
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget nearbyJobsVisual() {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: height * 0.25,
      width: width,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No jobs found'));
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    buildInfoRow(
                      icon: Icons.business,
                      label: "Company:",
                      value: data['companyName'] ?? 'No company name',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    buildInfoRow(
                      icon: Icons.badge,
                      label: "Position:",
                      value: data['positionName'] ?? 'No Position Mentioned',
                      color: Colors.red,
                    ),
                    // const SizedBox(height: 12),
                    // buildInfoRow(
                    //   icon: Icons.account_tree_outlined,
                    //   label: "Department:",
                    //   value: data['department'] ?? 'No department',
                    //   color: Colors.blueGrey,
                    // ),
                    const SizedBox(height: 12),
                    buildInfoRow(
                      icon: Icons.school,
                      label: "Education:",
                      value: data['eduction'] ?? 'No education',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    buildInfoRow(
                      icon: Icons.work_outline,
                      label: "Employment Type:",
                      value: data['employmentType'] ?? 'No employment type',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(JobDetailsScreen(data: data));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          elevation: 15,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

// Helper widget for cleaner rows with labels
  Widget buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.icon,
    required this.text,
    required this.press,
  });

  final String icon, text;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECDF),
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(icon),
                fit: BoxFit.fill,
              ),
            ),
          ),
          const SizedBox(height: 4), // Add space between the image and the text
          Container(
            margin: const EdgeInsets.only(right: 10),
            width: 56, // Adjust width if needed
            child: Text(
              text.toString().capitalize ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10, // Adjust the font size as needed
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow text to wrap to 2 lines if needed
            ),
          ),
        ],
      ),
    );
  }
}

class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({
    super.key,
    required this.category,
    required this.image,
    required this.numOfBrands,
    required this.press,
  });

  final String category, image;
  final int numOfBrands;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: GestureDetector(
        onTap: press,
        child: SizedBox(
          width: 242,
          height: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.asset(
                  image,
                  fit: BoxFit.fitWidth,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.black38,
                        Colors.black26,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: "$category\n",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: "$numOfBrands Days")
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
}
