/// JSON data export service (AC-5).
///
/// Serializes all user data (restaurants, visits, preferences, allergens)
/// to a valid JSON string for the "Export your data as JSON" feature.

import 'dart:convert';

import 'package:plated4me/domain/entities/entities.dart';

// -- Public API ----------------------------------------------------------------

/// Exports all user data to a pretty-printed JSON string.
///
/// Includes restaurants, visits, user preferences, and allergens.
/// Used by the Settings screen's "Export your data as JSON" action (AC-5).
///
/// Returns a formatted JSON document suitable for file writing.
String exportToJson({
  required List<Restaurant> restaurants,
  required List<Visit> visits,
  required UserPreferences? preferences,
  required List<Allergen> allergens,
}) {
  final data = <String, dynamic>{
    'restaurants': restaurants.map(_serializeRestaurant).toList(),
    'visits': visits.map(_serializeVisit).toList(),
    'preferences': preferences != null ? _serializePreferences(preferences) : null,
    'allergens': allergens.map(_serializeAllergen).toList(),
  };

  return const JsonEncoder.withIndent('  ').convert(data);
}

// -- Serializers ---------------------------------------------------------------

Map<String, dynamic> _serializeRestaurant(Restaurant r) {
  return {
    'id': r.id,
    'name': r.name,
    'address': r.address,
    'notes': r.notes,
    'createdAt': r.createdAt.toIso8601String(),
    'updatedAt': r.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> _serializeVisit(Visit v) {
  return {
    'id': v.id,
    'restaurantId': v.restaurantId,
    'foodRating': v.foodRating,
    'valueRating': v.valueRating,
    'serviceRating': v.serviceRating,
    'overallRating': v.overallRating,
    'compositeScore': v.compositeScore,
    'returnIntent': v.returnIntent,
    'occasions': v.occasions,
    'mealTotal': v.mealTotal,
    'tipPercent': v.tipPercent,
    'employeeName': v.employeeName,
    'generalNotes': v.generalNotes,
    'blacklisted': v.blacklisted,
    'blacklistReason': v.blacklistReason,
    'createdAt': v.createdAt.toIso8601String(),
    'updatedAt': v.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic>? _serializePreferences(UserPreferences p) {
  return {
    'ratingScale': p.ratingScale,
    'cuisinePreferences': p.cuisinePreferences,
    'defaultOccasions': p.defaultOccasions,
    'onboardingComplete': p.onboardingComplete,
    'allergies': p.allergies.map((a) => {'name': a.name, 'severity': a.severity}).toList(),
    'createdAt': p.createdAt.toIso8601String(),
    'updatedAt': p.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> _serializeAllergen(Allergen a) {
  return {
    'id': a.id,
    'name': a.name,
    'severity': a.severity,
    'createdAt': a.createdAt.toIso8601String(),
  };
}
