import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/data/firestore_helpers.dart';
import '../../../core/data/write_result.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

/// Stores the profile in `users/{uid}`.
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(
    this._firestore, {
    required this.uid,
    this.ackTimeout = defaultAckTimeout,
  });

  final FirebaseFirestore _firestore;
  final String uid;
  final Duration ackTimeout;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(uid);

  @override
  Stream<UserProfile?> watch() => _doc
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return UserProfile(
          displayName: data['displayName'] as String? ?? '',
          currency: data['currency'] as String? ?? UserProfile.defaultCurrency,
          themeMode: ThemeMode.values.firstWhere(
            (m) => m.name == data['themeMode'],
            orElse: () => ThemeMode.system,
          ),
        );
      })
      .transform(mapFirestoreErrors());

  /// Writes the whole document, so the first save creates it.
  @override
  Future<WriteResult> save(UserProfile profile) => runFirestoreWrite(
    () => _doc.set({
      'displayName': profile.displayName.trim(),
      'currency': profile.currency,
      'themeMode': profile.themeMode.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
    ackTimeout: ackTimeout,
  );
}
