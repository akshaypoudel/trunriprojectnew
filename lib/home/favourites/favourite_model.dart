// favourite_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum FavouriteType {
  events,
  jobs,
  accommodation,
  restaurants,
  grocery,
  temples,
}

extension FavouriteTypeExtension on FavouriteType {
  String get displayName {
    switch (this) {
      case FavouriteType.events:
        return 'Events';
      case FavouriteType.restaurants:
        return 'Restaurants';
      case FavouriteType.grocery:
        return 'Grocery';
      case FavouriteType.temples:
        return 'Temples';
      case FavouriteType.jobs:
        return 'Jobs';
      case FavouriteType.accommodation:
        return 'Accommodation';
    }
  }

  String get emoji {
    switch (this) {
      case FavouriteType.events:
        return '🎉';
      case FavouriteType.restaurants:
        return '🍽️';
      case FavouriteType.grocery:
        return '🛒';
      case FavouriteType.temples:
        return '🕉️';
      case FavouriteType.jobs:
        return '💼';
      case FavouriteType.accommodation:
        return '🏠';
    }
  }

  String get collectionName {
    switch (this) {
      case FavouriteType.events:
        return 'MakeEvent';
      case FavouriteType.jobs:
        return 'jobs';
      case FavouriteType.accommodation:
        return 'accommodation';
      case FavouriteType.restaurants:
        return 'restaurants';
      case FavouriteType.grocery:
        return 'grocery';
      case FavouriteType.temples:
        return 'temples';
    }
  }

  String getIdFieldName() {
    switch (this) {
      case FavouriteType.jobs:
        return 'postID';
      case FavouriteType.accommodation:
        return 'formID'; // or whatever field name you use
      case FavouriteType.events:
        return 'eventId'; // or whatever field name you use
      case FavouriteType.restaurants:
        return 'id';
      case FavouriteType.temples:
        return 'id';
      case FavouriteType.grocery:
        return 'id';
    }
  }

  bool get isDirectStorage {
    switch (this) {
      case FavouriteType.restaurants:
      case FavouriteType.grocery:
      case FavouriteType.temples:
        return true;
      case FavouriteType.events:
      case FavouriteType.jobs:
      case FavouriteType.accommodation:
        return false;
    }
  }
}

class FavouriteItem {
  final String id;
  final String name;
  final String location;
  final FavouriteType type;
  final DateTime addedAt;
  final String? imageUrl;
  final Map<String, dynamic>? extraData;

  FavouriteItem({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.addedAt,
    this.imageUrl,
    this.extraData,
  });

  factory FavouriteItem.fromFirestoreDoc(
    String id,
    Map<String, dynamic> data,
    FavouriteType type,
    DateTime addedAt,
  ) {
    switch (type) {
      case FavouriteType.events:
        return FavouriteItem(
          id: id,
          name: data['eventName'] ?? 'Unknown Event',
          location: data['location'] ?? 'Unknown Location',
          type: type,
          addedAt: addedAt,
          imageUrl: data['photo'][0],
          extraData: data,
        );

      case FavouriteType.jobs:
        return FavouriteItem(
          id: id,
          name: data['positionName'] ?? data['name'] ?? 'Unknown Job',
          location: data['fullAddress'] ?? 'Unknown Location',
          type: type,
          addedAt: addedAt,
          // imageUrl: data['imageUrl'] ?? data['companyLogo'],
          extraData: data,
        );

      case FavouriteType.accommodation:
        return FavouriteItem(
          id: id,
          name: data['name'] ?? data['title'] ?? 'Unknown Accommodation',
          location: data['fullAddress'] ?? 'Unknown Location',
          type: type,
          addedAt: addedAt,
          imageUrl: data['imageUrl'] ?? data['images']?[0],
          extraData: data,
        );

      case FavouriteType.restaurants:
      case FavouriteType.grocery:
      case FavouriteType.temples:
        return FavouriteItem(
          id: id,
          name: data['name'] ?? 'Unknown Item',
          location: data['location'] ?? data['address'] ?? 'Unknown Location',
          type: type,
          addedAt: addedAt,
          imageUrl: data['imageUrl'] ?? data['image'],
          extraData: data,
        );
    }
  }

  factory FavouriteItem.fromStoredData(
    Map<String, dynamic> savedData,
    FavouriteType type,
  ) {
    final addedAtData = savedData['addedAt'];
    DateTime addedAt;

    if (addedAtData is Timestamp) {
      addedAt = addedAtData.toDate();
    } else if (addedAtData is DateTime) {
      addedAt = addedAtData;
    } else {
      addedAt = DateTime.now();
    }

    return FavouriteItem(
      id: savedData['id'] ?? '',
      name: savedData['name'] ?? 'Unknown Item',
      location:
          savedData['location'] ?? savedData['address'] ?? 'Unknown Location',
      type: type,
      addedAt: addedAt,
      imageUrl: savedData['imageUrl'] ?? savedData['image'],
      extraData: savedData['extraData'] ?? savedData,
    );
  }

  String get subtitle {
    switch (type) {
      case FavouriteType.events:
        final date = extraData?['eventDate'];
        final time = extraData?['eventTime'];
        if (date != null && time != null) {
          return '$date at $time';
        }
        return location;

      case FavouriteType.jobs:
        final company = extraData?['company'];
        if (company != null) {
          return '$company • $location';
        }
        return location;

      case FavouriteType.accommodation:
        final price = extraData?['price'];
        final type = extraData?['type'];
        if (price != null && type != null) {
          return '$type • ₹$price • $location';
        }
        return location;

      default:
        return location;
    }
  }

  Map<String, dynamic> get fullData {
    switch (type) {
      case FavouriteType.restaurants:
      case FavouriteType.grocery:
      case FavouriteType.temples:
        return {
          'name': name,
          'rating': extraData?['rating'] ?? 0.0,
          'desc': extraData?['description'] ?? extraData?['desc'] ?? '',
          'openingTime': extraData?['openingTime'] ?? '',
          'closingTime': extraData?['closingTime'] ?? '',
          'address': location,
          'image': imageUrl ?? '',
          'isOpenNow': extraData?['isOpenNow'] ?? false,
          ...?extraData,
        };
      default:
        return extraData ?? {};
    }
  }

  // Generate unique ID for restaurants, grocery, temples
  static String generateId(String name, String address) {
    return '${name}_$address'
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w]'), '_')
        .toLowerCase();
  }
}
