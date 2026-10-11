import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/month.dart';
import '../../transactions/data/transaction_providers.dart';
import '../domain/dashboard_summary.dart';

/// Month shown on the dashboard. Kept while switching tabs.
final dashboardMonthProvider = NotifierProvider<DashboardMonthNotifier, Month>(
  DashboardMonthNotifier.new,
);

class DashboardMonthNotifier extends Notifier<Month> {
  @override
  Month build() => Month.current();

  void previous() => state = state.previous;
  void next() => state = state.next;
}

/// Summary for the selected month. Recomputed whenever any transaction
/// changes, so adding or editing one updates the dashboard immediately.
final dashboardSummaryProvider =
    Provider.autoDispose<AsyncValue<DashboardSummary>>((ref) {
      final month = ref.watch(dashboardMonthProvider);
      return ref
          .watch(allTransactionsProvider)
          .whenData((all) => DashboardSummary.of(all, month));
    });
