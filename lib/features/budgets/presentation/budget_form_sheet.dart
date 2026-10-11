import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/write_result.dart';
import '../../../core/utils/amount_input_formatter.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/month.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_icon.dart';
import '../domain/budget.dart';
import 'budget_category.dart';
import 'budgets_controller.dart';
import '../../settings/data/profile_providers.dart';
import '../../categories/data/category_providers.dart';
import '../../transactions/domain/transaction.dart';

enum BudgetSheetResult { saved, deleted }

/// Opens the sheet for a new budget in [month], or for changing the limit
/// of [existing]. Returns what happened, or `null` if it was dismissed.
Future<BudgetSheetResult?> showBudgetFormSheet(
  BuildContext context, {
  required Month month,
  Budget? existing,
  Set<String> takenCategoryIds = const {},
}) {
  return showModalBottomSheet<BudgetSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BudgetFormSheet(
      month: month,
      existing: existing,
      takenCategoryIds: takenCategoryIds,
    ),
  );
}

class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({
    required this.month,
    this.existing,
    this.takenCategoryIds = const {},
    super.key,
  });

  final Month month;
  final Budget? existing;

  /// Categories that already have a budget this month.
  final Set<String> takenCategoryIds;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late String? _categoryId = widget.existing?.categoryId;
  late final _limit = TextEditingController(
    text: widget.existing == null
        ? ''
        : Money.toInput(widget.existing!.limitMinor),
  );
  var _showErrors = false;

  bool get _isEditing => widget.existing != null;

  /// The overall budget first, then expense categories without a budget.
  List<Category> get _available => [
    overallBudgetCategory,
    ...ref.read(categoryCatalogProvider).forType(TransactionType.expense),
  ].where((c) => !widget.takenCategoryIds.contains(c.id)).toList();

  String? get _limitError {
    final minor = Money.parseMinor(_limit.text.trim());
    if (minor == null || minor <= 0) return 'Enter a limit greater than 0.';
    return null;
  }

  String? get _categoryError =>
      _categoryId == null ? 'Choose a category.' : null;

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_limitError != null || _categoryError != null) {
      setState(() => _showErrors = true);
      return;
    }
    final limit = Money.parseMinor(_limit.text.trim())!;
    final actions = ref.read(budgetActionsProvider.notifier);
    if (_isEditing) {
      await actions.updateLimit(widget.existing!.id, limit);
    } else {
      await actions.create(
        categoryId: _categoryId!,
        month: widget.month,
        limitMinor: limit,
      );
    }
    _closeIfDone(
      _isEditing ? 'Budget updated' : 'Budget created',
      BudgetSheetResult.saved,
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text(
          'Your transactions stay as they are; only the limit is removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(budgetActionsProvider.notifier).delete(widget.existing!.id);
    _closeIfDone('Budget deleted', BudgetSheetResult.deleted);
  }

  void _closeIfDone(String message, BudgetSheetResult outcome) {
    if (!mounted) return;
    final result = ref.read(budgetActionsProvider);
    if (result.hasError) return;
    final offline = result.value == WriteResult.pendingSync;
    // Replace any earlier confirmation instead of queueing behind it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            offline
                ? '$message offline. It will sync when you’re back online.'
                : message,
          ),
        ),
      );
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetActionsProvider);
    final busy = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.pwColors;
    final String currency =
        widget.existing?.currency ?? ref.watch(currencyProvider);
    final existingCategory = _isEditing
        ? categoryForBudget(
            ref.watch(categoryCatalogProvider),
            widget.existing!.categoryId,
          )
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? '${existingCategory!.name} budget' : 'New budget',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              widget.month.label,
              style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
            ),
            const SizedBox(height: 18),
            if (!_isEditing) ...[
              Text(
                'Budget for',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_available.isEmpty)
                Text(
                  'Every category and the overall budget are already set '
                  'for this month.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.mutedText,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _available)
                      _CategoryChoice(
                        category: c,
                        selected: c.id == _categoryId,
                        onTap: busy
                            ? null
                            : () => setState(() => _categoryId = c.id),
                      ),
                  ],
                ),
              if (_showErrors && _categoryError != null) ...[
                const SizedBox(height: 6),
                _FieldError(_categoryError!),
              ],
              if (_categoryId == Budget.overallCategoryId && !_isEditing) ...[
                const SizedBox(height: 8),
                Text(
                  'Limits all of this month’s spending, whatever the category.',
                  style: textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 18),
            ],
            Text(
              'Monthly limit',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('budget-limit-field'),
              controller: _limit,
              enabled: !busy,
              autofocus: _isEditing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [amountInputFormatter],
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: '0.00',
                // Always visible, unlike prefixText (only shown when focused).
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(currency, style: textTheme.bodyLarge),
                ),
                prefixIconConstraints: const BoxConstraints(),
                errorText: _showErrors ? _limitError : null,
              ),
            ),
            if (state.hasError) ...[
              const SizedBox(height: 14),
              ErrorBanner(message: ErrorView.messageFor(state.error!)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy || (!_isEditing && _available.isEmpty)
                  ? null
                  : _save,
              child: Text(
                busy
                    ? 'Saving…'
                    : _isEditing
                    ? 'Save limit'
                    : 'Create budget',
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete budget'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          side: BorderSide(
            width: 2,
            color: selected ? scheme.primary : colors.track,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.input),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIcon(category: category, size: 28, radius: 8),
                const SizedBox(width: 8),
                Text(
                  category.name,
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

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
  );
}
