import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/state_views.dart';
import '../../categories/domain/default_categories.dart';
import '../../categories/presentation/category_icon.dart';
import '../data/transaction_providers.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';
import 'transaction_tile.dart';
import 'transactions_controller.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final _search = TextEditingController(
    text: ref.read(transactionFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(transactionFilterProvider.notifier).clearNarrowing();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final list = ref.watch(transactionListProvider);
    final textTheme = Theme.of(context).textTheme;

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
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transactions',
                          style: textTheme.headlineMedium,
                        ),
                      ),
                      _SortButton(
                        sort: filter.sort,
                        onTap: notifier.toggleSort,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SearchField(
                    controller: _search,
                    onChanged: notifier.setQuery,
                  ),
                  const SizedBox(height: 8),
                  _MonthSwitcher(
                    label: filter.month.label,
                    totals: list.value?.monthTotals,
                    onPrevious: notifier.previousMonth,
                    onNext: notifier.nextMonth,
                  ),
                  const SizedBox(height: 4),
                  _FilterBar(filter: filter),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ...list.when(
              data: (data) => _content(data, filter),
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(monthTransactionsProvider(filter.month)),
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

  List<Widget> _content(TransactionListData data, TransactionFilter filter) {
    if (data.groups.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: data.monthIsEmpty
              ? MessageView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions in ${filter.month.monthName}',
                  message: 'Add your first income or expense to see it here.',
                  action: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add transaction'),
                    onPressed: () => context.push(AppRoutes.transactionNew),
                  ),
                )
              : MessageView(
                  icon: Icons.search_off,
                  title: 'No matching transactions',
                  message: 'Try a different search or clear the filters.',
                  action: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ),
        ),
      ];
    }

    return [
      SliverPadding(
        // Leaves room for the floating add button.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          96,
        ),
        sliver: SliverList.builder(
          itemCount: data.groups.length,
          itemBuilder: (context, i) => _DaySection(group: data.groups[i]),
        ),
      ),
    ];
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.group});

  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
          child: Semantics(
            header: true,
            child: Text(
              Dates.dayHeader(group.day).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.72,
                color: colors.mutedText,
              ),
            ),
          ),
        ),
        Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadii.listGroup),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, t) in group.transactions.indexed)
                TransactionTile(
                  transaction: t,
                  showDivider: i > 0,
                  onTap: () => context.push(AppRoutes.transactionEdit(t.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onTap});

  final TransactionSort sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final newest = sort == TransactionSort.newestFirst;
    return Semantics(
      label: newest ? 'Sort: newest first' : 'Sort: oldest first',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: context.pwColors.card,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: AppSpacing.minTouchTarget,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  newest ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  newest ? 'Newest' : 'Oldest',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide.none,
    );

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search in notes',
          prefixIcon: Icon(Icons.search, color: colors.mutedText),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.totals,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final TransactionTotals? totals;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;
    final totalsStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Column(
            children: [
              Text(label, style: textTheme.titleSmall),
              const SizedBox(height: 1),
              if (totals case final totals?)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Money.formatSigned(
                          totals.incomeMinor,
                          positive: true,
                        ),
                        style: totalsStyle?.copyWith(color: colors.income),
                      ),
                      TextSpan(text: ' · ', style: textTheme.bodySmall),
                      TextSpan(
                        text: Money.formatSigned(
                          totals.expenseMinor,
                          positive: false,
                        ),
                        style: totalsStyle?.copyWith(color: colors.expense),
                      ),
                    ],
                  ),
                )
              else
                Text(' ', style: textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});

  final TransactionFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(transactionFilterProvider.notifier);
    final category = filter.categoryId == null
        ? null
        : DefaultCategories.byId(filter.categoryId!);

    return Semantics(
      label: 'Filter transactions',
      container: true,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (type, label) in [
            (null, 'All'),
            (TransactionType.income, 'Income'),
            (TransactionType.expense, 'Expenses'),
          ])
            _FilterPill(
              label: label,
              selected: filter.type == type,
              onTap: () => notifier.setType(type),
            ),
          _FilterPill(
            label: category?.name ?? 'Category',
            selected: category != null,
            trailing: Icons.expand_more,
            onTap: () => _pickCategory(context, notifier),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory(
    BuildContext context,
    TransactionFilterNotifier notifier,
  ) async {
    final categories = filter.type == null
        ? DefaultCategories.all
        : DefaultCategories.forType(filter.type!);

    final picked = await showModalBottomSheet<({String? id})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.apps),
                title: const Text('All categories'),
                selected: filter.categoryId == null,
                onTap: () => Navigator.pop(context, (id: null)),
              ),
              for (final c in categories)
                ListTile(
                  leading: CategoryIcon(category: c, size: 36, radius: 10),
                  title: Text(c.name),
                  selected: c.id == filter.categoryId,
                  trailing: c.id == filter.categoryId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, (id: c.id)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) notifier.setCategory(picked.id);
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.pwColors;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : colors.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? scheme.primary : scheme.outline),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: EdgeInsets.only(
              left: 14,
              right: trailing == null ? 14 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailing, size: 18, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
