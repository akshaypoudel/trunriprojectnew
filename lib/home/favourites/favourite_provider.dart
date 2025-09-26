// favourite_provider.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:trunriproject/home/favourites/favourites_service.dart';
import 'favourite_model.dart';

class FavouritesProvider extends ChangeNotifier {
  final FavouritesService _service = FavouritesService();
  Map<FavouriteType, List<FavouriteItem>> _favourites = {};
  bool _isLoading = false;

  // Cache to store recent database check results to avoid repeated calls
  final Map<String, bool> _statusCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(seconds: 30);

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

  // MAIN FIX: Always check database first, with smart caching
  Future<bool> isFavouriteLocal(String itemId, FavouriteType type) async {
    final cacheKey = '${itemId}_${type.toString()}';
    final now = DateTime.now();

    // Check if we have a recent cached result
    if (_statusCache.containsKey(cacheKey) &&
        _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (now.difference(cacheTime) < _cacheValidDuration) {
        log('🔍 Using cached result for $itemId: ${_statusCache[cacheKey]}');
        return _statusCache[cacheKey]!;
      }
    }

    // Check database directly
    log('🔍 Checking database for $itemId...');
    final isInDatabase = await _service.isFavourite(itemId, type);

    // Update cache
    _statusCache[cacheKey] = isInDatabase;
    _cacheTimestamps[cacheKey] = now;

    // Sync local cache with database state
    if (isInDatabase) {
      // Add to local cache if not present
      _favourites[type] ??= [];
      final exists = _favourites[type]!.any((item) => item.id == itemId);
      if (!exists) {
        final basicItem = FavouriteItem(
          id: itemId,
          name: type == FavouriteType.events
              ? 'Event'
              : type == FavouriteType.jobs
                  ? 'Job'
                  : 'Item',
          location: 'Loading...',
          type: type,
          addedAt: DateTime.now(),
        );
        _favourites[type]!.add(basicItem);
        log('🔍 Added $itemId to local cache from database check');
      }
    } else {
      // Remove from local cache if it exists but not in database
      final removed =
          _favourites[type]?.removeWhere((item) => item.id == itemId);
    }

    log('🔍 Database check result for $itemId: $isInDatabase');
    return isInDatabase;
  }

  // Keep old method name for compatibility, but make it synchronous cache-only check
  bool isFavouriteFromCache(String itemId, FavouriteType type) {
    final items = _favourites[type] ?? [];
    return items.any((item) => item.id == itemId);
  }

  // Clear cache when favorites are modified
  void _clearStatusCache() {
    _statusCache.clear();
    _cacheTimestamps.clear();
    log('🔍 Status cache cleared');
  }

  void _clearStatusCacheForItem(String itemId, FavouriteType type) {
    final cacheKey = '${itemId}_${type.toString()}';
    _statusCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }

  // Updated addToFavourites with better duplicate prevention
  Future<bool> addToFavourites(String itemId, FavouriteType type) async {
    log('🔍 addToFavourites called: $itemId, $type');

    // Clear cache for this item before checking
    _clearStatusCacheForItem(itemId, type);

    // Check if already exists in database first
    final alreadyExists = await _service.isFavourite(itemId, type);
    if (alreadyExists) {
      log('⚠️ Item $itemId already in database, skipping add');

      // Update local cache to match database
      _favourites[type] ??= [];
      final existsInCache = _favourites[type]!.any((item) => item.id == itemId);
      if (!existsInCache) {
        final basicItem = FavouriteItem(
          id: itemId,
          name: type == FavouriteType.events
              ? 'Event'
              : type == FavouriteType.jobs
                  ? 'Job'
                  : 'Item',
          location: 'Loading...',
          type: type,
          addedAt: DateTime.now(),
        );
        _favourites[type]!.add(basicItem);
        notifyListeners();
      }

      return true;
    }

    // Add to database
    final success = await _service.addToFavourites(itemId, type);
    log('🔍 Service addToFavourites result: $success');

    if (success) {
      // Update cache to reflect successful add
      _statusCache['${itemId}_${type.toString()}'] = true;
      _cacheTimestamps['${itemId}_${type.toString()}'] = DateTime.now();

      // Add to local cache
      _favourites[type] ??= [];
      final exists = _favourites[type]!.any((item) => item.id == itemId);
      if (!exists) {
        final basicItem = FavouriteItem(
          id: itemId,
          name: type == FavouriteType.events
              ? 'Event'
              : type == FavouriteType.jobs
                  ? 'Job'
                  : 'Item',
          location: 'Loading...',
          type: type,
          addedAt: DateTime.now(),
        );

        _favourites[type]!.add(basicItem);
        log('🔍 Added $itemId to local cache. Count: ${_favourites[type]!.length}');
        notifyListeners();
      }
    }

    return success;
  }

  // Updated removeFromFavourites with cache clearing
  Future<bool> removeFromFavourites(String itemId, FavouriteType type) async {
    log('🔍 removeFromFavourites called: $itemId, $type');

    // Clear cache for this item
    _clearStatusCacheForItem(itemId, type);

    // Remove from database first
    final success = await _service.removeFromFavourites(itemId, type);
    log('🔍 Service removeFromFavourites result: $success');

    if (success) {
      // Update cache to reflect successful removal
      _statusCache['${itemId}_${type.toString()}'] = false;
      _cacheTimestamps['${itemId}_${type.toString()}'] = DateTime.now();

      // Remove from local cache
      final initialCount = _favourites[type]?.length ?? 0;
      _favourites[type]?.removeWhere((item) => item.id == itemId);
      final newCount = _favourites[type]?.length ?? 0;

      log('🔍 Removed from local cache. Count: $initialCount -> $newCount');
      notifyListeners();
    }

    return success;
  }

  // Add to favourites with complete data (for restaurants, grocery, temples)
  Future<bool> addToFavouritesWithData(FavouriteItem item) async {
    log('🔍 addToFavouritesWithData called: ${item.name}, ${item.type}');

    // Clear cache for this item
    _clearStatusCacheForItem(item.id, item.type);

    final success = await _service.addToFavouritesWithCompleteData(item);

    if (success) {
      // Update cache
      _statusCache['${item.id}_${item.type.toString()}'] = true;
      _cacheTimestamps['${item.id}_${item.type.toString()}'] = DateTime.now();

      // Update local cache immediately
      _favourites[item.type] ??= [];

      // Remove existing item if any, then add new one
      _favourites[item.type]!
          .removeWhere((existingItem) => existingItem.id == item.id);
      _favourites[item.type]!.add(item);

      notifyListeners();
    }

    return success;
  }

  // Toggle favourite status
  Future<bool> toggleFavourite(String itemId, FavouriteType type,
      {FavouriteItem? itemData}) async {
    // Use database check instead of cache check
    final isCurrentlyFav = await isFavouriteLocal(itemId, type);

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

  // Fetch all favourites - clears cache since we're getting fresh data
  Future<void> fetchFavourites() async {
    log('🔍 fetchFavourites called');
    _isLoading = true;
    notifyListeners();

    try {
      _favourites = await _service.fetchAllFavourites();

      // Clear status cache since we have fresh data
      _clearStatusCache();

      log('🔍 Fetched $totalFavouritesCount favorites successfully');
    } catch (e) {
      log('❌ Error fetching favourites: $e');
      _favourites = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Real-time check (kept for backward compatibility)
  Future<bool> isFavouriteRealTime(String itemId, FavouriteType type) async {
    return await isFavouriteLocal(itemId, type);
  }

  // Force refresh a specific item
  Future<void> refreshFavoriteStatus(String itemId, FavouriteType type) async {
    log('🔍 refreshFavoriteStatus called: $itemId, $type');

    // Clear cache for this item to force fresh check
    _clearStatusCacheForItem(itemId, type);

    // Check database directly
    final isActuallyFavorite = await _service.isFavourite(itemId, type);

    if (isActuallyFavorite) {
      // Add to local cache if it's missing
      if (!isFavouriteFromCache(itemId, type)) {
        final basicItem = FavouriteItem(
          id: itemId,
          name: type == FavouriteType.events
              ? 'Event'
              : type == FavouriteType.jobs
                  ? 'Job'
                  : 'Item',
          location: 'Loading...',
          type: type,
          addedAt: DateTime.now(),
        );

        _favourites[type] ??= [];
        _favourites[type]!.add(basicItem);
        notifyListeners();
        log('🔍 Added $itemId to local cache from refresh');
      }
    } else {
      // Remove from local cache if it shouldn't be there
      _favourites[type]?.removeWhere((item) => item.id == itemId);
      notifyListeners();
      log('🔍 Removed $itemId from local cache from refresh');
    }

    // Update cache with fresh result
    _statusCache['${itemId}_${type.toString()}'] = isActuallyFavorite;
    _cacheTimestamps['${itemId}_${type.toString()}'] = DateTime.now();
  }

  // Clear all favourites
  Future<void> clearAllFavourites() async {
    _favourites.clear();
    _clearStatusCache();
    notifyListeners();
  }

  // Clear favourites by type
  Future<void> clearFavouritesByType(FavouriteType type) async {
    _favourites[type]?.clear();

    // Clear cache entries for this type
    final keysToRemove = _statusCache.keys
        .where((key) => key.endsWith('_${type.toString()}'))
        .toList();

    for (String key in keysToRemove) {
      _statusCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    notifyListeners();
  }

  // Force clear all caches (useful for debugging)
  void clearAllCaches() {
    _clearStatusCache();
    notifyListeners();
  }
}
