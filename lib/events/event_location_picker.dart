import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/constants.dart';
import 'package:trunriproject/home/provider/location_data.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  double initialLat = 0;
  double initialLong = 0;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LocationData>(context, listen: false);
      initialLat = provider.getLatitude;
      initialLong = provider.getLongitude;
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
          initialPosition: (initialLong != 0 && initialLong != 0)
              ? LatLng(initialLat, initialLong)
              : const LatLng(-33.8568, 151.2153),
          onNext: (result) {
            onLocationPicked(
              result!.geometry!.location.lat,
              result.geometry!.location.lng,
              result.formattedAddress!,
              getCity(result.addressComponents!)!,
              getState(result.addressComponents!)!,
            );
          },
        ),
      ),
    );
  }

  String? getCity(List<AddressComponent> components) {
    for (final c in components) {
      if (c.types!.contains('locality')) {
        return c.longName;
      }
    }
    return null;
  }

  String? getState(List<AddressComponent> components) {
    for (final c in components) {
      if (c.types!.contains('administrative_area_level_1')) {
        return c.longName;
      }
    }
    return null;
  }
}
