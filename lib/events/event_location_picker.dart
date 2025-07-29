import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:trunriproject/home/constants.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  void onLocationPicked(
    double lat,
    double lng,
    String address,
    String city,
    String state,
  ) {
    Navigator.pop(context, {
      'lat': lat,
      'lng': lng,
      'address': address,
      'city': city,
      'state': state,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: MapLocationPicker(
        config: MapLocationPickerConfig(
          apiKey: Constants.API_KEY,
          initialMapType: MapType.normal,
          zoomControlsEnabled: true,
          liteModeEnabled: false,
          initialPosition: const LatLng(-33.8568, 151.2153),
          onNext: (result) {
            onLocationPicked(
              result!.geometry.location.lat,
              result.geometry.location.lng,
              result.formattedAddress!,
              getCity(result.addressComponents)!,
              getState(result.addressComponents)!,
            );
          },
        ),
      ),
    );
  }

  String? getCity(List<AddressComponent> components) {
    for (final c in components) {
      if (c.types.contains('locality')) {
        return c.longName;
      }
    }
    return null;
  }

  String? getState(List<AddressComponent> components) {
    for (final c in components) {
      if (c.types.contains('administrative_area_level_1')) {
        return c.longName;
      }
    }
    return null;
  }
}
