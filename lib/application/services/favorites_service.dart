/// Favorites computation service — P4ME-20 (S13).
///
/// Computes which restaurants qualify as favorites based on visit history,
/// composite scores, return intent, and manual pin/unpin overrides.
///
/// Favorites are computed on-demand from Visit data (AC-2), not stored separately.

import 'package:plated4me/domain/entities/entities.dart';

/// Threshold for average composite score: 80% of max scale (5.0 → 4.0).
const double kFavoritesScoreThreshold = 4.0;

/// Minimum number of visits required to qualify as a favorite.
const int kFavoritesMinVisits = 2;

class FavoritesService {
  /// Computes the list of favorite restaurants from all restaurants and visits.
  ///
  /// A restaurant qualifies as a favorite when ALL three auto-criteria are met:
  /// - AC-1: >= [kFavoritesMinVisits] non-blacklisted visits logged
  /// - AC-1: Average composite score >= [kFavoritesScoreThreshold] (80% of scale max)
  /// - AC-1: At least one visit with returnIntent = true
  ///
  /// Manual overrides take precedence (AC-3):
  /// - [Restaurant.isPinned] = true → excluded from auto-favorites (goes to pinned section)
  /// - [Restaurant.isUnpinned] = true → always hidden from favorites
  ///
  /// Blacklisted visits are excluded from all computations (AC-5).
  static List<Restaurant> computeFavorites(
    List<Restaurant> restaurants,
    List<Visit> visits,
  ) {
    // Filter out blacklisted visits (AC-5).
    final validVisits = visits.where((v) => !v.blacklisted).toList();

    // Group visits by restaurant.
    final grouped = <int, List<Visit>>{};
    for (final v in validVisits) {
      grouped.putIfAbsent(v.restaurantId, () => []);
      grouped[v.restaurantId]!.add(v);
    }

    final favorites = <Restaurant>[];

    for (final restaurant in restaurants) {
      // AC-3: Unpinned restaurants are always hidden.
      if (restaurant.isUnpinned) continue;

      final restaurantVisits = grouped[restaurant.id] ?? [];

      // AC-3: Pinned restaurants show regardless of auto-criteria.
      if (restaurant.isPinned) {
        favorites.add(restaurant);
        continue;
      }

      // Auto-surface criteria for non-pinned, non-unpinned restaurants.

      // AC-1: Need at least kFavoritesMinVisits visits.
      if (restaurantVisits.length < kFavoritesMinVisits) continue;

      // AC-1: Average composite score must be >= threshold.
      final avgScore =
          restaurantVisits.fold<double>(
                0.0,
                (sum, v) => sum + v.compositeScore,
              ) /
              restaurantVisits.length;

      if (avgScore < kFavoritesScoreThreshold) continue;

      // AC-1: At least one visit must have returnIntent = true.
      final hasReturnIntent = restaurantVisits.any((v) => v.returnIntent);
      if (!hasReturnIntent) continue;

      favorites.add(restaurant);
    }

    // Sort by average score descending for consistent display order.
    favorites.sort((a, b) {
      final aVisits = grouped[a.id] ?? [];
      final bVisits = grouped[b.id] ?? [];
      final aAvg = aVisits.fold<double>(0.0, (s, v) => s + v.compositeScore) / aVisits.length;
      final bAvg = bVisits.fold<double>(0.0, (s, v) => s + v.compositeScore) / bVisits.length;
      return bAvg.compareTo(aAvg);
    });

    return favorites;
  }
}
