/// Repository interface for [UserPreferences] entities.
///
/// Defines the contract for managing user preferences, including
/// an existence check used as the onboarding gate (AC-3, P4ME-24).
import 'package:plated4me/domain/entities/entities.dart';

abstract class UserPreferencesRepository {
  /// Returns user preferences, creating defaults if none exist.
  Future<UserPreferences> getUserPreferences();

  /// Saves user preferences (single record per device, ID=1).
  Future<UserPreferences> saveUserPreferences(UserPreferences preferences);

  /// Checks whether user preferences exist in the database.
  ///
  /// Used as the onboarding gate: if false, show onboarding flow (AC-3, AD-6).
  Future<bool> hasPreferences();
}
