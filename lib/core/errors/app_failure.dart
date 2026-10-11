import 'package:flutter/foundation.dart';

/// Errors surfaced to the UI. Data sources map raw exceptions (Firebase,
/// platform, network) to one of these so presentation code never depends on
/// backend-specific error types.
@immutable
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  /// Human-readable message, safe to show to the user.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class FirebaseNotConfiguredFailure extends AppFailure {
  const FirebaseNotConfiguredFailure()
    : super(
        'Firebase is not configured for this platform. '
        'Run `flutterfire configure` and rebuild the app.',
      );
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure()
    : super('No connection. Check your internet and try again.');
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([this.cause])
    : super('Something went wrong. Please try again.');

  final Object? cause;
}
