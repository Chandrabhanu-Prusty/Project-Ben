/// Manages the 36-hour data retention rules across local storage and UI queries.
class RetentionPolicy {
  RetentionPolicy._();

  /// Maximum retention duration for notifications, conversations, and messages.
  static const Duration retentionDuration = Duration(hours: 36);

  /// Returns current UTC timestamp in epoch milliseconds.
  static int currentTimestamp() {
    return DateTime.now().toUtc().millisecondsSinceEpoch;
  }

  /// Calculates expiration timestamp from a given start timestamp in UTC epoch milliseconds.
  static int calculateExpiration(int startTimestamp) {
    return startTimestamp + retentionDuration.inMilliseconds;
  }

  /// Checks if a record has reached or surpassed its expiration time.
  static bool isExpired(int expiresAt) {
    return currentTimestamp() >= expiresAt;
  }

  /// Returns the cutoff timestamp for queries: anything with expires_at <= cutoff is expired.
  static int currentExpiryCutoff() {
    return currentTimestamp();
  }
}
