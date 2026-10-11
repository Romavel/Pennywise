import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/month.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';
import 'firestore_transaction_repository.dart';
import '../../settings/data/profile_providers.dart';

/// Transactions of the signed-in user. Rebuilt when the user changes, so
/// one account can never read another account's data from a stale instance.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final uid = ref.watch(authStateProvider.select((auth) => auth.value?.uid));
  if (uid == null) {
    throw StateError('Transactions are only available when signed in.');
  }
  return FirestoreTransactionRepository(
    FirebaseFirestore.instance,
    uid: uid,
    currency: ref.watch(currencyProvider),
  );
});

final monthTransactionsProvider = StreamProvider.autoDispose
    .family<List<Transaction>, Month>(
      (ref, month) =>
          ref.watch(transactionRepositoryProvider).watchMonth(month),
    );

/// Every transaction of the user. Firestore serves repeat reads from its
/// local cache, so this stays cheap for a personal ledger; a server-side
/// running total would replace it if histories grow very large.
final allTransactionsProvider = StreamProvider.autoDispose<List<Transaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

final transactionProvider = StreamProvider.autoDispose
    .family<Transaction?, String>(
      (ref, id) => ref.watch(transactionRepositoryProvider).watchById(id),
    );
