import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/transactions/data/firestore_transaction_repository.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';
import 'package:pennywise/features/transactions/domain/transaction_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreTransactionRepository repository;

  const october = Month(2026, 10);
  final draft = TransactionDraft(
    type: TransactionType.expense,
    amountMinor: 4599,
    categoryId: 'food',
    occurredAt: DateTime(2026, 10, 11, 12),
    note: '  Groceries ',
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreTransactionRepository(
      firestore,
      uid: 'alice',
      currency: 'PLN',
    );
  });

  CollectionReference<Map<String, dynamic>> collectionOf(String uid) =>
      firestore.collection('users').doc(uid).collection('transactions');

  test('create stores the schema under the user and trims the note', () async {
    expect(await repository.create(draft), WriteResult.saved);

    final docs = (await collectionOf('alice').get()).docs;
    expect(docs, hasLength(1));
    final data = docs.single.data();
    expect(data['type'], 'expense');
    expect(data['amountMinor'], 4599);
    expect(data['currency'], 'PLN');
    expect(data['categoryId'], 'food');
    expect(data['note'], 'Groceries');
    expect(data['occurredAt'], isA<Timestamp>());
    expect(data.keys, containsAll(['createdAt', 'updatedAt']));
  });

  test('watchMonth returns only that month, newest first', () async {
    await repository.create(draft);
    await repository.create(
      TransactionDraft(
        type: TransactionType.income,
        amountMinor: 100000,
        categoryId: 'salary',
        occurredAt: DateTime(2026, 10, 31, 23, 59),
      ),
    );
    // Boundaries: first moment of next month and last of previous one.
    await repository.create(
      TransactionDraft(
        type: TransactionType.expense,
        amountMinor: 1,
        categoryId: 'other',
        occurredAt: DateTime(2026, 11),
      ),
    );
    await repository.create(
      TransactionDraft(
        type: TransactionType.expense,
        amountMinor: 2,
        categoryId: 'other',
        occurredAt: DateTime(2026, 9, 30, 23, 59),
      ),
    );

    final result = await repository.watchMonth(october).first;
    expect(result.map((t) => t.amountMinor), [100000, 4599]);
    expect(result.first.type, TransactionType.income);
  });

  test('does not see other users\' transactions', () async {
    await FirestoreTransactionRepository(
      firestore,
      uid: 'bob',
      currency: 'PLN',
    ).create(draft);

    expect(await repository.watchMonth(october).first, isEmpty);
  });

  test('update and delete change the stored document', () async {
    await repository.create(draft);
    final id = (await collectionOf('alice').get()).docs.single.id;

    await repository.update(
      id,
      TransactionDraft(
        type: TransactionType.expense,
        amountMinor: 8640,
        categoryId: 'shopping',
        occurredAt: DateTime(2026, 10, 12),
        note: 'Jacket',
      ),
    );
    final updated = await repository.watchById(id).first;
    expect(updated?.amountMinor, 8640);
    expect(updated?.categoryId, 'shopping');
    expect(updated?.currency, 'PLN');

    await repository.delete(id);
    expect(await repository.watchById(id).first, isNull);
  });

  test('skips documents that do not match the schema', () async {
    await repository.create(draft);
    await collectionOf('alice').add({
      'type': 'transfer',
      'amountMinor': 'lots',
      'occurredAt': Timestamp.fromDate(DateTime(2026, 10, 5)),
    });

    final result = await repository.watchMonth(october).first;
    expect(result, hasLength(1));
  });
}
