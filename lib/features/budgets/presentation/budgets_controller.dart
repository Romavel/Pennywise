import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/write_result.dart';
import '../../../core/utils/month.dart';
import '../../transactions/data/transaction_providers.dart';
import '../data/budget_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_progress.dart';
import '../domain/budget_repository.dart';

/// Month shown on the budgets tab. Kept while switching tabs.
final budgetsMonthProvider = NotifierProvider<BudgetsMonthNotifier, Month>(
  BudgetsMonthNotifier.new,
);

class BudgetsMonthNotifier extends Notifier<Month> {
  @override
  Month build() => Month.current();

  void previous() => state = state.previous;
  void next() => state = state.next;
  void show(Month month) => state = month;
}

/// Budgets of [Month] with their progress. Updates whenever a budget or a
/// transaction of that month changes.
final budgetOverviewProvider = Provider.autoDispose
    .family<AsyncValue<BudgetOverview>, Month>((ref, month) {
      final budgets = ref.watch(monthBudgetsProvider(month));
      final transactions = ref.watch(monthTransactionsProvider(month));
      return switch ((budgets, transactions)) {
        (AsyncData(value: final b), AsyncData(value: final t)) => AsyncData(
          BudgetOverview.of(b, t),
        ),
        (AsyncError(:final error, :final stackTrace), _) ||
        (
          _,
          AsyncError(:final error, :final stackTrace),
        ) => AsyncError(error, stackTrace),
        _ => const AsyncLoading(),
      };
    });

/// Budgets of the month before [Month], offered for copying when [Month]
/// has none.
final previousMonthBudgetsProvider = Provider.autoDispose
    .family<List<Budget>, Month>(
      (ref, month) =>
          ref.watch(monthBudgetsProvider(month.previous)).value ?? [],
    );

/// Creating, editing, deleting and copying budgets.
final budgetActionsProvider =
    NotifierProvider.autoDispose<BudgetActions, AsyncValue<WriteResult?>>(
      BudgetActions.new,
    );

class BudgetActions extends Notifier<AsyncValue<WriteResult?>> {
  @override
  AsyncValue<WriteResult?> build() => const AsyncData(null);

  Future<void> create({
    required String categoryId,
    required Month month,
    required int limitMinor,
  }) => _run(
    (repo) => repo.create(
      categoryId: categoryId,
      month: month,
      limitMinor: limitMinor,
    ),
  );

  Future<void> updateLimit(String id, int limitMinor) =>
      _run((repo) => repo.updateLimit(id, limitMinor));

  Future<void> delete(String id) => _run((repo) => repo.delete(id));

  Future<void> copyTo(Month to, List<Budget> budgets) =>
      _run((repo) => repo.copyTo(to, budgets));

  Future<void> _run(
    Future<WriteResult> Function(BudgetRepository repo) action,
  ) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => action(ref.read(budgetRepositoryProvider)),
    );
    if (ref.mounted) state = result;
  }
}
