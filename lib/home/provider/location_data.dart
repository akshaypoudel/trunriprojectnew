import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/widgets/helper.dart';

class LocationData extends ChangeNotifier {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  double _latitude = 0;
  double _longitude = 0;

  bool _isLocationFetched = false;

  int _radiusFilter = 50; //in kms

  String _usersAddress = '';
  String _shortFormAddress = '';
  String _state = '';
  String _city = '';

  List<dynamic> _restaurauntList = [];
  List<dynamic> _groceryList = [];
  List<dynamic> _templeList = [];
  List<Map<String, dynamic>> _eventList = [];
  List<Map<String, dynamic>> _accomodationList = [];

  double get getLatitude => _latitude;
  double get getLongitude => _longitude;
  int get getRadiusFilter => _radiusFilter;
  String get getUsersAddress => _usersAddress;
  String get getShortFormAddress => _shortFormAddress;
  String get getState => _state;
  String get getCity => _city;
  List<dynamic> get getRestaurauntList => _restaurauntList;
  List<dynamic> get getGroceryList => _groceryList;
  List<dynamic> get getTemplesList => _templeList;
  bool get isLocationFetched => _isLocationFetched;
  List<Map<String, dynamic>> get getEventList => _eventList;
  List<Map<String, dynamic>> get getAccomodationList => _accomodationList;

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

  void setRadiusFilter(int radius) {
    _radiusFilter = radius;
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

  Future<void> fetchUserAddressAndLocation() async {
    dynamic addressSnapshot = await firestore
        .collection('currentLocation')
        .doc(auth.currentUser!.uid)
        .get();

    if (addressSnapshot.exists) {
      final street = addressSnapshot.data()['Street'] ?? '';
      final city = addressSnapshot.data()['city'] ?? '';
      _city = city;
      final town = addressSnapshot.data()['town'] ?? '';
      final state = addressSnapshot.data()['state'] ?? '';
      _state = state;
      final country = addressSnapshot.data()['country'] ?? '';
      final zip = addressSnapshot.data()['zipcode'] ?? '';
      final fullAddress = '$street, $town, $city, $state, $zip, $country';
      _usersAddress = fullAddress;
      String lat = addressSnapshot.data()['latitude'] ?? '';
      String long = addressSnapshot.data()['longitude'] ?? '';
      _latitude = lat.toNum.toDouble();
      _longitude = long.toNum.toDouble();
      _radiusFilter = addressSnapshot.data()['radiusFilter'] ?? 50;

      _shortFormAddress = '📍 $city, ${getStateShortForm(state)}';

      notifyListeners();
    } else {
      log('currentLocation doesnt exists');
    }
  }

  String getStateShortForm(String stateName) {
    List<String> words = stateName.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0];
    }
    return words.map((word) => word[0].toUpperCase()).join();
  }

  void setAllLocationData({
    double? lat,
    double? long,
    String? fullAddress,
    String? shortFormAddress,
    int? radiusFilter,
    bool? isLocationFetched,
  }) {
    _latitude = lat!;
    _longitude = long!;
    _usersAddress = fullAddress!;
    _shortFormAddress = shortFormAddress!;
    _radiusFilter = radiusFilter!;
    _isLocationFetched = isLocationFetched!;
    notifyListeners();
  }
}
