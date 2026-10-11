/// Outcome of a write.
enum WriteResult {
  /// Confirmed by the server.
  saved,

  /// Stored on the device; it syncs when the connection comes back.
  pendingSync,
}
