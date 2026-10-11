import 'package:flutter/foundation.dart';

import '../../transactions/domain/transaction.dart';
import 'budget.dart';

enum BudgetStatus {
  /// Under 90% of the limit.
  ok,

  /// 90% of the limit or more, but not over it.
  near,

  /// Spending exceeds the limit.
  over,
}

/// How much of a budget has been used.
@immutable
class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spentMinor});

  /// Sums the expenses of the budget's category in the budget's month.
  /// Income never counts against a budget.
  factory BudgetProgress.of(Budget budget, Iterable<Transaction> transactions) {
    var spent = 0;
    for (final t in transactions) {
      if (!t.isIncome &&
          t.categoryId == budget.categoryId &&
          budget.month.contains(t.occurredAt)) {
        spent += t.amountMinor;
      }
    }
    return BudgetProgress(budget: budget, spentMinor: spent);
  }

  static const nearThreshold = 0.9;

  final Budget budget;
  final int spentMinor;

  int get limitMinor => budget.limitMinor;

  /// Negative when over the limit.
  int get remainingMinor => limitMinor - spentMinor;

  int get overMinor => remainingMinor < 0 ? -remainingMinor : 0;

  /// Spent / limit; can exceed 1.
  double get ratio => limitMinor == 0 ? 0 : spentMinor / limitMinor;

  int get percent => (ratio * 100).round();

  BudgetStatus get status => spentMinor > limitMinor
      ? BudgetStatus.over
      : ratio >= nearThreshold
      ? BudgetStatus.near
      : BudgetStatus.ok;
}

/// All budgets of one month with their progress.
@immutable
class BudgetOverview {
  const BudgetOverview(this.items);

  /// Largest limits first, like the design.
  factory BudgetOverview.of(
    Iterable<Budget> budgets,
    Iterable<Transaction> transactions,
  ) {
    final list = transactions.toList();
    return BudgetOverview(
      budgets.map((b) => BudgetProgress.of(b, list)).toList()..sort((a, b) {
        final byLimit = b.limitMinor.compareTo(a.limitMinor);
        return byLimit != 0
            ? byLimit
            : a.budget.categoryId.compareTo(b.budget.categoryId);
      }),
    );
  }

  final List<BudgetProgress> items;

  bool get isEmpty => items.isEmpty;

  int get limitMinor => items.fold(0, (sum, p) => sum + p.limitMinor);
  int get spentMinor => items.fold(0, (sum, p) => sum + p.spentMinor);
  int get remainingMinor => limitMinor - spentMinor;
  double get ratio => limitMinor == 0 ? 0 : spentMinor / limitMinor;
  int get percent => (ratio * 100).round();

  List<BudgetProgress> get overLimit =>
      items.where((p) => p.status == BudgetStatus.over).toList();
}
