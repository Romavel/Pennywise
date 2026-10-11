import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/month.dart';
import '../data/transaction_providers.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_repository.dart';
import '../../categories/data/category_providers.dart';

/// Filters of the transaction list. Kept while the user switches tabs.
final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter(month: Month.current());

  void previousMonth() => state = state.copyWith(month: state.month.previous);

  void nextMonth() => state = state.copyWith(month: state.month.next);

  void setType(TransactionType? type) {
    // A category of the other type would hide everything, so drop it.
    final category = state.categoryId;
    state = state.copyWith(
      type: () => type,
      categoryId: () =>
          type != null && category != null && !_matches(category, type)
          ? null
          : category,
    );
  }

  void setCategory(String? categoryId) =>
      state = state.copyWith(categoryId: () => categoryId);

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleSort() => state = state.copyWith(
    sort: state.sort == TransactionSort.newestFirst
        ? TransactionSort.oldestFirst
        : TransactionSort.newestFirst,
  );

  /// Replaces the whole filter, e.g. when opening the list from the
  /// dashboard for a given month.
  void showOnly(TransactionFilter filter) => state = filter;

  void clearNarrowing() =>
      state = TransactionFilter(month: state.month, sort: state.sort);

  bool _matches(String categoryId, TransactionType type) {
    final catalog = ref.read(categoryCatalogProvider);
    return !catalog.contains(categoryId) ||
        catalog.byId(categoryId).type == type;
  }
}

/// What the list shows for the current filter.
@immutable
class TransactionListData {
  const TransactionListData({
    required this.monthTotals,
    required this.groups,
    required this.monthIsEmpty,
  });

  /// Totals of the whole month, regardless of type/category/search.
  final TransactionTotals monthTotals;
  final List<DayGroup> groups;

  /// No transactions at all this month (as opposed to none matching).
  final bool monthIsEmpty;
}

final transactionListProvider =
    Provider.autoDispose<AsyncValue<TransactionListData>>((ref) {
      final filter = ref.watch(transactionFilterProvider);
      return ref
          .watch(monthTransactionsProvider(filter.month))
          .whenData(
            (all) => TransactionListData(
              monthTotals: TransactionTotals.of(all),
              groups: groupByDay(filter.apply(all)),
              monthIsEmpty: all.isEmpty,
            ),
          );
    });

/// Saving or deleting from the transaction form.
final transactionFormControllerProvider =
    NotifierProvider.autoDispose<
      TransactionFormController,
      AsyncValue<WriteResult?>
    >(TransactionFormController.new);

class TransactionFormController extends Notifier<AsyncValue<WriteResult?>> {
  @override
  AsyncValue<WriteResult?> build() => const AsyncData(null);

  /// Creates a transaction, or updates [id] when given.
  Future<void> save(TransactionDraft draft, {String? id}) => _run((repo) {
    return id == null ? repo.create(draft) : repo.update(id, draft);
  });

  Future<void> delete(String id) => _run((repo) => repo.delete(id));

  Future<void> _run(
    Future<WriteResult> Function(TransactionRepository repo) action,
  ) async {
    // Ignore repeated taps while a write is in flight.
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => action(ref.read(transactionRepositoryProvider)),
    );
    if (ref.mounted) state = result;
  }
}
