import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/month.dart';
import '../../budgets/data/budget_providers.dart';
import '../../transactions/data/transaction_providers.dart';
import '../domain/report.dart';

/// Selected report period. Kept while switching tabs.
final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
      ReportPeriodNotifier.new,
    );

class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.sixMonths;

  void set(ReportPeriod period) => state = period;
}

/// The report for the selected period, ending with the current month.
final reportProvider = Provider.autoDispose<AsyncValue<Report>>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final transactions = ref.watch(allTransactionsProvider);
  final budgets = ref.watch(allBudgetsProvider);
  return switch ((transactions, budgets)) {
    (AsyncData(value: final t), AsyncData(value: final b)) => AsyncData(
      Report.of(
        transactions: t,
        budgets: b,
        period: period,
        current: Month.current(),
      ),
    ),
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});
