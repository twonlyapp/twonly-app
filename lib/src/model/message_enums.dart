// Persisted enum names must stay compatible with the Rust database.

enum MessageType {
  media,
  text,
  contacts,
  restoreFlameCounter,
  askAboutUser,
  webxdcApp,
}

enum MessageActionType {
  openedAt,
  ackByUserAt,
  ackByServerAt,
  sendFailed,
}
