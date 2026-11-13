/// Repository interface for [UserPreferences] entities.
///
/// There is exactly one [UserPreferences] record per device (fixed ID = 1).
import 'package:plated4me/domain/entities/entities.dart';

abstract class UserPreferencesRepository {
  /// Returns the singleton user preferences record.
  ///
  /// If no record exists, creates and returns a default instance.
  Future<UserPreferences> getUserPreferences();

  /// Updates the user preferences record.
  ///
  /// The [preferences] must have `id == 1`. All fields are overwritten
  /// with the values from [preferences].
  Future<UserPreferences> saveUserPreferences(UserPreferences preferences);
}
