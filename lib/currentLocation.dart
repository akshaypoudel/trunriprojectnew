import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart'
    hide Location;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/visaTypeScreen.dart';
import 'package:trunriproject/widgets/addSize.dart';
import 'package:trunriproject/widgets/appTheme.dart';
import 'package:trunriproject/widgets/helper.dart';

class CurrentAddress extends StatefulWidget {
  const CurrentAddress({
    super.key,
    required this.isProfileScreen,
    required this.savedAddress,
    required this.latitude,
    required this.longitude,
    required this.radiusFilter,
    this.isInAustralia,
  });
  final bool isProfileScreen;
  final String savedAddress;
  final String latitude;
  final String longitude;
  final int radiusFilter;
  final bool? isInAustralia;
  static var chooseAddressScreen = "/chooseAddressScreen";

  @override
  State<CurrentAddress> createState() => _CurrentAddressState();
}

class _CurrentAddressState extends State<CurrentAddress> {
  final Completer<GoogleMapController> googleMapController = Completer();
  GoogleMapController? mapController;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _address = "";
  String? fullAddress = "";
  Position? _currentPosition;

  String? street, city, state, country, zipcode, town;
  String suburb = '';

  CameraPosition? cameraPosition;
  String location = "Enter Your Address Here";
  // final Set<Marker> markers = {};
  final Set<Circle> circles = {}; // Added for radius circle
  final String appLanguage = "English";
  String latitude1 = '';
  String longitude1 = '';
  int? radiusFilter;
  double sliderValue = 25.0; // Added slider value

  // Calculate zoom level based on radius
  double _getZoomLevel(double radius) {
    if (radius <= 1) return 14.0;
    if (radius <= 5) return 13.0;
    if (radius <= 10) return 11.5;
    if (radius <= 25) return 10.0;
    if (radius <= 50) return 9.0;
    return 8.0;
  }

  // Update map zoom and circle based on radius
  void _updateMapRadius(double radius) {
    if (latitude1.isNotEmpty &&
        longitude1.isNotEmpty &&
        mapController != null) {
      final zoom = _getZoomLevel(radius);

      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(double.parse(latitude1), double.parse(longitude1)),
            zoom: zoom,
          ),
        ),
      );

      _updateRadiusCircle(radius);
    }
  }

  // Update the radius circle on map
  void _updateRadiusCircle(double radius) {
    if (latitude1.isNotEmpty && longitude1.isNotEmpty) {
      circles.clear();
      circles.add(
        Circle(
          circleId: const CircleId('radius_circle'),
          center: LatLng(double.parse(latitude1), double.parse(longitude1)),
          radius: radius * 1000, // Convert km to meters
          fillColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          strokeColor: AppTheme.primaryColor,
          strokeWidth: 2,
        ),
      );
      setState(() {});
    }
  }

  Future<bool> _handleLocationPermission() async {
    radiusFilter = widget.radiusFilter;
    sliderValue = widget.radiusFilter.toDouble(); // Initialize slider
    bool isServiceEnabled;
    LocationPermission permission;

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

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);

      double lat = _currentPosition!.latitude;
      double long = _currentPosition!.longitude;
      latitude1 = _currentPosition!.latitude.toString();
      longitude1 = _currentPosition!.longitude.toString();

      if (widget.isProfileScreen) {
        if (widget.latitude.isNotEmpty && widget.longitude.isNotEmpty) {
          lat = widget.latitude.toNum.toDouble();
          long = widget.longitude.toNum.toDouble();
          latitude1 = widget.latitude;
          longitude1 = widget.longitude;
        }
      }

      final zoom = _getZoomLevel(sliderValue);
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, long),
            zoom: zoom,
          ),
        ),
      );
      // _onAddMarkerButtonPressed(
      //   LatLng(double.parse(latitude1), double.parse(longitude1)),
      //   "current location",
      // );

      // Add initial radius circle
      _updateRadiusCircle(sliderValue);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];

      setState(() {
        street = placemark.street ?? '';
        city = placemark.locality ?? '';
        state = placemark.administrativeArea ?? '';
        country = placemark.country ?? '';
        zipcode = placemark.postalCode ?? '';
        town = placemark.subAdministrativeArea ?? '';
        fullAddress = '$street, $town, $city, $state, $zipcode';
      });
    }
    await placemarkFromCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    ).then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        if (widget.isProfileScreen) {
          _address = widget.savedAddress;
        } else {
          _address = fullAddress;
        }
        latitude1 = _currentPosition!.latitude.toString();
        longitude1 = _currentPosition!.longitude.toString();
      });
    }).catchError((e) {
      debugPrint(e.toString());
    });
  }

  void addCurrentLocation() async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('User').doc(uid).set({
      'city': city,
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance
        .collection('currentLocation')
        .doc(uid)
        .set({
      'Street': street,
      'city': city,
      'state': state,
      'country': country,
      'zipcode': zipcode,
      'town': town,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'latitude': latitude1,
      'longitude': longitude1,
      'radiusFilter': radiusFilter,
    }, SetOptions(merge: true)).then((value) {
      showSnackBar(context, 'Current Location Save Successfully');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const VisaTypeScreen(),
        ),
        (Route<dynamic> route) => false,
      );
      NewHelper.hideLoader(loader);
    });
  }

  Future<void> updateCurrentLocation({required bool isInAustralia}) async {
    if (_address == widget.savedAddress &&
        radiusFilter == widget.radiusFilter) {
      Navigator.pop(context);
      return;
    }

    String fullAddress = '';
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    final user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('User').doc(user.uid).set({
      'city': city,
    }, SetOptions(merge: true));

    DocumentReference<Map<String, dynamic>> userRef;
    if (isInAustralia) {
      userRef = _firestore.collection('currentLocation').doc(user.uid);
    } else {
      userRef = _firestore.collection('nativeAddress').doc(user.uid);
    }

    try {
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        if (isInAustralia) {
          await userRef.update({
            'Street': street,
            'city': city,
            'state': state,
            'country': country,
            'zipcode': zipcode,
            'town': town,
            'latitude': latitude1,
            'longitude': longitude1,
            'radiusFilter': radiusFilter,
          });
        } else {
          await userRef.update({
            'nativeAddress': {
              'city': city,
              'state': state,
              'country': country,
              'zipcode': zipcode,
              'latitude': latitude1,
              'longitude': longitude1,
              'radiusFilter': radiusFilter,
            }
          });
        }

        fullAddress = '$town, $city, $state, $zipcode, $country';

        if (isInAustralia) {
          showSnackBar(context, 'Current Location Updated Successfully');
        } else {
          showSnackBar(context, 'Location Updated Successfully');
        }

        Navigator.pop(context, {
          'state': state,
          'city': city,
          'address': fullAddress,
          'latitude': latitude1,
          'longitude': longitude1,
          'radiusFilter': radiusFilter,
        });
        NewHelper.hideLoader(loader);
      } else {
        log('Document doesnot exist');
      }
    } catch (e) {
      log("error in the update method ===== ${e.toString()}");
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  // Future<void> _onAddMarkerButtonPressed(LatLng lastMapPosition, markerTitle,
  //     {allowZoomIn = true}) async {
  //   final Uint8List markerIcon =
  //       await getBytesFromAsset('assets/icons/location.png', 140);
  //   markers.clear();
  //   markers.add(
  //     Marker(
  //       markerId: MarkerId(lastMapPosition.toString()),
  //       position: lastMapPosition,
  //       infoWindow: const InfoWindow(
  //         title: "",
  //       ),
  //       icon: BitmapDescriptor.bytes(markerIcon),
  //     ),
  //   );
  //   if (googleMapController.isCompleted) {
  //     final zoom = _getZoomLevel(sliderValue);
  //     mapController!.animateCamera(CameraUpdate.newCameraPosition(
  //         CameraPosition(
  //             target: lastMapPosition, zoom: allowZoomIn ? zoom : 11)));
  //   }
  //   setState(() {});
  // }

  @override
  void initState() {
    super.initState();
    radiusFilter = widget.radiusFilter;
    sliderValue = widget.radiusFilter.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getCurrentPosition();
    });
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus!.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          title: InkWell(
            onTap: () async {
              var place = await PlacesAutocomplete.show(
                  context: context,
                  apiKey: Constants.API_KEY,
                  mode: Mode.overlay,
                  types: [],
                  strictbounds: false,
                  onError: (err) {
                    log("error.....   ${err.errorMessage}");
                  });
              if (place != null) {
                setState(() {
                  _address = place.description.toString();
                });
                final plist = GoogleMapsPlaces(
                  apiKey: Constants.API_KEY,
                  apiHeaders: await const GoogleApiHeaders().getHeaders(),
                );
                String placeid = place.placeId ?? "0";
                final detail = await plist.getDetailsByPlaceId(placeid);
                final geometry = detail.result.geometry!;
                final lat = geometry.location.lat;
                final lang = geometry.location.lng;
                var newlatlang = LatLng(lat, lang);
                setState(() {
                  _address = place.description.toString();
                  latitude1 = lat.toString();
                  longitude1 = lang.toString();
                  // _onAddMarkerButtonPressed(
                  //     LatLng(lat, lang), place.description);
                });

                final zoom = _getZoomLevel(sliderValue);
                mapController?.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(target: newlatlang, zoom: zoom)));

                List<Placemark> placemarks =
                    await placemarkFromCoordinates(lat, lang);
                Placemark placemark = placemarks.first;
                setState(() {
                  street = placemark.street ?? '';
                  city = placemark.locality ?? '';
                  state = placemark.administrativeArea ?? '';
                  country = placemark.country ?? '';
                  zipcode = placemark.postalCode ?? '';
                  town = placemark.subAdministrativeArea ?? '';
                  fullAddress =
                      '$street, $town, $city, $state, $zipcode, $country';
                  _address = fullAddress;
                });

                // Update circle for new location
                _updateRadiusCircle(sliderValue);
              }
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search For Locations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.my_location,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          titleSpacing: 8,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              GoogleMap(
                  zoomGesturesEnabled: true,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0, 0),
                    zoom: 14.0,
                  ),
                  mapType: MapType.normal,
                  onMapCreated: (controller) {
                    mapController = controller;
                    googleMapController.complete(controller);
                  },
                  //markers: markers,
                  circles: circles,
                  onCameraMove: (CameraPosition cameraPositions) {
                    cameraPosition = cameraPositions;
                  },
                  onCameraIdle: () async {
                    if (cameraPosition == null) return;

                    try {
                      final placemarks = await placemarkFromCoordinates(
                        cameraPosition!.target.latitude,
                        cameraPosition!.target.longitude,
                      );
                      setState(() {
                        latitude1 = cameraPosition!.target.latitude.toString();
                        longitude1 =
                            cameraPosition!.target.longitude.toString();
                      });

                      if (placemarks.isEmpty) {
                        setState(() {
                          _address = "";
                          fullAddress = "";
                          street =
                              city = state = country = zipcode = town = null;
                        });
                        return;
                      }

                      final placemark = placemarks.first;
                      final hasPostal = placemark.postalCode != null &&
                          placemark.postalCode!.isNotEmpty;
                      final hasCity = placemark.locality != null &&
                          placemark.locality!.isNotEmpty;
                      final hasState = placemark.administrativeArea != null &&
                          placemark.administrativeArea!.isNotEmpty;
                      final hasCountry = placemark.country != null &&
                          placemark.country!.isNotEmpty;

                      if (!hasPostal || !hasCity || !hasState || !hasCountry) {
                        setState(() {
                          _address = "";
                          fullAddress = "";
                          street =
                              city = state = country = zipcode = town = null;
                        });
                        return;
                      }

                      final localStreet = placemark.street ?? '';
                      final localTown = placemark.subAdministrativeArea ?? '';
                      final localCity = placemark.locality ?? '';
                      final localState = placemark.administrativeArea ?? '';
                      final localZip = placemark.postalCode ?? '';
                      final localCountry = placemark.country ?? '';
                      final composedAddress =
                          '$localStreet, $localTown, $localCity, $localState, $localZip, $localCountry';

                      setState(() {
                        street = localStreet;
                        city = localCity;
                        state = localState;
                        country = localCountry;
                        zipcode = localZip;
                        town = localTown;
                        fullAddress = composedAddress;
                        _address = composedAddress;
                      });

                      // Update circle when location changes
                      _updateRadiusCircle(sliderValue);
                    } catch (error) {
                      setState(() {
                        _address = "";
                        fullAddress = "";
                        street = city = state = country = zipcode = town = null;
                      });
                    }
                  }),
              const Center(
                child: Text(
                  '📍',
                  style: TextStyle(fontSize: 45),
                ),
              ),

              // Radius Slider (moved up since search bar is now in AppBar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 70, // Slightly taller to accommodate ruler
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        8), // Minimal rounding for rectangle
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.2),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Slider section
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.orange,
                            inactiveTrackColor:
                                Colors.orange.withValues(alpha: 0.2),
                            thumbColor: Colors.orange,
                            overlayColor: Colors.orange.withValues(alpha: 0.1),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(
                            value: sliderValue,
                            min: 1.0,
                            max: 100.0,
                            divisions: 33, // 33 divisions (1-100 range)
                            onChanged: (double value) {
                              setState(() {
                                sliderValue = value;
                                radiusFilter = value.round();
                              });
                              _updateMapRadius(value);
                            },
                          ),
                        ),
                      ),
                      // const SizedBox(height: 8),
                      // Ruler markings
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildRulerMark('1 km'),
                            _buildRulerMark('25'),
                            _buildRulerMark('50'),
                            _buildRulerMark('75'),
                            _buildRulerMark('100 km'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Address Container
              Positioned(
                  bottom: 0,
                  child: Container(
                    height: AddSize.size200,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AddSize.padding16,
                        vertical: AddSize.padding10,
                      ),
                      child: Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        height: 170,
                        width: Get.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: (_address!.isEmpty)
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(
                                        width: AddSize.size12,
                                      ),
                                      Expanded(
                                        child: Text(
                                          _address.toString(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall!
                                              .copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: AddSize.font16),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.isProfileScreen) {
                                        updateCurrentLocation(
                                            isInAustralia:
                                                widget.isInAustralia ?? false);
                                      } else {
                                        addCurrentLocation();
                                      }
                                      log('full address = $fullAddress');
                                      log('address = $_address');
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          left: 25, right: 25),
                                      width: size.width,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xffFF730A),
                                            Color(0xffFF8A2B),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xffFF730A)
                                                .withValues(alpha: 0.3),
                                            spreadRadius: 0,
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Confirm Your Address",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulerMark(String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 1,
          height: 4,
          color: Colors.orange.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
