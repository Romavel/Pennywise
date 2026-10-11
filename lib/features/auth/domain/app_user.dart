import 'package:flutter/foundation.dart';

/// The signed-in user, independent of the auth backend.
@immutable
class AppUser {
  const AppUser({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);

  // Deliberately omits the email so users are not logged by accident.
  @override
  String toString() => 'AppUser($uid)';
}
