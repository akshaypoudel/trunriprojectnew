// favourite_service.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'favourite_model.dart';

class FavouritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId {
    final uid = _auth.currentUser?.uid;
    log('🔍 Current User ID: $uid');
    return uid;
  }

  // Add item to favourites (handles both direct storage and ID-only storage)
  Future<bool> addToFavourites(String itemId, FavouriteType type) async {
    try {
      log('🔍 Adding to favourites - ItemID: $itemId, Type: $type');

      if (currentUserId == null) {
        log('❌ currentUserId is null - user not authenticated');
        return false;
      }

      final docRef = _firestore.collection('favourites').doc(currentUserId);
      final typeField = type.toString().split('.').last;

      final favouriteData = {'id': itemId, 'addedAt': Timestamp.now()};

      await docRef.set({
        typeField: FieldValue.arrayUnion([favouriteData])
      }, SetOptions(merge: true));

      log('✅ Successfully added $itemId to $typeField');
      return true;
    } catch (e) {
      log('❌ Error adding to favourites: $e');
      return false;
    }
  }

  // Add item with complete data (for restaurants, grocery, temples)
  Future<bool> addToFavouritesWithCompleteData(FavouriteItem item) async {
    try {
      log('🔍 Adding complete data to favourites - Name: ${item.name}, Type: ${item.type}');

      if (currentUserId == null) {
        log('❌ currentUserId is null - user not authenticated');
        return false;
      }

      final docRef = _firestore.collection('favourites').doc(currentUserId);
      final typeField = item.type.toString().split('.').last;

      final favouriteData = {
        'id': item.id,
        'name': item.name,
        'location': item.location,
        'imageUrl': item.imageUrl,
        'addedAt': Timestamp.now(),
        'extraData': item.extraData ?? {},
      };

      await docRef.set({
        typeField: FieldValue.arrayUnion([favouriteData])
      }, SetOptions(merge: true));

      log('✅ Successfully added ${item.name} with complete data to $typeField');
      return true;
    } catch (e) {
      log('❌ Error adding complete data to favourites: $e');
      return false;
    }
  }

  // Remove item from favourites
  Future<bool> removeFromFavourites(String itemId, FavouriteType type) async {
    try {
      log('🔍 Removing from favourites - ItemID: $itemId, Type: $type');

      if (currentUserId == null) {
        log('❌ currentUserId is null');
        return false;
      }

      final docRef = _firestore.collection('favourites').doc(currentUserId);

      final doc = await docRef.get();
      if (!doc.exists) {
        log('🔍 Favourites document does not exist');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final typeField = type.toString().split('.').last;
      final List<dynamic> currentItems = data[typeField] ?? [];

      final updatedItems = currentItems.where((item) {
        return item['id'] != itemId;
      }).toList();

      await docRef.update({
        typeField: updatedItems,
      });

      log('✅ Successfully removed $itemId from $typeField');
      return true;
    } catch (e) {
      log('❌ Error removing from favourites: $e');
      return false;
    }
  }

  // Check if item is in favourites
  Future<bool> isFavourite(String itemId, FavouriteType type) async {
    try {
      if (currentUserId == null) return false;

      final doc =
          await _firestore.collection('favourites').doc(currentUserId).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final typeField = type.toString().split('.').last;
      final List<dynamic> items = data[typeField] ?? [];

      final result = items.any((item) => item['id'] == itemId);
      log('🔍 isFavourite($itemId, $type) = $result');
      return result;
    } catch (e) {
      log('❌ Error checking favourite status: $e');
      return false;
    }
  }

  // Fetch all favourites with their complete data
  Future<Map<FavouriteType, List<FavouriteItem>>> fetchAllFavourites() async {
    try {
      log('🔍 Starting fetchAllFavourites...');

      if (currentUserId == null) {
        log('❌ currentUserId is null - user not authenticated');
        return {};
      }

      final favDoc =
          await _firestore.collection('favourites').doc(currentUserId).get();

      if (!favDoc.exists) {
        log('🔍 No favourites document found');
        return {};
      }

      final favData = favDoc.data() as Map<String, dynamic>;
      final Map<FavouriteType, List<FavouriteItem>> favourites = {};

      for (FavouriteType type in FavouriteType.values) {
        final typeField = type.toString().split('.').last;
        final List<dynamic> savedItems = favData[typeField] ?? [];
        final List<FavouriteItem> favouriteItems = [];

        log('🔍 Processing ${type.displayName} ($typeField): ${savedItems.length} saved items');

        for (var savedItem in savedItems) {
          final String itemId = savedItem['id'];

          try {
            if (type.isDirectStorage) {
              // For restaurants, grocery, temples - data is stored directly
              final favouriteItem =
                  FavouriteItem.fromStoredData(savedItem, type);
              favouriteItems.add(favouriteItem);
              log('✅ Added direct storage item: ${favouriteItem.name}');
            } else {
              // For events, jobs, accommodation - fetch from respective collections
              final collectionName = type.collectionName;
              final queryFieldName = type.getIdFieldName();

              final querySnapshot = await _firestore
                  .collection(collectionName)
                  .where(queryFieldName, isEqualTo: itemId)
                  .limit(1)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                final itemDoc = querySnapshot.docs.first;
                final itemData = itemDoc.data();
                final documentId = itemDoc.id;

                final addedAtData = savedItem['addedAt'];
                DateTime addedAt;
                if (addedAtData is Timestamp) {
                  addedAt = addedAtData.toDate();
                } else if (addedAtData is DateTime) {
                  addedAt = addedAtData;
                } else {
                  addedAt = DateTime.now();
                }

                final favouriteItem = FavouriteItem.fromFirestoreDoc(
                  documentId,
                  itemData,
                  type,
                  addedAt,
                );
                favouriteItems.add(favouriteItem);
                log('✅ Added fetched item: ${favouriteItem.name}');
              } else {
                log('⚠️ Item $itemId not found in collection $collectionName');
              }
            }
          } catch (e) {
            log('❌ Error processing item $itemId: $e');
            continue;
          }
        }

        favourites[type] = favouriteItems;
        log('🔍 Final count for ${type.displayName}: ${favouriteItems.length} items');
      }

      log('✅ fetchAllFavourites completed');
      return favourites;
    } catch (e) {
      log('❌ Error in fetchAllFavourites: $e');
      return {};
    }
  }
}
