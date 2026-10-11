import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/segmented_switch.dart';
import '../../../core/widgets/state_views.dart';
import '../../budgets/data/budget_providers.dart';
import '../../budgets/presentation/budget_widgets.dart';
import '../../categories/domain/default_categories.dart';
import '../../dashboard/domain/spending_breakdown.dart';
import '../../dashboard/presentation/spending_chart.dart';
import '../../transactions/data/transaction_providers.dart';
import '../domain/report.dart';
import 'reports_controller.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final report = ref.watch(reportProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                8,
                AppSpacing.screenHorizontal,
                14,
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Reports',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 14),
                  SegmentedSwitch(
                    segments: [
                      for (final p in ReportPeriod.values) (p, p.label),
                    ],
                    selected: period,
                    onChanged: ref.read(reportPeriodProvider.notifier).set,
                  ),
                ],
              ),
            ),
            ...report.when(
              data: (data) => data.hasTransactions
                  ? [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          24,
                        ),
                        sliver: SliverList.list(
                          children: _cards(data, currency),
                        ),
                      ),
                    ]
                  : [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: MessageView(
                          icon: Icons.insights_outlined,
                          title: 'Nothing to report yet',
                          message:
                              'Add transactions to see trends for '
                              '${period == ReportPeriod.month ? 'this month' : 'the last ${period.label}'}.',
                        ),
                      ),
                    ],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    error: error,
                    onRetry: () {
                      ref.invalidate(allTransactionsProvider);
                      ref.invalidate(allBudgetsProvider);
                    },
                  ),
                ),
              ],
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingView(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cards(Report report, String currency) => [
    Row(
      children: [
        Expanded(
          child: _StatTile(
            label: report.period == ReportPeriod.month
                ? 'Spent this month'
                : 'Avg. monthly spend',
            value:
                '$currency ${Money.formatWhole(report.averageMonthlySpendMinor)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _ChangeTile(report: report)),
      ],
    ),
    const SizedBox(height: 14),
    _Card(
      title: 'Income vs expenses',
      trailing: const _IncomeExpenseLegend(),
      child: _IncomeExpenseChart(report: report, currency: currency),
    ),
    const SizedBox(height: 14),
    _Card(
      title: 'Top spending categories',
      trailing: _Caption(
        report.period == ReportPeriod.month
            ? report.current.monthName
            : 'Last ${report.period.label}',
      ),
      child: _TopCategories(report: report, currency: currency),
    ),
    const SizedBox(height: 14),
    _BudgetHistoryCard(report: report),
  ];
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.pwColors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodySmall);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.pwColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color ?? Theme.of(context).colorScheme.onSurface,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final change = report.spendingChange;
    final label = 'Spending vs ${report.current.previous.monthName}';
    if (change == null) return _StatTile(label: label, value: '—');

    final percent = (change.abs() * 100).round();
    final lower = change < 0;
    return Semantics(
      label: '$label: ${lower ? 'down' : 'up'} $percent percent',
      excludeSemantics: true,
      child: _StatTile(
        label: label,
        value: '$percent%',
        // Spending less is good news.
        color: percent == 0 ? null : (lower ? colors.income : colors.expense),
        icon: percent == 0
            ? null
            : (lower ? Icons.arrow_downward : Icons.arrow_upward),
      ),
    );
  }
}

class _IncomeExpenseLegend extends StatelessWidget {
  const _IncomeExpenseLegend();

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        item(Theme.of(context).colorScheme.primary, 'Income'),
        const SizedBox(width: 12),
        item(colors.accent, 'Expenses'),
      ],
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({required this.report, required this.currency});

  final Report report;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final months = report.months;
    final monthFormat = DateFormat(
      months.length > 6 ? 'MMMMM' : 'MMM',
      'en_US',
    );
    final barWidth = months.length > 6 ? 7.0 : 12.0;

    final maxValue = months.fold<int>(
      0,
      (m, t) =>
          math.max(m, math.max(t.totals.incomeMinor, t.totals.expenseMinor)),
    );
    final interval = _niceInterval(maxValue / 100);
    // Round the top up to the next step above the data, not a fixed 3 steps.
    final maxY = math.max(1, (maxValue / 100 / interval).ceil()) * interval;
    final compact = NumberFormat.compact(locale: 'en_US');

    final description = months
        .map(
          (m) =>
              '${DateFormat('MMMM', 'en_US').format(m.month.start)}: income '
              '${Money.format(m.totals.incomeMinor)}, expenses '
              '${Money.format(m.totals.expenseMinor)}',
        )
        .join('; ');

    return Semantics(
      label: 'Income and expenses by month in $currency. $description',
      excludeSemantics: true,
      child: SizedBox(
        height: 150,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: colors.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(bottom: BorderSide(color: scheme.outline)),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: interval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      compact.format(value),
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colors.mutedText,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    final last = i == months.length - 1;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        monthFormat.format(months[i].month.start),
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: last ? FontWeight.w700 : FontWeight.w500,
                          color: last ? scheme.onSurface : colors.mutedText,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItem: (group, _, rod, rodIndex) {
                  final m = months[group.x];
                  return rodIndex == 0
                      ? BarTooltipItem(
                          '${DateFormat('MMMM', 'en_US').format(m.month.start)}\n'
                          'Income ${Money.format(m.totals.incomeMinor)}\n'
                          'Expenses ${Money.format(m.totals.expenseMinor)}',
                          textTheme.labelMedium!.copyWith(
                            color: scheme.onInverseSurface,
                          ),
                        )
                      : null;
                },
              ),
            ),
            barGroups: [
              for (final (i, m) in months.indexed)
                BarChartGroupData(
                  x: i,
                  barsSpace: 3,
                  barRods: [
                    _rod(m.totals.incomeMinor, scheme.primary, barWidth),
                    _rod(m.totals.expenseMinor, colors.accent, barWidth),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static BarChartRodData _rod(int minor, Color color, double width) =>
      BarChartRodData(
        toY: minor / 100,
        color: color,
        width: width,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      );

  /// A round step so that three steps cover [max]: 1, 2, 2.5 or 5 × 10ⁿ.
  static double _niceInterval(double max) {
    if (max <= 0) return 1;
    final raw = max / 3;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    for (final step in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (step * magnitude >= raw) return step * magnitude;
    }
    return 10 * magnitude;
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.report, required this.currency});

  final Report report;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final top = report.topCategories;
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    if (top.isEmpty) {
      return Text(
        'No expenses in this period.',
        style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
      );
    }
    final largest = top.first.amountMinor;

    return Column(
      children: [
        for (final c in top) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  DefaultCategories.byId(c.categoryId).name,
                  style: textTheme.titleSmall?.copyWith(fontSize: 14),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$currency ${Money.format(c.amountMinor)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' · ${c.percent}%',
                      style: TextStyle(color: colors.mutedText),
                    ),
                  ],
                ),
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BudgetBar(
            ratio: c.amountMinor / largest,
            trackColor: colors.divider,
            color: spendingSlotColor(
              SpendingSlot.forCategory(c.categoryId),
              brightness,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BudgetHistoryCard extends StatelessWidget {
  const _BudgetHistoryCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final budgeted = report.monthsWithBudgets;

    Color colorFor(BudgetMonthOutcome outcome) => switch (outcome) {
      BudgetMonthOutcome.within => scheme.primary,
      BudgetMonthOutcome.over => colors.accent,
      BudgetMonthOutcome.none => colors.track,
    };
    String nameFor(BudgetMonthOutcome outcome) => switch (outcome) {
      BudgetMonthOutcome.within => 'within budget',
      BudgetMonthOutcome.over => 'over budget',
      BudgetMonthOutcome.none => 'no budget',
    };

    final summary = budgeted == 0
        ? 'No budgets set in this period'
        : 'Within budget ${report.monthsWithinBudget} of $budgeted '
              '${budgeted == 1 ? 'month' : 'months'}';
    final description = report.budgetHistory
        .map((h) => '${h.month.monthName} ${nameFor(h.outcome)}')
        .join(', ');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Budget history',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: description,
                excludeSemantics: true,
                child: Wrap(
                  spacing: report.budgetHistory.length > 6 ? 3 : 6,
                  children: [
                    for (final h in report.budgetHistory)
                      Container(
                        width: report.budgetHistory.length > 6 ? 8 : 14,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorFor(h.outcome),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (budgeted > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final outcome in BudgetMonthOutcome.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorFor(outcome),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        nameFor(outcome)[0].toUpperCase() +
                            nameFor(outcome).substring(1),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
