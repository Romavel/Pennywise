import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/data/firestore_helpers.dart';
import '../../../core/data/write_result.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/category_catalog.dart';
import '../domain/category_repository.dart';
import '../domain/default_categories.dart';

/// Stores categories in `users/{uid}/categories/{id}`:
///
/// * a built-in id (e.g. `food`) holds only the user's name for it;
/// * a `custom_…` id holds a full custom category.
class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(
    this._firestore, {
    required this.uid,
    this.ackTimeout = defaultAckTimeout,
    Random? random,
  }) : _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final String uid;
  final Duration ackTimeout;
  final Random _random;

  DocumentReference<Map<String, dynamic>> get _user =>
      _firestore.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _collection =>
      _user.collection('categories');

  @override
  Stream<UserCategories> watch() => _collection
      .snapshots()
      .map((snapshot) {
        final renamed = <String, String>{};
        final custom = <CustomCategory>[];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            if (DefaultCategories.exists(doc.id)) {
              renamed[doc.id] = data['name'] as String;
            } else if (CustomCategory.idPattern.hasMatch(doc.id)) {
              custom.add(
                CustomCategory(
                  id: doc.id,
                  name: data['name'] as String,
                  type: TransactionType.parse(data['type'] as String),
                  iconKey: data['icon'] as String,
                  toneKey: data['tone'] as String,
                ),
              );
            }
          } on Object catch (e) {
            debugPrint(
              'Skipping malformed category ${doc.id}: ${e.runtimeType}',
            );
          }
        }
        custom.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return UserCategories(renamed: renamed, custom: custom);
      })
      .transform(mapFirestoreErrors());

  @override
  Future<WriteResult> rename(String builtInId, String name) => _write(
    () => _collection.doc(builtInId).set({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<WriteResult> resetName(String builtInId) =>
      _write(() => _collection.doc(builtInId).delete());

  @override
  Future<WriteResult> createCustom({
    required String name,
    required TransactionType type,
    required String iconKey,
    required String toneKey,
  }) => _write(
    () => _collection.doc(_newId()).set({
      'name': name.trim(),
      'type': type.name,
      'icon': iconKey,
      'tone': toneKey,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<WriteResult> updateCustom(CustomCategory category) => _write(
    () => _collection.doc(category.id).update({
      'name': category.name.trim(),
      'icon': category.iconKey,
      'tone': category.toneKey,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<WriteResult> deleteCustom(String id) => _write(() async {
    final budgets = await _user
        .collection('budgets')
        .where('categoryId', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (final doc in budgets.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_collection.doc(id));
    await batch.commit();
  });

  String _newId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final suffix = List.generate(
      16,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return 'custom_$suffix';
  }

  Future<WriteResult> _write(Future<void> Function() action) =>
      runFirestoreWrite(action, ackTimeout: ackTimeout);
}
