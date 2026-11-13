/// Domain entity definitions for Isar 3.x code generation.
///
/// Each class is annotated with @collection so the [isar_generator] creates
/// schema classes and collection accessors (e.g., `isar.restaurants`, `isar.visits`).
import 'package:isar/isar.dart';

part 'entities.g.dart';

// -- Main entities -----------------------------------------------------------

@collection
class Restaurant {
  Id id = Isar.autoIncrement;

  /// The restaurant's display name. Indexed for deduplication lookups (AD-10).
  @Index(type: IndexType.value)
  String name = '';

  /// The restaurant's street address. Null if not recorded.
  @Index(type: IndexType.value)
  String? address;

  /// When this restaurant record was first created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  /// Last time any field on this restaurant was updated.
  DateTime updatedAt = DateTime.now();

  // -- Sub-collections --------------------------------------------------------
  /// Allergy-safe foods associated with this restaurant (FR-5).
  @ignore
  List<AllergySafeFood> allergySafeFoods = const [];

  Restaurant({required this.name, this.address});

  void touch() => updatedAt = DateTime.now();

  Restaurant copyWith({
    Id? id,
    String? name,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(name: name ?? this.name, address: address ?? this.address)
      ..id = id ?? this.id
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }

  @override
  String toString() => 'Restaurant(name: $name, address: $address)';
}

@collection
class Visit {
  Id id = Isar.autoIncrement;

  /// Foreign key reference to the associated Restaurant.
  int restaurantId = 0;

  // -- Ratings (required for save) ------------------------------------------
  double foodRating = 0;
  double valueRating = 0;
  double serviceRating = 0;
  double overallRating = 0;

  /// Pre-computed weighted composite score (AD-4).
  double compositeScore = 0;

  // -- Return intent --------------------------------------------------------
  bool returnIntent = false;

  // -- Occasion tags --------------------------------------------------------
  final occasions = <String>[];

  // -- Meal details (optional) ----------------------------------------------
  double? mealTotal;
  double? tipPercent;
  String? employeeName;

  // -- Optional sections ----------------------------------------------------
  String? generalNotes;
  bool blacklisted = false;
  String? blacklistReason;

  // -- Timestamps -----------------------------------------------------------
  /// When this visit record was first created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  /// Last time any field on this visit was updated.
  DateTime updatedAt = DateTime.now();

  // -- Sub-collections (FR-6, FR-2, UX-DR9) ---------------------------------
  /// Allergy-safe foods recorded during this visit (FR-5).
  @ignore
  List<AllergySafeFood> allergySafeFoods = const [];

  /// Journal entries for dishes tasted on this visit (FR-6).
  @ignore
  List<JournalEntry> journalEntries = const [];

  /// Line items (dishes ordered) for this visit (FR-2).
  @ignore
  List<VisitLineItem> lineItems = const [];

  /// Photo attachments for this visit (UX-DR9).
  @ignore
  List<PhotoAttachment> photos = const [];

  Visit({
    required this.restaurantId,
    required this.foodRating,
    required this.valueRating,
    required this.serviceRating,
    required this.overallRating,
    required this.compositeScore,
    required this.returnIntent,
  });

  void touch() => updatedAt = DateTime.now();

  Visit copyWith({
    Id? id,
    int? restaurantId,
    double? foodRating,
    double? valueRating,
    double? serviceRating,
    double? overallRating,
    double? compositeScore,
    bool? returnIntent,
    List<String>? occasions,
    double? mealTotal,
    double? tipPercent,
    String? employeeName,
    String? generalNotes,
    bool? blacklisted,
    String? blacklistReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
        restaurantId: restaurantId ?? this.restaurantId,
        foodRating: foodRating ?? this.foodRating,
        valueRating: valueRating ?? this.valueRating,
        serviceRating: serviceRating ?? this.serviceRating,
        overallRating: overallRating ?? this.overallRating,
        compositeScore: compositeScore ?? this.compositeScore,
        returnIntent: returnIntent ?? this.returnIntent,
      )
      ..id = id ?? this.id
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }

  @override
  String toString() =>
      'Visit(restaurantId: $restaurantId, composite: $compositeScore)';
}

@collection
class UserPreferences {
  /// There is exactly one UserPreferences record per device.
  Id id = 1;

  // -- Timestamps -----------------------------------------------------------
  /// When these preferences were first created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  /// Last time any preference was updated.
  DateTime updatedAt = DateTime.now();

  // -- Allergies (FR-14, FR-16) ---------------------------------------------
  @ignore
  List<Allergen> allergies = [];

  // -- Cuisine preferences (FR-14, FR-16) -----------------------------------
  final cuisinePreferences = <String>[];

  // -- Rating scale (FR-14, FR-16) ------------------------------------------
  int ratingScale = 5;

  // -- Default occasions (FR-14) --------------------------------------------
  final defaultOccasions = <String>[];

  // -- Onboarding state (AD-6) ----------------------------------------------
  bool onboardingComplete = false;

  UserPreferences();

  void touch() => updatedAt = DateTime.now();

  UserPreferences copyWith({
    List<Allergen>? allergies,
    List<String>? cuisinePreferences,
    int? ratingScale,
    List<String>? defaultOccasions,
    bool? onboardingComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final result = UserPreferences()..id = id;
    if (allergies != null) {
      result.allergies.addAll(allergies);
    } else {
      result.allergies.addAll(this.allergies);
    }
    if (cuisinePreferences != null) {
      result.cuisinePreferences.addAll(cuisinePreferences);
    } else {
      result.cuisinePreferences.addAll(this.cuisinePreferences);
    }
    result.ratingScale = ratingScale ?? this.ratingScale;
    if (defaultOccasions != null) {
      result.defaultOccasions.addAll(defaultOccasions);
    } else {
      result.defaultOccasions.addAll(this.defaultOccasions);
    }
    result.onboardingComplete = onboardingComplete ?? this.onboardingComplete;
    result.createdAt = createdAt ?? this.createdAt;
    result.updatedAt = updatedAt ?? this.updatedAt;
    return result;
  }

  @override
  String toString() => 'UserPreferences(scale: $ratingScale)';
}

// -- Sub-collections ---------------------------------------------------------

@collection
class AllergySafeFood {
  Id id = Isar.autoIncrement;
  String itemName = '';

  /// When this safe-food entry was created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  AllergySafeFood({required this.itemName});

  AllergySafeFood copyWith({Id? id, String? itemName, DateTime? createdAt}) {
    return AllergySafeFood(itemName: itemName ?? this.itemName)
      ..id = id ?? this.id
      ..createdAt = createdAt ?? this.createdAt;
  }

  @override
  String toString() => 'AllergySafeFood(itemName: $itemName)';
}

@collection
class JournalEntry {
  Id id = Isar.autoIncrement;
  String dishName = '';
  String impressions = '';

  /// When this journal entry was created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  JournalEntry({required this.dishName, required this.impressions});

  JournalEntry copyWith({Id? id, String? dishName, String? impressions}) {
    return JournalEntry(
      dishName: dishName ?? this.dishName,
      impressions: impressions ?? this.impressions,
    )..id = id ?? this.id;
  }

  @override
  String toString() => 'JournalEntry(dishName: $dishName)';
}

@collection
class VisitLineItem {
  Id id = Isar.autoIncrement;
  String dishName = '';
  double? price;

  /// When this line item was created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  VisitLineItem({required this.dishName});

  VisitLineItem copyWith({Id? id, String? dishName, double? price}) {
    return VisitLineItem(dishName: dishName ?? this.dishName)
      ..id = id ?? this.id
      ..price = price ?? this.price;
  }

  @override
  String toString() => 'VisitLineItem(dishName: $dishName)';
}

@collection
class PhotoAttachment {
  Id id = Isar.autoIncrement;
  String filePath = '';

  /// When this photo was taken/attached.
  @Index(type: IndexType.value)
  DateTime timestamp = DateTime.now();

  /// When this attachment record was created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  PhotoAttachment({required this.filePath, required this.timestamp});

  PhotoAttachment copyWith({Id? id, String? filePath, DateTime? timestamp}) {
    return PhotoAttachment(
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
    )..id = id ?? this.id;
  }

  @override
  String toString() => 'PhotoAttachment(filePath: $filePath)';
}

// -- Supporting types --------------------------------------------------------

@collection
class Allergen {
  Id id = Isar.autoIncrement;

  /// The allergen's display name. Indexed for lookups.
  @Index(type: IndexType.value)
  String name = '';

  /// Severity level: 0 = moderate, 1 = severe (stored as int for Isar compatibility).
  int severity = 0;

  /// When this allergen entry was created.
  @Index(type: IndexType.value)
  DateTime createdAt = DateTime.now();

  Allergen({required this.name, required this.severity});

  Allergen copyWith({Id? id, String? name, int? severity}) {
    return Allergen(
      name: name ?? this.name,
      severity: severity ?? this.severity,
    )..id = id ?? this.id;
  }

  @override
  String toString() => 'Allergen(name: $name)';
}
