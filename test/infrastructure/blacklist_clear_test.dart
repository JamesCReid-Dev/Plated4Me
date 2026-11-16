/// Infrastructure tests for blacklist clearing (AC-6).
///
/// Red Phase: These tests verify that blacklisted visits can be identified
/// and bulk-deleted. The production code will need a repository method to
/// find all blacklisted visits and remove them in a single operation.
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/infrastructure/storage/isar_storage.dart';

/// Tries to open a test Isar database. Returns false if native libraries
/// aren't available (i.e., running in pure VM without a Flutter device).
Future<bool> _tryOpenIsar(List<CollectionSchema<dynamic>> schemas) async {
  try {
    final isar = await Isar.open(schemas, directory: ':memory:');
    await isar.close();
    return true;
  } catch (e) {
    if (e.toString().contains('libisar') ||
        e.toString().contains('Failed to load dynamic library')) {
      return false;
    }
    rethrow;
  }
}

void main() {
  group('AC-6 — Blacklist Clear Option', () {
    // -- Identification of blacklisted visits ------------------------------

    test('AC-6: Visit.blacklisted defaults to false', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.5,
        overallRating: 4.0,
        compositeScore: 3.95,
        returnIntent: true,
      );

      expect(visit.blacklisted, isFalse);
    });

    test('AC-6: Visit can be marked as blacklisted', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 1.0,
        valueRating: 1.0,
        serviceRating: 1.0,
        overallRating: 1.0,
        compositeScore: 1.0,
        returnIntent: false,
      )..blacklisted = true;

      expect(visit.blacklisted, isTrue);
    });

    test('AC-6: blacklisted visit can have a reason', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 1.0,
        valueRating: 1.0,
        serviceRating: 1.0,
        overallRating: 1.0,
        compositeScore: 1.0,
        returnIntent: false,
      )..blacklisted = true
        ..blacklistReason = 'Food poisoning';

      expect(visit.blacklisted, isTrue);
      expect(visit.blacklistReason, equals('Food poisoning'));
    });

    // -- Bulk delete via repository ----------------------------------------

    test('AC-6: can identify blacklisted visits in a mixed list', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);

        // Save a mix of blacklisted and normal visits.
        await repo.saveVisit(Visit(
          restaurantId: 1, foodRating: 4.0, valueRating: 3.5,
          serviceRating: 4.5, overallRating: 4.0, compositeScore: 3.95, returnIntent: true,
        ));
        await repo.saveVisit(Visit(
          restaurantId: 2, foodRating: 1.0, valueRating: 1.0,
          serviceRating: 1.0, overallRating: 1.0, compositeScore: 1.0, returnIntent: false,
        )..blacklisted = true);
        await repo.saveVisit(Visit(
          restaurantId: 3, foodRating: 5.0, valueRating: 4.5,
          serviceRating: 5.0, overallRating: 5.0, compositeScore: 4.75, returnIntent: true,
        ));
        await repo.saveVisit(Visit(
          restaurantId: 4, foodRating: 1.0, valueRating: 1.0,
          serviceRating: 1.0, overallRating: 1.0, compositeScore: 1.0, returnIntent: false,
        )..blacklisted = true);

        final allVisits = await repo.getAllVisits();
        final blacklistedIds = <Id>[];
        for (final v in allVisits) {
          if (v.blacklisted) blacklistedIds.add(v.id);
        }

        expect(blacklistedIds, hasLength(2));
      } finally {
        await isar.close();
      }
    });

    test('AC-6: bulkDeleteBlacklistedVisits removes all blacklisted visits', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);

        // Save 3 blacklisted + 2 normal visits.
        for (var i = 0; i < 3; i++) {
          await repo.saveVisit(Visit(
            restaurantId: i + 1, foodRating: 1.0, valueRating: 1.0,
            serviceRating: 1.0, overallRating: 1.0, compositeScore: 1.0, returnIntent: false,
          )..blacklisted = true);
        }
        await repo.saveVisit(Visit(
          restaurantId: 4, foodRating: 4.0, valueRating: 3.5,
          serviceRating: 4.5, overallRating: 4.0, compositeScore: 3.95, returnIntent: true,
        ));
        await repo.saveVisit(Visit(
          restaurantId: 5, foodRating: 5.0, valueRating: 4.5,
          serviceRating: 5.0, overallRating: 5.0, compositeScore: 4.75, returnIntent: true,
        ));

        final before = await repo.getAllVisits();
        expect(before, hasLength(5));

        // Bulk delete blacklisted visits.
        final deletedCount = await repo.bulkDeleteBlacklistedVisits();

        expect(deletedCount, equals(3));
        final after = await repo.getAllVisits();
        expect(after, hasLength(2));
        expect(after.every((v) => !v.blacklisted), isTrue);
      } finally {
        await isar.close();
      }
    });

    test('AC-6: bulkDeleteBlacklistedVisits returns 0 when none blacklisted', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);

        await repo.saveVisit(Visit(
          restaurantId: 1, foodRating: 4.0, valueRating: 3.5,
          serviceRating: 4.5, overallRating: 4.0, compositeScore: 3.95, returnIntent: true,
        ));

        final deletedCount = await repo.bulkDeleteBlacklistedVisits();

        expect(deletedCount, equals(0));
      } finally {
        await isar.close();
      }
    });

    test('AC-6: bulkDeleteBlacklistedVisits returns count when all are blacklisted', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);

        for (var i = 0; i < 5; i++) {
          await repo.saveVisit(Visit(
            restaurantId: i + 1, foodRating: 1.0, valueRating: 1.0,
            serviceRating: 1.0, overallRating: 1.0, compositeScore: 1.0, returnIntent: false,
          )..blacklisted = true);
        }

        final deletedCount = await repo.bulkDeleteBlacklistedVisits();

        expect(deletedCount, equals(5));
        final remaining = await repo.getAllVisits();
        expect(remaining, isEmpty);
      } finally {
        await isar.close();
      }
    });

    test('AC-6: bulkDeleteBlacklistedVisits handles empty database', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);

        final deletedCount = await repo.bulkDeleteBlacklistedVisits();

        expect(deletedCount, equals(0));
      } finally {
        await isar.close();
      }
    });

    // -- Confirmation requirement (entity-level) ---------------------------

    test('AC-6: blacklistReason is preserved on blacklisted visit', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);

        final visit = Visit(
          restaurantId: 1,
          foodRating: 1.0,
          valueRating: 1.0,
          serviceRating: 1.0,
          overallRating: 1.0,
          compositeScore: 1.0,
          returnIntent: false,
        )..blacklisted = true
          ..blacklistReason = 'Severe allergic reaction';

        await repo.saveVisit(visit);
        final fetched = await repo.getVisitById(visit.id);

        expect(fetched!.blacklisted, isTrue);
        expect(fetched.blacklistReason, equals('Severe allergic reaction'));
      } finally {
        await isar.close();
      }
    });
  });
}
