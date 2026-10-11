import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/month.dart';
import '../../../core/widgets/state_views.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/transaction_tile.dart';
import '../data/budget_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_progress.dart';
import '../domain/category_history.dart';
import 'budget_category.dart';
import 'budget_form_sheet.dart';
import 'budget_widgets.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  const BudgetDetailScreen({required this.budgetId, super.key});

  final String budgetId;

  @override
  ConsumerState<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen> {
  /// Last loaded budget. Kept when the budget disappears (e.g. right after
  /// the user deletes it here) so the screen can close normally instead of
  /// flashing "not found".
  Budget? _lastBudget;

  @override
  Widget build(BuildContext context) {
    final budgetId = widget.budgetId;
    final budget = ref.watch(budgetProvider(budgetId));
    final transactions = ref.watch(allTransactionsProvider);
    if (budget.value case final b?) _lastBudget = b;

    Widget scaffold(Widget body) => Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: body,
    );

    return switch ((_lastBudget, budget, transactions)) {
      (final b?, _, AsyncData(value: final t)) => _BudgetDetail(
        budget: b,
        transactions: t,
      ),
      (null, AsyncData(value: null), _) => scaffold(
        MessageView(
          icon: Icons.savings_outlined,
          title: 'Budget not found',
          message: 'It may have been deleted on another device.',
          action: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to budgets'),
          ),
        ),
      ),
      (_, AsyncError(:final error), _) ||
      (_, _, AsyncError(:final error)) => scaffold(
        ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(budgetProvider(budgetId));
            ref.invalidate(allTransactionsProvider);
          },
        ),
      ),
      _ => scaffold(const LoadingView()),
    };
  }
}

class _BudgetDetail extends ConsumerWidget {
  const _BudgetDetail({required this.budget, required this.transactions});

  final Budget budget;
  final List<Transaction> transactions;

  static const _historyLength = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = categoryForBudget(budget.categoryId);
    final progress = BudgetProgress.of(budget, transactions);
    final history = categorySpendingByMonth(
      transactions,
      categoryId: budget.isOverall ? null : budget.categoryId,
      months: monthsEndingAt(budget.month, _historyLength),
    );
    final monthTransactions =
        transactions
            .where(
              (t) =>
                  !t.isIncome &&
                  (budget.isOverall || t.categoryId == budget.categoryId) &&
                  budget.month.contains(t.occurredAt),
            )
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final colors = context.pwColors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            8,
            AppSpacing.screenHorizontal,
            24,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back to budgets',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.card,
                    fixedSize: const Size.square(AppSpacing.minTouchTarget),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(fontSize: 24),
                      ),
                      Text(
                        budget.month.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.mutedText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit budget limit',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.card,
                    fixedSize: const Size.square(AppSpacing.minTouchTarget),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await showBudgetFormSheet(
                      context,
                      month: budget.month,
                      existing: budget,
                    );
                    if (result == BudgetSheetResult.deleted &&
                        context.mounted) {
                      context.pop();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProgressCard(progress: progress),
            const SizedBox(height: 14),
            _HistoryCard(
              history: history,
              limitMinor: budget.limitMinor,
              currency: budget.currency,
            ),
            const SizedBox(height: 14),
            _Card(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: _CardTitle(
                      budget.isOverall ? 'Expenses' : 'Transactions',
                    ),
                  ),
                  if (monthTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        budget.isOverall
                            ? 'No expenses in ${budget.month.monthName}.'
                            : 'No ${category.name.toLowerCase()} expenses '
                                  'in ${budget.month.monthName}.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    )
                  else
                    for (final t in monthTransactions)
                      TransactionTile(
                        transaction: t,
                        showDivider: true,
                        showDate: true,
                        horizontalPadding: 0,
                        onTap: () =>
                            context.push(AppRoutes.transactionEdit(t.id)),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;
    final status = progress.status;
    final statusColor = status.color(colors);
    final currency = progress.budget.currency;

    final (IconData icon, String message) = switch (status) {
      BudgetStatus.over => (
        Icons.warning_amber_rounded,
        '$currency ${Money.format(progress.overMinor)} over your limit',
      ),
      BudgetStatus.near => (
        Icons.info_outline,
        'Only $currency ${Money.format(progress.remainingMinor)} left',
      ),
      BudgetStatus.ok => (
        Icons.check_circle_outline,
        '$currency ${Money.format(progress.remainingMinor)} left to spend',
      ),
    };

    Widget stat(String label, String value, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );

    return _Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent this month', style: textTheme.labelMedium),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$currency ${Money.format(progress.spentMinor)}',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.68,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.percent}%',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: status == BudgetStatus.ok
                      ? Theme.of(context).colorScheme.onSurface
                      : statusColor,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BudgetBar(ratio: progress.ratio, color: statusColor, height: 12),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: status == BudgetStatus.over
                    ? colors.warningBackground
                    : colors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: status == BudgetStatus.over
                        ? colors.warningForeground
                        : statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: status == BudgetStatus.over
                            ? colors.warningForeground
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              stat('Limit', Money.format(progress.limitMinor)),
              stat('Spent', Money.format(progress.spentMinor)),
              stat(
                'Remaining',
                progress.remainingMinor < 0
                    ? '−${Money.format(-progress.remainingMinor)}'
                    : Money.format(progress.remainingMinor),
                color: progress.remainingMinor < 0 ? colors.expense : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({
    required this.history,
    required this.limitMinor,
    required this.currency,
  });

  final List<({Month month, int spentMinor})> history;
  final int limitMinor;
  final String currency;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final history = widget.history;
    final limit = widget.limitMinor / 100;
    final maxSpent =
        history.fold(0, (m, h) => h.spentMinor > m ? h.spentMinor : m) / 100;
    final maxY = (maxSpent > limit ? maxSpent : limit) * 1.25;
    final overCount = history
        .where((h) => h.spentMinor > widget.limitMinor)
        .length;
    final monthFormat = DateFormat('MMM', 'en_US');

    final description = history
        .map(
          (h) =>
              '${monthFormat.format(h.month.start)} ${Money.format(h.spentMinor)}',
        )
        .join(', ');

    return _Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _CardTitle('Last ${history.length} months')),
              Container(width: 14, height: 2, color: colors.mutedText),
              const SizedBox(width: 6),
              Text(
                'Limit ${Money.formatWhole(widget.limitMinor)}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label:
                'Spending by month: $description ${widget.currency}, '
                'limit ${Money.format(widget.limitMinor)}',
            excludeSemantics: true,
            child: SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  maxY: maxY == 0 ? 1 : maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(bottom: BorderSide(color: scheme.outline)),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: limit,
                        color: colors.mutedText,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          final last = i == history.length - 1;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              monthFormat.format(history[i].month.start),
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: last
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: last
                                    ? scheme.onSurface
                                    : colors.mutedText,
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
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        '${monthFormat.format(history[group.x].month.start)}\n'
                        '${widget.currency} ${Money.format(history[group.x].spentMinor)}',
                        textTheme.labelMedium!.copyWith(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (final (i, h) in history.indexed)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: h.spentMinor / 100,
                            width: 22,
                            color: h.spentMinor > widget.limitMinor
                                ? colors.accent
                                : scheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            overCount == 0
                ? 'Within the current limit in all of the last ${history.length} months.'
                : 'Over the current limit in $overCount of the last ${history.length} months.',
            style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.pwColors.card,
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
