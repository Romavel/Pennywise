import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/month.dart';
import '../../auth/data/auth_providers.dart';
import '../../transactions/data/transaction_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_repository.dart';
import 'firestore_budget_repository.dart';

/// Budgets of the signed-in user; rebuilt when the user changes.
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final uid = ref.watch(authStateProvider.select((auth) => auth.value?.uid));
  if (uid == null) {
    throw StateError('Budgets are only available when signed in.');
  }
  return FirestoreBudgetRepository(
    FirebaseFirestore.instance,
    uid: uid,
    currency: ref.watch(currencyProvider),
  );
});

final monthBudgetsProvider = StreamProvider.autoDispose
    .family<List<Budget>, Month>(
      (ref, month) => ref.watch(budgetRepositoryProvider).watchMonth(month),
    );

final allBudgetsProvider = StreamProvider.autoDispose<List<Budget>>(
  (ref) => ref.watch(budgetRepositoryProvider).watchAll(),
);

final budgetProvider = StreamProvider.autoDispose.family<Budget?, String>(
  (ref, id) => ref.watch(budgetRepositoryProvider).watchById(id),
);
