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

  // String googleApikey = "AIzaSyAP9njE_z7lH2tii68WLoQGju0DF8KryXA";
  CameraPosition? cameraPosition;
  String location = "Enter Your Address Here";
  final Set<Marker> markers = {};
  final String appLanguage = "English";
  String latitude1 = '';
  String longitude1 = '';
  int? radiusFilter;

  Future<bool> _handleLocationPermission() async {
    radiusFilter = widget.radiusFilter;
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
      // radiusFilter =

      if (widget.isProfileScreen) {
        if (widget.latitude.isNotEmpty && widget.longitude.isNotEmpty) {
          lat = widget.latitude.toNum.toDouble();
          long = widget.longitude.toNum.toDouble();
        }
        // lat = latlng[0];
        // long = latlng[1];
      }
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, long),
            zoom: 15,
          ),
        ),
      );
      _onAddMarkerButtonPressed(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        "current location",
      );
      //setState(() {});
      // location = _currentAddress!;
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

  void addCurrentLocation() {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);
    FirebaseFirestore.instance
        .collection('currentLocation')
        .doc(FirebaseAuth.instance.currentUser!.uid)
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
    }).then((value) {
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
            // 'Street': street,
            'nativeAddress': {
              'city': city,
              'state': state,
              'country': country,
              'zipcode': zipcode,
              // 'town': town,
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

  Future<void> _onAddMarkerButtonPressed(LatLng lastMapPosition, markerTitle,
      {allowZoomIn = true}) async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/icons/location.png', 140);
    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId(lastMapPosition.toString()),
        position: lastMapPosition,
        infoWindow: const InfoWindow(
          title: "",
        ),
        icon: BitmapDescriptor.bytes(markerIcon),
      ),
    );
    // BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan,)));
    if (googleMapController.isCompleted) {
      mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: lastMapPosition, zoom: allowZoomIn ? 14 : 11)));
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getCurrentPosition();
    });
  }

  @override
  void dispose() {
    mapController!.dispose();

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
        body: Stack(
          children: [
            GoogleMap(
                zoomGesturesEnabled: true,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 14.0, //initial zoom level
                ),
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  mapController = controller;
                  //setState(() async {});
                },
                // markers: markers,
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
                      longitude1 = cameraPosition!.target.longitude.toString();
                    });

                    if (placemarks.isEmpty) {
                      // No address found at this location; hide address in UI
                      setState(() {
                        _address = "";
                        fullAddress = "";
                        street = city = state = country = zipcode = town = null;
                      });
                      // You may show a snackbar or other feedback here if desired
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

                    // Validate required fields (customize as needed)
                    if (!hasPostal || !hasCity || !hasState || !hasCountry) {
                      setState(() {
                        _address = "";
                        fullAddress = "";
                        street = city = state = country = zipcode = town = null;
                      });
                      // Optionally show a message/snackbar for the user
                      // showSnackBar(context, "Complete address not available at this location");
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
                  } catch (error) {
                    // Handle all errors gracefully (network, permissions, etc.)
                    setState(() {
                      _address = "";
                      fullAddress = "";
                      street = city = state = country = zipcode = town = null;
                    });
                    // Optionally log or show error feedback to the user
                    // log("Reverse geocoding failed: $error");
                    // showSnackBar(context, "Could not retrieve address for this position");
                  }
                }),
            const Center(
              child: Text(
                '📍',
                style: TextStyle(fontSize: 45),
              ),
            ),
            Positioned(
              top: 10,
              child: InkWell(
                onTap: () async {
                  var place = await PlacesAutocomplete.show(
                      context: context,
                      apiKey: Constants.API_KEY,
                      mode: Mode.overlay,
                      types: [],
                      strictbounds: false,
                      // components: [
                      //   Component(Component.country, appLanguage == "French" ? "fr" : appLanguage == "Spanish"?"es": appLanguage == "Arabic"?"ar":appLanguage == "English"?"en":"en")
                      // ],
                      onError: (err) {
                        log("error.....   ${err.errorMessage}");
                      });
                  if (place != null) {
                    setState(() {
                      _address = place.description.toString();
                      // final a = place.description.
                    });
                    final plist = GoogleMapsPlaces(
                      apiKey: Constants.API_KEY,
                      apiHeaders: await const GoogleApiHeaders().getHeaders(),
                    );
                    //print(plist);
                    String placeid = place.placeId ?? "0";
                    final detail = await plist.getDetailsByPlaceId(placeid);
                    final geometry = detail.result.geometry!;
                    final lat = geometry.location.lat;
                    final lang = geometry.location.lng;
                    var newlatlang = LatLng(lat, lang);
                    setState(() {
                      _address = place.description.toString();

                      _onAddMarkerButtonPressed(
                          LatLng(lat, lang), place.description);
                    });
                    mapController?.animateCamera(CameraUpdate.newCameraPosition(
                        CameraPosition(target: newlatlang, zoom: 17)));
                    setState(() {});

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
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 15, top: 35),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new_outlined,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Card(
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.all(0),
                              width: MediaQuery.of(context).size.width - 50,
                              child: ListTile(
                                leading: const Icon(Icons.location_on_outlined,
                                    color: AppTheme.primaryColor),
                                title: Text(
                                  'Search For Locations',
                                  // _address.toString(),
                                  style: TextStyle(fontSize: AddSize.font14),
                                ),
                                trailing: IconButton(
                                  onPressed: _showFilterDialog,
                                  icon: const Icon(
                                    Icons.filter_list,
                                  ),
                                ),
                                dense: true,
                              )),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: AppTheme.primaryColor,
                                      size: AddSize.size25,
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
                                    // Expanded(
                                    //   child: GestureDetector(
                                    //     onTap: () {
                                    //       showSnackBar(context,
                                    //           'Your Location save Successfully');
                                    //     },
                                    //     child: Text(
                                    //       'Save Location',
                                    //       style: Theme.of(context)
                                    //           .textTheme
                                    //           .headlineSmall!
                                    //           .copyWith(
                                    //               fontWeight: FontWeight.w600,
                                    //               fontSize: AddSize.font16,
                                    //               color: const Color(0xff014E70)),
                                    //     ),
                                    //   ),
                                    // )
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
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFF730A),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Confirm Your Address",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          fontSize: 20,
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
    );
  }

  void _showFilterDialog() {
    int? selectedRadius = radiusFilter;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            '📍 Radius Filter',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose how far (in km) you want to search from your location.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [1, 5, 10, 25, 50, 100].map((km) {
                        return RadioListTile<int>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('$km km'),
                          value: km,
                          groupValue: selectedRadius,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (int? value) {
                            if (value != null) {
                              Navigator.of(context).pop();
                              setState(() {
                                radiusFilter = value;
                              });
                              showSnackBar(
                                context,
                                'Radius set to ${value.toString()}km',
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
