import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/data/write_result.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/month.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/state_views.dart';
import '../../transactions/data/transaction_providers.dart';
import '../data/budget_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_progress.dart';
import 'budget_form_sheet.dart';
import 'budget_widgets.dart';
import 'budgets_controller.dart';
import '../../settings/data/profile_providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetsMonthProvider);
    final overview = ref.watch(budgetOverviewProvider(month));
    final notifier = ref.read(budgetsMonthProvider.notifier);
    final taken = {
      for (final p in overview.value?.items ?? const <BudgetProgress>[])
        p.budget.categoryId,
      if (overview.value?.overall != null) Budget.overallCategoryId,
    };

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Budgets',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, AppSpacing.minTouchTarget),
                          padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                          shape: const StadiumBorder(),
                          textStyle: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(fontSize: 14),
                        ),
                        onPressed: overview.hasValue
                            ? () => showBudgetFormSheet(
                                context,
                                month: month,
                                takenCategoryIds: taken,
                              )
                            : null,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New budget'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MonthSwitcher(
                    month: month,
                    onPrevious: notifier.previous,
                    onNext: notifier.next,
                  ),
                ],
              ),
            ),
            ...overview.when(
              data: (data) => data.isEmpty
                  ? [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyBudgets(month: month),
                      ),
                    ]
                  : [_content(context, ref, data, month)],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    error: error,
                    onRetry: () {
                      ref.invalidate(monthBudgetsProvider(month));
                      ref.invalidate(monthTransactionsProvider(month));
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

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    BudgetOverview data,
    Month month,
  ) {
    final currency = ref.watch(currencyProvider);
    final overLimit = data.overLimit;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        24,
      ),
      sliver: SliverList.list(
        children: [
          _SummaryCard(
            overview: data,
            currency: currency,
            onTap: data.overall == null
                ? null
                : () => context.push(
                    AppRoutes.budgetDetail(data.overall!.budget.id),
                  ),
          ),
          if (data.categoryLimitsExceedOverall) ...[
            const SizedBox(height: 10),
            _Hint(
              'Your category limits add up to $currency '
              '${Money.format(data.categoryLimitsMinor)}, more than the '
              'overall budget.',
            ),
          ],
          if (overLimit.isNotEmpty) ...[
            const SizedBox(height: 14),
            OverLimitBanner(overLimit: overLimit, currency: currency),
          ],
          const SizedBox(height: 14),
          if (data.items.isEmpty)
            const _Hint('Add category budgets to see where the money goes.'),
          for (final p in data.items) ...[
            BudgetRow(
              progress: p,
              currency: currency,
              onTap: () => context.push(AppRoutes.budgetDetail(p.budget.id)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.overview,
    required this.currency,
    this.onTap,
  });

  final BudgetOverview overview;
  final String currency;

  /// Opens the overall budget, when there is one.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final remaining = overview.remainingMinor;
    final over = remaining < 0;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.heroCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      over
                          ? 'Over budget this month'
                          : 'Left to spend this month',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.heroMuted,
                      ),
                    ),
                  ),
                  Text(
                    overview.overall != null
                        ? 'Overall budget'
                        : 'Sum of category budgets',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.heroMuted,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colors.heroMuted,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$currency ${Money.format(remaining.abs())}',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.68,
                    color: over ? colors.heroExpense : colors.onHeroCard,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BudgetBar(
                ratio: overview.ratio,
                height: 10,
                color: over ? colors.heroExpense : colors.heroIncome,
                trackColor: colors.heroTile,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Spent ${Money.format(overview.spentMinor)} '
                      'of ${Money.format(overview.limitMinor)}',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.heroMuted,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
                  Text(
                    '${overview.percent}%',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onHeroCard,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBudgets extends ConsumerWidget {
  const _EmptyBudgets({required this.month});

  final Month month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previous = ref.watch(previousMonthBudgetsProvider(month));
    final copying = ref.watch(budgetActionsProvider).isLoading;

    return MessageView(
      icon: Icons.savings_outlined,
      title: 'No budgets for ${month.monthName}',
      message: previous.isEmpty
          ? 'Set a monthly limit for a category to see how much is left.'
          : 'Reuse last month’s limits or create a new budget.',
      action: previous.isEmpty
          ? FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create a budget'),
              onPressed: () => showBudgetFormSheet(context, month: month),
            )
          : FilledButton.icon(
              icon: const Icon(Icons.copy_all_outlined),
              label: Text(
                'Copy ${previous.length} from ${month.previous.monthName}',
              ),
              onPressed: copying ? null : () => _copy(context, ref, previous),
            ),
    );
  }

  Future<void> _copy(
    BuildContext context,
    WidgetRef ref,
    List<Budget> previous,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(budgetActionsProvider.notifier).copyTo(month, previous);
    final result = ref.read(budgetActionsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.hasError
              ? ErrorView.messageFor(result.error!)
              : result.value == WriteResult.pendingSync
              ? 'Budgets copied offline. They will sync when you’re back online.'
              : 'Budgets copied',
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: context.pwColors.mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
