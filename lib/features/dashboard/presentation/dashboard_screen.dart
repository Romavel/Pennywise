import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/month.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../budgets/domain/budget_progress.dart';
import '../../budgets/presentation/budget_widgets.dart';
import '../../budgets/presentation/budgets_controller.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/transaction_tile.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_controller.dart';
import 'spending_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(dashboardMonthProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final user = ref.watch(authStateProvider).value;
    final monthNotifier = ref.read(dashboardMonthProvider.notifier);

    final header = <Widget>[
      _Greeting(user: user),
      const SizedBox(height: 18),
      MonthSwitcher(
        month: month,
        onPrevious: monthNotifier.previous,
        onNext: monthNotifier.next,
      ),
      const SizedBox(height: 18),
    ];

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
                0,
              ),
              sliver: SliverList.list(children: header),
            ),
            ...summary.when(
              data: (data) => [
                SliverPadding(
                  // Room for the floating add button.
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    100,
                  ),
                  sliver: SliverList.list(children: _cards(context, ref, data)),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(allTransactionsProvider),
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

  List<Widget> _cards(
    BuildContext context,
    WidgetRef ref,
    DashboardSummary data,
  ) {
    final currency = ref.watch(currencyProvider);

    void openTransactions() {
      // Show the same month on the transactions tab.
      ref
          .read(transactionFilterProvider.notifier)
          .showOnly(TransactionFilter(month: data.month));
      context.go(AppRoutes.transactions);
    }

    return [
      _BalanceCard(summary: data, currency: currency),
      const SizedBox(height: 18),
      _Section(
        title: 'Budgets',
        actionLabel: 'See all',
        onAction: () {
          ref.read(budgetsMonthProvider.notifier).show(data.month);
          context.go(AppRoutes.budgets);
        },
        child: _BudgetSummary(month: data.month, currency: currency),
      ),
      const SizedBox(height: 18),
      _Section(
        title: 'Spending by category',
        actionLabel: 'Reports',
        onAction: () => context.go(AppRoutes.reports),
        child: data.spending.isEmpty
            ? _EmptyNote('No expenses in ${data.month.monthName} yet.')
            : SpendingChart(breakdown: data.spending, currency: currency),
      ),
      const SizedBox(height: 18),
      _Section(
        title: 'Recent transactions',
        actionLabel: 'See all',
        onAction: openTransactions,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
        child: data.recent.isEmpty
            ? _EmptyNote(
                data.hasAnyTransactions
                    ? 'No transactions in ${data.month.monthName}.'
                    : 'No transactions yet. Tap + to add your first one.',
              )
            : Column(
                children: [
                  for (final t in data.recent)
                    TransactionTile(
                      transaction: t,
                      showDate: true,
                      showDivider: true,
                      horizontalPadding: 0,
                      onTap: () =>
                          context.push(AppRoutes.transactionEdit(t.id)),
                    ),
                ],
              ),
      ),
    ];
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final AppUser? user;

  static String _salutation(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning,',
    < 18 => 'Good afternoon,',
    _ => 'Good evening,',
  };

  @override
  Widget build(BuildContext context) {
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email.split('@').first ?? '');
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _salutation(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: context.pwColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 26),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Profile and settings',
          excludeSemantics: true,
          child: Material(
            color: scheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go(AppRoutes.settings),
              child: SizedBox.square(
                dimension: AppSpacing.minTouchTarget,
                child: Center(
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.currency});

  final DashboardSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final balance = summary.balanceMinor;
    final balanceText =
        '${balance < 0 ? '−' : ''}$currency ${Money.format(balance.abs())}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.heroCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total balance',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.heroMuted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              balanceText,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.72,
                color: colors.onHeroCard,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Across all recorded transactions',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.heroMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroTile(
                  icon: Icons.south_west,
                  label: 'Income',
                  value: Money.formatSigned(
                    summary.monthTotals.incomeMinor,
                    positive: true,
                  ),
                  valueColor: colors.heroIncome,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroTile(
                  icon: Icons.north_east,
                  label: 'Expenses',
                  value: Money.formatSigned(
                    summary.monthTotals.expenseMinor,
                    positive: false,
                  ),
                  valueColor: colors.heroExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.heroTile,
        borderRadius: BorderRadius.circular(AppRadii.listGroup),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.heroMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(color: colors.heroMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White card with a title row and an optional link.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: context.pwColors.mutedText),
    ),
  );
}

/// Budget totals for the dashboard month.
class _BudgetSummary extends ConsumerWidget {
  const _BudgetSummary({required this.month, required this.currency});

  final Month month;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(budgetOverviewProvider(month));
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;

    return overview.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => _EmptyNote(ErrorView.messageFor(error)),
      data: (data) {
        if (data.isEmpty) {
          return _EmptyNote(
            'No budgets for ${month.monthName}. '
            'Set limits to track your spending.',
          );
        }
        final remaining = data.remainingMinor;
        final overCount = data.overLimit.length;
        final barColor = remaining < 0
            ? colors.budgetOver
            : data.ratio >= BudgetProgress.nearThreshold
            ? colors.budgetNear
            : colors.budgetOk;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$currency ${Money.format(data.spentMinor)}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: '  of ${Money.format(data.limitMinor)}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: colors.mutedText,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
            const SizedBox(height: 12),
            BudgetBar(ratio: data.ratio, color: barColor, height: 10),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    remaining < 0
                        ? '${data.percent}% used · '
                              '$currency ${Money.format(-remaining)} over'
                        : '${data.percent}% used · '
                              '$currency ${Money.format(remaining)} left',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.mutedText,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ),
                if (overCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: ShapeDecoration(
                      color: colors.warningBackground,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      '$overCount over limit',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.warningForeground,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
