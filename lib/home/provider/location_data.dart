import 'dart:developer';
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/widgets/helper.dart';

class LocationData extends ChangeNotifier {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  double _latitude = 0;
  double _longitude = 0;

  bool _isUserInAustralia = false;

  bool _isLocationFetched = false;

  // int _radiusFilter = 50; //in kms

  String _usersAddress = '';
  String _shortFormAddress = '';
  // final String _state = '';
  // final String _city = '';

  List<dynamic> _restaurauntList = [];
  List<dynamic> _groceryList = [];
  List<dynamic> _templeList = [];
  List<Map<String, dynamic>> _eventList = [];
  List<Map<String, dynamic>> _accomodationList = [];

  double get getLatitude => _latitude;
  double get getLongitude => _longitude;
  // int get getRadiusFilter => _radiusFilter;
  String get getUsersAddress => _usersAddress;
  String get getShortFormAddress => _shortFormAddress;
  // String get getState => _state;
  // String get getCity => _city;
  bool get isUserInAustralia => _isUserInAustralia;
  List<dynamic> get getRestaurauntList => _restaurauntList;
  List<dynamic> get getGroceryList => _groceryList;
  List<dynamic> get getTemplesList => _templeList;
  bool get isLocationFetched => _isLocationFetched;
  List<Map<String, dynamic>> get getEventList => _eventList;
  List<Map<String, dynamic>> get getAccomodationList => _accomodationList;

  ////////////////////////////////////////////////////

  int? _tempEventRadiusFilter; // null by default

  int? get getTempEventRadiusFilter => _tempEventRadiusFilter;

  void setTempEventRadiusFilter(int? value) {
    _tempEventRadiusFilter = value;
    notifyListeners();
  }

  /////////////////////////////////////////////////////////////

  String _nativeState = '';
  String _nativeCity = '';
  String _suburb = '';
  String _zipcode = '';
  int _nativeRadiusFilter = 50;

  String get getNativeState => _nativeState;
  String get getNativeCity => _nativeCity;
  String get getNativeSuburb => _suburb;
  String get getNativeZipcode => _zipcode;
  int get getNativeRadiusFilter => _nativeRadiusFilter;

  void setNativeLocation({
    required String state,
    required String city,
    required String suburb,
    required String zipcode,
    required int radiusFilter,
  }) {
    _nativeState = state;
    _nativeCity = city;
    _suburb = suburb;
    _zipcode = zipcode;
    _nativeRadiusFilter = radiusFilter;
    notifyListeners();
  }

////////////////////////////////////////////////////////
  void setIsLocationFetched(bool val) {
    _isLocationFetched = val;
    notifyListeners();
  }

  void setRestaurauntList(List<dynamic> list) {
    _restaurauntList = list;
    notifyListeners();
  }

  void setGroceryList(List<dynamic> list) {
    _groceryList = list;
    notifyListeners();
  }

  void setTemplessList(List<dynamic> list) {
    _templeList = list;
    notifyListeners();
  }

  void setEventList(List<Map<String, dynamic>> eventList) {
    _eventList = eventList;
    notifyListeners();
  }

  void setAccomodationList(List<Map<String, dynamic>> accomodationList) {
    _accomodationList = accomodationList;
    notifyListeners();
  }

  void setLatitudeAndLongitude(double lat, double long) {
    _latitude = lat;
    _longitude = long;
    notifyListeners();
  }

  // void setRadiusFilter(int radius) {
  //   _radiusFilter = radius;
  //   notifyListeners();
  // }

  void setUserInAustralia(bool val) {
    _isUserInAustralia = val;
    notifyListeners();
  }

  void setUserAddress(String address) {
    _usersAddress = address;
    notifyListeners();
  }

  void setStateShortForm(String shortForm) {
    _shortFormAddress = shortForm;
    notifyListeners();
  }

  Future<void> fetchUserAddressAndLocation({
    required bool isInAustralia,
  }) async {
    late DocumentSnapshot addressSnapshot1;

    if (isInAustralia) {
      addressSnapshot1 = await firestore
          .collection('currentLocation')
          .doc(auth.currentUser!.uid)
          .get();
    } else {
      addressSnapshot1 = await firestore
          .collection('nativeAddress')
          .doc(auth.currentUser!.uid)
          .get();
    }

    if (addressSnapshot1.exists) {
      Map<String, dynamic>? addressSnapshot;

      if (isInAustralia) {
        addressSnapshot = addressSnapshot1.data() as Map<String, dynamic>?;
      } else {
        addressSnapshot =
            (addressSnapshot1.data() as Map<String, dynamic>?)?['nativeAddress']
                as Map<String, dynamic>?;
      }

      if (addressSnapshot != null) {
        final city = addressSnapshot['city'] ?? '';
        _nativeCity = city;
        final state = addressSnapshot['state'] ?? '';
        _nativeState = state;
        final country = addressSnapshot['country'] ?? '';
        final zip = addressSnapshot['zipcode'] ?? '';
        final suburb = addressSnapshot['suburb'] ?? '';
        final fullAddress = '$suburb, $city, $state, $zip, $country';
        _usersAddress = fullAddress;

        final lat = addressSnapshot['latitude'] ?? '';
        final long = addressSnapshot['longitude'] ?? '';

        if (lat is double && long is double) {
          _latitude = lat;
          _longitude = long;
        } else if (lat is String && long is String) {
          _latitude = double.tryParse(lat) ?? 0.0;
          _longitude = double.tryParse(long) ?? 0.0;
        }

        final radius = addressSnapshot['radiusFilter'] ?? 50;
        if (radius is int) {
          _nativeRadiusFilter = radius;
        } else if (radius is double) {
          _nativeRadiusFilter = radius.toInt();
        }

        _shortFormAddress = '📍 $city, ${getStateShortForm(state)}';
        notifyListeners();
      } else {
        log('addressSnapshot is null or not a Map');
      }
    } else {
      log('Document does not exist');
    }
  }

  // Future<void> fetchUserAddressAndLocation1(
  //     {required bool isInAustralia}) async {
  //   dynamic addressSnapshot1;
  //   if (isInAustralia) {
  //     addressSnapshot1 = await firestore
  //         .collection('currentLocation')
  //         .doc(auth.currentUser!.uid)
  //         .get();
  //   } else {
  //     addressSnapshot1 = await firestore
  //         .collection('nativeAddress')
  //         .doc(auth.currentUser!.uid)
  //         .get();
  //   }
  //   if (addressSnapshot1.exists) {
  //     Map<String, dynamic>? addressSnapshot;
  //     if (isInAustralia) {
  //       addressSnapshot = addressSnapshot1.data() as Map<String, dynamic>?;
  //     } else {
  //       addressSnapshot =
  //           (addressSnapshot1.data() as Map<String, dynamic>?)?['nativeAddress']
  //               as Map<String, dynamic>?;
  //     }
  //     // final street = addressSnapshot.data()['Street'] ?? '';
  //     final city = addressSnapshot?['city'] ?? '';
  //     _nativeCity = city;
  //     // final town = addressSnapshot.data()['town'] ?? '';
  //     final state = addressSnapshot?['state'] ?? '';
  //     _nativeState = state;
  //     final country = addressSnapshot?['country'] ?? '';
  //     final zip = addressSnapshot?['zipcode'] ?? '';
  //     final suburb = addressSnapshot?['suburb'] ?? '';
  //     final fullAddress = '$suburb, $city, $state, $zip, $country';
  //     _usersAddress = fullAddress;
  //     final lat = addressSnapshot?['latitude'] ?? '';
  //     final long = addressSnapshot?['longitude'] ?? '';
  //     if (lat is double && long is double) {
  //       _latitude = lat;
  //       _longitude = long;
  //     } else if (lat is String && long is String) {
  //       _latitude = lat.toNum.toDouble();
  //       _longitude = long.toNum.toDouble();
  //     }
  //     final radius = addressSnapshot?['radiusFilter'] ?? 50;
  //     if (radius is int) {
  //       _radiusFilter = radius;
  //     } else if (radius is double) {
  //       _radiusFilter = radius.toInt();
  //     }
  //     _shortFormAddress = '📍 $city, ${getStateShortForm(state)}';
  //     notifyListeners();
  //   } else {
  //     log('currentLocation doesnt exists');
  //   }
  // }

  String getStateShortForm(String stateName) {
    List<String> words = stateName.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0];
    }
    return words.map((word) => word[0].toUpperCase()).join();
  }

  void setAllLocationData({
    required double lat,
    required double long,
    required String fullAddress,
    required String shortFormAddress,
    required int radiusFilter,
    required bool isLocationFetched,
  }) {
    _latitude = lat;
    _longitude = long;
    _usersAddress = fullAddress;
    _shortFormAddress = shortFormAddress;
    _nativeRadiusFilter = radiusFilter;
    _isLocationFetched = isLocationFetched;
    notifyListeners();
  }
}
