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

  /// Sums the expenses of the budget's category in the budget's month, or
  /// all expenses of that month for the overall budget. Income never counts
  /// against a budget.
  factory BudgetProgress.of(Budget budget, Iterable<Transaction> transactions) {
    var spent = 0;
    for (final t in transactions) {
      if (!t.isIncome &&
          (budget.isOverall || t.categoryId == budget.categoryId) &&
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
  const BudgetOverview(this.items, {this.overall});

  /// Category budgets sorted by limit, largest first (like the design), and
  /// the overall budget kept apart.
  factory BudgetOverview.of(
    Iterable<Budget> budgets,
    Iterable<Transaction> transactions,
  ) {
    final list = transactions.toList();
    BudgetProgress? overall;
    final items = <BudgetProgress>[];
    for (final b in budgets) {
      final progress = BudgetProgress.of(b, list);
      if (b.isOverall) {
        overall = progress;
      } else {
        items.add(progress);
      }
    }
    items.sort((a, b) {
      final byLimit = b.limitMinor.compareTo(a.limitMinor);
      return byLimit != 0
          ? byLimit
          : a.budget.categoryId.compareTo(b.budget.categoryId);
    });
    return BudgetOverview(items, overall: overall);
  }

  /// Category budgets only.
  final List<BudgetProgress> items;

  /// The overall budget for all spending, if one is set.
  final BudgetProgress? overall;

  bool get isEmpty => items.isEmpty && overall == null;

  /// Sum of the category limits.
  int get categoryLimitsMinor => items.fold(0, (sum, p) => sum + p.limitMinor);

  /// The month's limit: the overall budget when set, otherwise the sum of
  /// the category budgets.
  int get limitMinor => overall?.limitMinor ?? categoryLimitsMinor;

  /// Spending counted against [limitMinor]: all expenses when there is an
  /// overall budget, otherwise only the budgeted categories.
  int get spentMinor =>
      overall?.spentMinor ?? items.fold(0, (sum, p) => sum + p.spentMinor);

  int get remainingMinor => limitMinor - spentMinor;
  double get ratio => limitMinor == 0 ? 0 : spentMinor / limitMinor;
  int get percent => (ratio * 100).round();

  /// Category limits that together allow more than the overall budget.
  bool get categoryLimitsExceedOverall =>
      overall != null && categoryLimitsMinor > overall!.limitMinor;

  /// Budgets over their limit, the overall budget first.
  List<BudgetProgress> get overLimit => [
    if (overall case final o? when o.status == BudgetStatus.over) o,
    ...items.where((p) => p.status == BudgetStatus.over),
  ];
}
