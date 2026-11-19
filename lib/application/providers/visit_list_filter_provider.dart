/// Riverpod provider for filtered and sorted visit lists.
///
/// Joins [Visit] data with [Restaurant] names, applies filter criteria,
/// and returns a sorted list of [FilteredVisit] objects for display in
/// VisitCard widgets on the Browse screen.
///
/// P4ME-17 — S10 Filterable Visit Card List.
/// Covers AC-2 (default sort), AC-4 (filter options), AC-5 (apply filters),
/// AC-6 (clear all), AC-7 (active filter badge).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';

/// Placeholder name for visits whose restaurant could not be resolved.
const _kUnknownRestaurantName = 'Unknown Restaurant';

/// Joined visit + restaurant data for display in VisitCard widgets.
class FilteredVisit {
  /// The visit record.
  final Visit visit;

  /// The associated restaurant (resolved by [Visit.restaurantId]).
  /// May be a placeholder when no matching restaurant exists (P4ME-43).
  final Restaurant restaurant;

  const FilteredVisit({required this.visit, required this.restaurant});
}

/// Notifier that manages a filtered and sorted list of [FilteredVisit] objects.
///
/// Default state: all visits sorted by [Visit.createdAt] descending (most recent first).
/// Filter criteria can be applied individually or cleared all at once.
class VisitListFilterNotifier extends AsyncNotifier<List<FilteredVisit>> {
  VisitRepository? _visitRepo;
  RestaurantRepository? _restaurantRepo;

  String? _cuisineType;
  double? _minRating;
  double? _maxRating;
  String? _occasionTag;
  bool _allergySafeOnly = false;

  /// Default constructor for production use.
  VisitListFilterNotifier();

  /// Constructor for testing with mock repositories.
  VisitListFilterNotifier.withRepos(this._visitRepo, this._restaurantRepo);

  @override
  Future<List<FilteredVisit>> build() async {
    // Only read repositories if not already set (i.e., using default constructor).
    _visitRepo ??= ref.read(visitRepositoryProvider);
    _restaurantRepo ??= ref.read(restaurantRepositoryProvider);
    return _loadVisits();
  }

  /// Loads all visits and joins them with restaurant data.
  Future<List<FilteredVisit>> _loadVisits() async {
    final visits = await _visitRepo!.getAllVisits();
    final restaurants = await _restaurantRepo!.getAllRestaurants();
    return _buildFilteredResult(visits, restaurants);
  }

  /// Builds the result list from raw visit and restaurant data.
  ///
  /// Joins each [Visit] with its [Restaurant]. Visits whose [Visit.restaurantId]
  /// does not match any restaurant (e.g., orphaned visits from QuickLog's
  /// `restaurantId: 0`) are included with a placeholder name (P4ME-43).
  List<FilteredVisit> _buildFilteredResult(
      List<Visit> visits, List<Restaurant> restaurants) {
    final restaurantMap = {for (final r in restaurants) r.id: r};

    // P4ME-43: Placeholder for visits with no matching restaurant.
    final unknownRestaurant = Restaurant(name: _kUnknownRestaurantName);

    final result = <FilteredVisit>[];
    for (final visit in visits) {
      final restaurant = restaurantMap[visit.restaurantId] ?? unknownRestaurant;
      result.add(FilteredVisit(visit: visit, restaurant: restaurant));
    }

    // AC-2: Default sort — most recent first.
    result.sort((a, b) => b.visit.createdAt.compareTo(a.visit.createdAt));
    return result;
  }

  /// Reloads data from repositories and re-applies filters.
  Future<void> refresh() async {
    state = AsyncData(_applyFilters(await _loadVisits()));
  }

  /// Applies or updates a filter criterion.
  ///
  /// Each parameter is independent — only the non-null parameters are updated.
  Future<void> setFilterCriteria({
    String? cuisineType,
    double? minRating,
    double? maxRating,
    String? occasionTag,
    bool? allergySafeOnly,
  }) async {
    if (cuisineType != null) _cuisineType = cuisineType;
    if (minRating != null) _minRating = minRating;
    if (maxRating != null) _maxRating = maxRating;
    if (occasionTag != null) _occasionTag = occasionTag;
    if (allergySafeOnly != null) _allergySafeOnly = allergySafeOnly;

    state = AsyncData(_applyFilters(await _loadVisits()));
  }

  /// Clears all active filters and returns to the unfiltered view.
  ///
  /// AC-6: Clear all filters resets to unfiltered view.
  Future<void> clearAllFilters() async {
    _cuisineType = null;
    _minRating = null;
    _maxRating = null;
    _occasionTag = null;
    _allergySafeOnly = false;

    state = AsyncData(await _loadVisits());
  }

  /// Returns true if any filter criterion has been set.
  ///
  /// AC-7: Active filter icon shows dot/badge when any filter is active.
  bool get hasActiveFilters {
    return _cuisineType != null ||
        _minRating != null ||
        _maxRating != null ||
        _occasionTag != null ||
        _allergySafeOnly;
  }

  /// Applies all active filters to the visit list (AND logic).
  ///
  /// AC-5: Apply closes sheet and updates list in one frame (~16ms) —
  /// local data is instant.
  List<FilteredVisit> _applyFilters(List<FilteredVisit> visits) {
    var filtered = visits;

    // AC-4: Filter by cuisine type (matches restaurant name).
    if (_cuisineType != null && _cuisineType!.isNotEmpty) {
      final query = _cuisineType!.toLowerCase();
      filtered = filtered
          .where((fv) => fv.restaurant.name.toLowerCase().contains(query))
          .toList();
    }

    // AC-4: Filter by rating range (composite score).
    if (_minRating != null) {
      filtered = filtered
          .where((fv) => fv.visit.compositeScore >= _minRating!)
          .toList();
    }
    if (_maxRating != null) {
      filtered = filtered
          .where((fv) => fv.visit.compositeScore <= _maxRating!)
          .toList();
    }

    // AC-4: Filter by occasion tag.
    if (_occasionTag != null && _occasionTag!.isNotEmpty) {
      filtered = filtered
          .where((fv) =>
              fv.visit.occasions.contains(_occasionTag!))
          .toList();
    }

    // AC-4: Filter by allergy-safe status.
    if (_allergySafeOnly) {
      // A visit is "allergy-safe" if its restaurant has at least one
      // AllergySafeFood recorded. We check the restaurant's sub-collection.
      filtered = filtered.where((fv) {
        return fv.restaurant.allergySafeFoods.isNotEmpty;
      }).toList();
    }

    return filtered;
  }
}

/// Provider for filtered visit list, using default repositories from DI.
final visitsListFilterProvider =
    AsyncNotifierProvider<VisitListFilterNotifier, List<FilteredVisit>>(
      () => VisitListFilterNotifier(),
      name: 'visitsListFilter',
    );
