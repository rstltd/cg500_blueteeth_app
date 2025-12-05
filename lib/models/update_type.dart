/// Update type enumeration indicating the urgency of an update.
enum UpdateType {
  optional,     // User can choose to update
  recommended,  // Strongly recommended but not forced
  critical,     // Critical security/bug fixes
  forced,       // Must update to continue using app
}
