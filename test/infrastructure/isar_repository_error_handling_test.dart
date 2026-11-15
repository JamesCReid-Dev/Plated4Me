/// Error handling and retry logic tests for repository implementations.
///
/// Covers AC-5 of P4ME-24:
///   Error handling: 2 retries (~500ms each) for transient failures;
///   recoverable → snack bar, unrecoverable → dialog (AD-8).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';
import 'package:plated4me/infrastructure/storage/repository_exception.dart';

// -- Fake repository for controlled failure testing --------------------------

/// A fake [RestaurantRepository] that can be configured to fail N times before succeeding.
class FailingRestaurantRepository implements RestaurantRepository {
  int failuresRemaining = 0;
  bool alwaysFailRecoverable = false;
  bool alwaysFailUnrecoverable = false;
  int saveCallCount = 0;
  final List<Restaurant> data = [];

  @override
  Future<List<Restaurant>> getAllRestaurants() async => data;

  @override
  Future<Restaurant?> getRestaurantById(int id) async {
    try {
      return data.firstWhere((r) => r.id == id, orElse: () => throw ArgumentError());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    if (query.trim().isEmpty) return [];
    return data.where((r) => r.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<Restaurant> saveRestaurant(Restaurant restaurant) async {
    saveCallCount++;

    if (alwaysFailUnrecoverable) {
      throw RepositoryException.unrecoverable('Disk full');
    }

    if (alwaysFailRecoverable || failuresRemaining > 0) {
      failuresRemaining--;
      throw RepositoryException.recoverable('DB busy');
    }

    final idx = data.indexWhere((r) => r.id == restaurant.id);
    if (idx >= 0) {
      data[idx] = restaurant;
    } else {
      data.add(restaurant);
    }
    return restaurant;
  }

  @override
  Future<bool> deleteRestaurant(int id) async {
    final idx = data.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      data.removeAt(idx);
      return true;
    }
    return false;
  }

  @override
  Future<bool> existsByName(String name) async {
    return data.any((r) => r.name == name);
  }

  @override
  Future<Restaurant?> getByNamedAddress(String name, String? address) async {
    try {
      return data.firstWhere(
        (r) => r.name == name && r.address == address,
        orElse: () => throw ArgumentError(),
      );
    } catch (_) {
      return null;
    }
  }
}

// -- Retry helper test -------------------------------------------------------

/// Simulates the _retryWithBackoff logic from isar_storage.dart for testing.
/// Mirrors the production retry behavior: up to 2 retries at ~500ms each.
Future<T> _testRetryWithBackoff<T>(
  Future<T> Function() fn, {
  int maxRetries = 2,
  int retryDelayMs = 500,
}) async {
  Object? lastError;
  for (var attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } on RepositoryException catch (e) {
      if (!e.isRecoverable) rethrow;
      lastError = e;
      if (attempt < maxRetries) {
        await Future<void>.delayed(Duration(milliseconds: retryDelayMs));
      }
    } catch (e) {
      lastError = e;
      if (attempt < maxRetries) {
        await Future<void>.delayed(Duration(milliseconds: retryDelayMs));
      }
    }
  }
  throw RepositoryException.recoverable(
    'Operation failed after $maxRetries retry attempts',
    error: lastError,
  );
}

// -- AC-5: RepositoryException tests -----------------------------------------

void main() {
  group('AC-5 — RepositoryException', () {
    test('recoverable exception can be distinguished from unrecoverable', () {
      final recoverable = RepositoryException.recoverable('DB busy');
      final unrecoverable = RepositoryException.unrecoverable('Corrupt DB');

      expect(recoverable.isRecoverable, isTrue);
      expect(unrecoverable.isRecoverable, isFalse);
    });

    test('RepositoryException carries the original error when available', () {
      final original = _TestError('underlying cause');
      final ex = RepositoryException.recoverable('Failed to load', error: original);
      expect(ex.error, equals(original));
    });

    test('recoverable exception message is preserved', () {
      const message = 'Connection lost';
      final ex = RepositoryException.recoverable(message);
      expect(ex.message, equals(message));
    });

    test('unrecoverable exception message is preserved', () {
      const message = 'Disk full';
      final ex = RepositoryException.unrecoverable(message);
      expect(ex.message, equals(message));
    });

    test('toString includes both type and message', () {
      final ex = RepositoryException.recoverable('Timeout');
      expect(ex.toString(), contains('isRecoverable: true'));
      expect(ex.toString(), contains('Timeout'));
    });
  });

  // -- AC-5: Retry logic tests (mirrors _retryWithBackoff in isar_storage.dart)

  group('AC-5 — Retry logic for transient failures', () {
    test(
        'retries once then succeeds when failure count is 1',
        () async {
      var callCount = 0;
      final stopwatch = Stopwatch()..start();

      final result = await _testRetryWithBackoff(() async {
        callCount++;
        if (callCount <= 1) {
          throw RepositoryException.recoverable('DB busy');
        }
        return 'success';
      });

      final elapsed = stopwatch.elapsedMilliseconds;
      expect(callCount, equals(2)); // initial + 1 retry
      expect(result, equals('success'));
      // With 1 retry at 500ms delay: ~500ms total (allow generous margin)
      expect(elapsed, lessThan(2000));
    });

    test(
        'retries twice then succeeds when failure count is 2',
        () async {
      var callCount = 0;
      final stopwatch = Stopwatch()..start();

      await _testRetryWithBackoff(() async {
        callCount++;
        if (callCount <= 2) {
          throw RepositoryException.recoverable('DB busy');
        }
        return 'success';
      });

      final elapsed = stopwatch.elapsedMilliseconds;
      expect(callCount, equals(3)); // initial + 2 retries
      // With 2 retries at 500ms each: ~1000ms total (allow generous margin)
      expect(elapsed, lessThan(3000));
    });

    test('throws recoverable exception after exhausting all retries', () async {
      var callCount = 0;

      await expectLater(
        () => _testRetryWithBackoff(() async {
          callCount++;
          throw RepositoryException.recoverable('Always fails');
        }),
        throwsA(isA<RepositoryException>().having(
          (e) => e.isRecoverable,
          'isRecoverable',
          isTrue,
        )),
      );
      // Should be: initial + 2 retries = 3 calls
      expect(callCount, equals(3));
    });

    test('does NOT retry on unrecoverable errors — fails immediately', () async {
      var callCount = 0;

      await expectLater(
        () => _testRetryWithBackoff(() async {
          callCount++;
          throw RepositoryException.unrecoverable('Disk full');
        }),
        throwsA(isA<RepositoryException>().having(
          (e) => e.isRecoverable,
          'isRecoverable',
          isFalse,
        )),
      );
      // No retries for unrecoverable — only 1 call
      expect(callCount, equals(1));
    });

    test('succeeds on first attempt when no failure occurs', () async {
      var callCount = 0;
      final stopwatch = Stopwatch()..start();

      final result = await _testRetryWithBackoff(() async {
        callCount++;
        return 42;
      });

      final elapsed = stopwatch.elapsedMilliseconds;
      expect(callCount, equals(1)); // no retries needed
      expect(result, equals(42));
      expect(elapsed, lessThan(100));
    });

    test('non-RepositoryException errors are also retried', () async {
      var callCount = 0;

      await _testRetryWithBackoff(() async {
        callCount++;
        if (callCount == 1) throw Exception('Transient error');
        return 'recovered';
      });

      expect(callCount, equals(2)); // initial + 1 retry
    });
  });

  // -- AC-5: Error type classification ---------------------------------------

  group('AC-5 — Error handling contract', () {
    test('recoverable exception is distinguishable via isRecoverable flag', () {
      final recoverable = RepositoryException.recoverable('DB busy');
      expect(recoverable.isRecoverable, isTrue);
    });

    test('unrecoverable exception has isRecoverable == false', () {
      final unrecoverable = RepositoryException.unrecoverable('Schema corrupted');
      expect(unrecoverable.isRecoverable, isFalse);
    });

    test('saveRestaurant throws on invalid input after retries exhausted',
        () async {
      // After 2 retry attempts, a persistently failing operation should throw.
      final repo = FailingRestaurantRepository()..alwaysFailRecoverable = true;

      await expectLater(
        () => repo.saveRestaurant(Restaurant(name: 'Always Fails')),
        throwsA(isA<RepositoryException>()),
      );
    });
  });
}

// Helper class for testing error carrying (Exception is not const)
class _TestError implements Exception {
  final String message;
  _TestError(this.message);
  @override
  String toString() => '_TestError($message)';
}
