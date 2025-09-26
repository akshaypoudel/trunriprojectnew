// favourite_provider.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:trunriproject/home/favourites/favourites_service.dart';
import 'favourite_model.dart';

class FavouritesProvider extends ChangeNotifier {
  final FavouritesService _service = FavouritesService();
  Map<FavouriteType, List<FavouriteItem>> _favourites = {};
  bool _isLoading = false;

  // Getters
  bool get isLoading => _isLoading;
  Map<FavouriteType, List<FavouriteItem>> get favourites => _favourites;

  int get totalFavouritesCount {
    return _favourites.values.fold(0, (sum, list) => sum + list.length);
  }

  int get categoriesWithItemsCount {
    return _favourites.values.where((list) => list.isNotEmpty).length;
  }

  List<FavouriteItem> getFavouritesByType(FavouriteType type) {
    return _favourites[type] ?? [];
  }

  // Check if item is favourite (local check)
  bool isFavouriteLocal(String itemId, FavouriteType type) {
    final items = _favourites[type] ?? [];
    log('favourite typeee item 111#####  ======  $items');
    return items.any((item) => item.id == itemId);
  }

  // Add to favourites with complete data (for restaurants, grocery, temples)
  Future<bool> addToFavouritesWithData(FavouriteItem item) async {
    final success = await _service.addToFavouritesWithCompleteData(item);

    if (success) {
      // Update local cache immediately
      _favourites[item.type] ??= [];
      _favourites[item.type]!.add(item);
      notifyListeners();
    }

    return success;
  }

  // Toggle favourite status
  Future<bool> toggleFavourite(String itemId, FavouriteType type,
      {FavouriteItem? itemData}) async {
    final isCurrentlyFav = isFavouriteLocal(itemId, type);

    if (isCurrentlyFav) {
      return await removeFromFavourites(itemId, type);
    } else {
      if (type.isDirectStorage && itemData != null) {
        return await addToFavouritesWithData(itemData);
      } else {
        return await addToFavourites(itemId, type);
      }
    }
  }

  // Fetch all favourites
  Future<void> fetchFavourites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favourites = await _service.fetchAllFavourites();
    } catch (e) {
      log('Error fetching favourites: $e');
      _favourites = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all favourites
  Future<void> clearAllFavourites() async {
    // Implementation for clearing all favourites
    _favourites.clear();
    notifyListeners();
  }

  // Clear favourites by type
  Future<void> clearFavouritesByType(FavouriteType type) async {
    // Implementation for clearing favourites by type
    _favourites[type]?.clear();
    notifyListeners();
  }

/////////////////////////////////////////////////////////////////////////////////////////////////

// In FavouritesProvider - Updated removeFromFavourites
  Future<bool> removeFromFavourites(String itemId, FavouriteType type) async {
    // Remove from local cache immediately for instant UI feedback
    _favourites[type]?.removeWhere((item) => item.id == itemId);
    notifyListeners(); // This triggers UI update immediately

    // Then remove from Firestore
    final success = await _service.removeFromFavourites(itemId, type);

    if (!success) {
      // If failed, refresh to get the actual state
      await fetchFavourites();
    }

    return success;
  }

// In FavouritesProvider - Updated addToFavourites
  Future<bool> addToFavourites(String itemId, FavouriteType type) async {
    final success = await _service.addToFavourites(itemId, type);

    if (success) {
      // Add to local cache immediately
      _favourites[type] ??= [];

      // Check if already exists to avoid duplicates
      final exists = _favourites[type]!.any((item) => item.id == itemId);
      if (!exists) {
        final basicItem = FavouriteItem(
          id: itemId,
          name: 'Event',
          location: 'Loading...',
          type: type,
          addedAt: DateTime.now(),
        );

        _favourites[type]!.add(basicItem);
        notifyListeners(); // This triggers UI update immediately
      }
    }

    return success;
  }

  Future<bool> isFavouriteRealTime(String itemId, FavouriteType type) async {
    // First check local cache
    final localCheck = isFavouriteLocal(itemId, type);
    if (localCheck) return true;

    // If not in local cache, check Firestore directly
    return await _service.isFavourite(itemId, type);
  }

// Also add this method to force refresh a specific item
  Future<void> refreshFavoriteStatus(String itemId, FavouriteType type) async {
    final isActuallyFavorite = await _service.isFavourite(itemId, type);

    if (isActuallyFavorite) {
      // Add to local cache if it's missing
      if (!isFavouriteLocal(itemId, type)) {
        // Create a basic item for the cache
        final basicItem = FavouriteItem(
          id: itemId,
          name: 'Event',
          location: 'Location',
          type: type,
          addedAt: DateTime.now(),
        );

        _favourites[type] ??= [];
        _favourites[type]!.add(basicItem);
        notifyListeners();
      }
    } else {
      // Remove from local cache if it shouldn't be there
      _favourites[type]?.removeWhere((item) => item.id == itemId);
      notifyListeners();
    }
  }
}
