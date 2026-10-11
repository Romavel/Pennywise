import 'package:flutter/foundation.dart';

/// Errors surfaced to the UI. Data sources map raw exceptions (Firebase,
/// platform, network) to one of these so presentation code never depends on
/// backend-specific error types. Features add their own subclasses.
@immutable
abstract class AppFailure implements Exception {
  const AppFailure();

  /// Human-readable message, safe to show to the user.
  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

final class FirebaseNotConfiguredFailure extends AppFailure {
  const FirebaseNotConfiguredFailure();

  @override
  String get message =>
      'Firebase is not configured for this platform. '
      'Run `flutterfire configure` and rebuild the app.';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();

  @override
  String get message => 'No connection. Check your internet and try again.';
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([this.cause]);

  final Object? cause;

  @override
  String get message => 'Something went wrong. Please try again.';
}
