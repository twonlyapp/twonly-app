// Persisted enum names must stay compatible with the Rust database.

enum SignalVersion { v1, v2 }

enum VerificationType {
  migratedFromOldVersion,
  qrScanned,
  link,
  manual,
  secretQrToken,
  contactSharedByVerified,
}
