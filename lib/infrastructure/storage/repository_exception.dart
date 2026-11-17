/// Base exception for repository-level errors.
///
/// Distinguishes between recoverable errors (transient DB issues that can be retried)
/// and unrecoverable errors (schema corruption, disk full — require user intervention).
///
/// Used by all [Isar*Repository] implementations to signal error severity
/// so callers can choose the appropriate UI response (snack bar vs dialog).
class RepositoryException implements Exception {
  /// Whether this error is recoverable (true) or requires a dialog (false).
  final bool isRecoverable;

  /// Human-readable error message.
  final String message;

  /// The underlying cause, if available.
  final Object? error;

  const RepositoryException._(
    this.message, {
    required this.isRecoverable,
    this.error,
  });

  /// Creates a recoverable exception for transient failures.
  ///
  /// These errors (e.g., database busy, lock timeout) should trigger retry logic.
  /// On exhaustion of retries, show a snack bar to the user.
  factory RepositoryException.recoverable(String message, {Object? error}) {
    return RepositoryException._(message, isRecoverable: true, error: error);
  }

  /// Creates an unrecoverable exception for permanent failures.
  ///
  /// These errors (e.g., schema corruption, disk full) should bypass retries
  /// and show a dialog to the user immediately.
  factory RepositoryException.unrecoverable(String message, {Object? error}) {
    return RepositoryException._(message, isRecoverable: false, error: error);
  }

  @override
  String toString() =>
      'RepositoryException(isRecoverable: $isRecoverable, message: $message)';
}
