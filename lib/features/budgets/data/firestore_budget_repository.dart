import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/data/firestore_helpers.dart';
import '../../../core/data/write_result.dart';
import '../../../core/utils/month.dart';
import '../domain/budget.dart';
import '../domain/budget_repository.dart';

/// Stores budgets in `users/{uid}/budgets/{yyyy-MM}_{categoryId}`.
class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository(
    this._firestore, {
    required this.uid,
    required this.currency,
    this.ackTimeout = defaultAckTimeout,
  });

  final FirebaseFirestore _firestore;
  final String uid;
  final String currency;
  final Duration ackTimeout;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('budgets');

  @override
  Stream<List<Budget>> watchMonth(Month month) => _collection
      .where('monthKey', isEqualTo: month.key)
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).nonNulls.toList())
      .transform(mapFirestoreErrors());

  @override
  Stream<List<Budget>> watchAll() => _collection
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).nonNulls.toList())
      .transform(mapFirestoreErrors());

  @override
  Stream<Budget?> watchById(String id) => _collection
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? _fromDoc(doc) : null)
      .transform(mapFirestoreErrors());

  @override
  Future<WriteResult> create({
    required String categoryId,
    required Month month,
    required int limitMinor,
  }) => runFirestoreWrite(
    () => _collection
        .doc(Budget.idFor(month, categoryId))
        .set(_newDocument(categoryId, month, limitMinor)),
    ackTimeout: ackTimeout,
  );

  @override
  Future<WriteResult> updateLimit(String id, int limitMinor) =>
      runFirestoreWrite(
        () => _collection.doc(id).update({
          'limitMinor': limitMinor,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        ackTimeout: ackTimeout,
      );

  @override
  Future<WriteResult> delete(String id) => runFirestoreWrite(
    () => _collection.doc(id).delete(),
    ackTimeout: ackTimeout,
  );

  @override
  Future<WriteResult> copyTo(Month to, List<Budget> budgets) =>
      runFirestoreWrite(() {
        final batch = _firestore.batch();
        for (final b in budgets) {
          batch.set(
            _collection.doc(Budget.idFor(to, b.categoryId)),
            _newDocument(b.categoryId, to, b.limitMinor),
          );
        }
        return batch.commit();
      }, ackTimeout: ackTimeout);

  Map<String, Object> _newDocument(
    String categoryId,
    Month month,
    int limitMinor,
  ) => {
    'categoryId': categoryId,
    'monthKey': month.key,
    'limitMinor': limitMinor,
    'currency': currency,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static Budget? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    try {
      return Budget(
        categoryId: data['categoryId'] as String,
        month: Month.parse(data['monthKey'] as String),
        limitMinor: data['limitMinor'] as int,
        currency: data['currency'] as String,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    } on Object catch (e) {
      debugPrint('Skipping malformed budget ${doc.id}: ${e.runtimeType}');
      return null;
    }
  }
}
