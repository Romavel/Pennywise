import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';

import '../../../core/errors/firestore_errors.dart';
import '../../../core/utils/month.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';

/// Stores transactions in `users/{uid}/transactions`.
class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository(
    this._firestore, {
    required this.uid,
    required this.currency,
    this.ackTimeout = const Duration(seconds: 8),
  });

  final FirebaseFirestore _firestore;
  final String uid;

  /// Currency recorded with new transactions.
  final String currency;

  /// How long to wait for the server before reporting a write as
  /// [WriteResult.pendingSync]. Firestore keeps offline writes on the device
  /// and their futures complete only once they reach the server.
  final Duration ackTimeout;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('transactions');

  @override
  Stream<List<Transaction>> watchMonth(Month month) => _collection
      .where(
        'occurredAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(month.start),
      )
      .where('occurredAt', isLessThan: Timestamp.fromDate(month.end))
      .orderBy('occurredAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_fromDoc).nonNulls.toList())
      .transform(_mapErrors());

  @override
  Stream<Transaction?> watchById(String id) => _collection
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? _fromDoc(doc) : null)
      .transform(_mapErrors());

  @override
  Future<WriteResult> create(TransactionDraft draft) => _write(
    () => _collection.doc().set({
      ..._fields(draft),
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<WriteResult> update(String id, TransactionDraft draft) => _write(
    () => _collection.doc(id).update({
      ..._fields(draft),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<WriteResult> delete(String id) =>
      _write(() => _collection.doc(id).delete());

  static Map<String, Object> _fields(TransactionDraft draft) => {
    'type': draft.type.name,
    'amountMinor': draft.amountMinor,
    'categoryId': draft.categoryId,
    'note': draft.note.trim(),
    'occurredAt': Timestamp.fromDate(draft.occurredAt),
  };

  /// Returns `null` for documents that don't match the schema, so one bad
  /// document can't break the whole list.
  static Transaction? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    try {
      return Transaction(
        id: doc.id,
        type: TransactionType.parse(data['type'] as String),
        amountMinor: data['amountMinor'] as int,
        currency: data['currency'] as String,
        categoryId: data['categoryId'] as String,
        note: data['note'] as String? ?? '',
        occurredAt: (data['occurredAt'] as Timestamp).toDate(),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    } on Object catch (e) {
      // Only the id and error type are logged, never the document content.
      debugPrint('Skipping malformed transaction ${doc.id}: ${e.runtimeType}');
      return null;
    }
  }

  Future<WriteResult> _write(Future<void> Function() action) async {
    try {
      await action().timeout(ackTimeout);
      return WriteResult.saved;
    } on TimeoutException {
      return WriteResult.pendingSync;
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  static StreamTransformer<T, T> _mapErrors<T>() =>
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) => sink.addError(
          error is FirebaseException ? mapFirestoreException(error) : error,
          stackTrace,
        ),
      );
}
