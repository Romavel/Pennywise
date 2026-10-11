import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/amount_input_formatter.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/segmented_switch.dart';
import '../../../core/widgets/state_views.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_icon.dart';
import '../data/transaction_providers.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';
import '../domain/transaction_validators.dart';
import 'transactions_controller.dart';
import '../../settings/data/profile_providers.dart';
import '../../categories/data/category_providers.dart';

/// Add a transaction, or edit [transactionId] when given.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({this.transactionId, super.key});

  final String? transactionId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  /// The transaction as first loaded. The form keeps editing this snapshot,
  /// so later stream events (including the local "deleted" event right
  /// after the user deletes it) don't replace the form mid-action.
  Transaction? _loaded;

  @override
  Widget build(BuildContext context) {
    final id = widget.transactionId;
    if (id == null) return const _TransactionForm();
    if (_loaded case final loaded?) {
      return _TransactionForm(key: ValueKey(id), initial: loaded);
    }

    final transaction = ref.watch(transactionProvider(id));
    return transaction.when(
      data: (t) {
        if (t == null) return const _Unavailable();
        _loaded = t;
        return _TransactionForm(key: ValueKey(id), initial: t);
      },
      error: (error, _) => Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(transactionProvider(id)),
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: const LoadingView(),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const CloseButton()),
    body: MessageView(
      icon: Icons.delete_outline,
      title: 'Transaction not found',
      message: 'It may have been deleted on another device.',
      action: OutlinedButton(
        onPressed: () => context.pop(),
        child: const Text('Back to transactions'),
      ),
    ),
  );
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({this.initial, super.key});

  /// The transaction being edited; `null` when adding.
  final Transaction? initial;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  late TransactionType _type = widget.initial?.type ?? TransactionType.expense;
  late String? _categoryId = widget.initial?.categoryId;
  late DateTime _date = widget.initial?.occurredAt ?? DateTime.now();
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toInput(widget.initial!.amountMinor),
  );
  late final _note = TextEditingController(text: widget.initial?.note ?? '');

  /// Errors are shown after the first submit attempt, then live.
  var _showErrors = false;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _amountError => TransactionValidators.amount(_amount.text);
  String? get _categoryError => TransactionValidators.category(_categoryId);

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      final current = _categoryId;
      if (current != null &&
          ref.read(categoryCatalogProvider).byId(current).type != type) {
        _categoryId = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    // Keep the time of day so the order within a day stays stable.
    setState(
      () => _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
        _date.second,
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_amountError != null || _categoryError != null) {
      setState(() => _showErrors = true);
      return;
    }

    final draft = TransactionDraft(
      type: _type,
      amountMinor: Money.parseMinor(_amount.text)!,
      categoryId: _categoryId!,
      occurredAt: _date,
      note: _note.text.trim(),
    );
    final controller = ref.read(transactionFormControllerProvider.notifier);
    await controller.save(draft, id: widget.initial?.id);
    if (!mounted) return;
    _finish(
      _isEditing ? 'Changes saved' : 'Transaction added',
      ref.read(transactionFormControllerProvider),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This can’t be undone.'),
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

    await ref
        .read(transactionFormControllerProvider.notifier)
        .delete(widget.initial!.id);
    if (!mounted) return;
    _finish('Transaction deleted', ref.read(transactionFormControllerProvider));
  }

  /// Closes the form after a successful write; errors stay on screen.
  void _finish(String message, AsyncValue<WriteResult?> result) {
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
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionFormControllerProvider);
    final busy = state.isLoading;
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      title: _isEditing
                          ? 'Edit transaction'
                          : 'New transaction',
                      onDelete: _isEditing && !busy ? _delete : null,
                      showDelete: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    SegmentedSwitch(
                      segments: const [
                        (TransactionType.expense, 'Expense'),
                        (TransactionType.income, 'Income'),
                      ],
                      selected: _type,
                      onChanged: busy ? null : _setType,
                    ),
                    const SizedBox(height: 16),
                    _AmountField(
                      controller: _amount,
                      currency:
                          widget.initial?.currency ??
                          ref.watch(currencyProvider),
                      type: _type,
                      error: _showErrors ? _amountError : null,
                      enabled: !busy,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _CategoryGrid(
                      categories: ref
                          .watch(categoryCatalogProvider)
                          .forType(_type),
                      selectedId: _categoryId,
                      error: _showErrors ? _categoryError : null,
                      onSelected: busy
                          ? null
                          : (id) => setState(() => _categoryId = id),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(AppRadii.listGroup),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: busy ? null : _pickDate,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 56),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 20,
                                      color: colors.mutedText,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Date',
                                            style: textTheme.bodySmall,
                                          ),
                                          Text(
                                            Dates.longDate(_date),
                                            style: textTheme.titleSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: colors.mutedText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            indent: 16,
                            endIndent: 16,
                            color: colors.divider,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notes,
                                  size: 20,
                                  color: colors.mutedText,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _note,
                                    enabled: !busy,
                                    maxLength:
                                        TransactionValidators.maxNoteLength,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    textInputAction: TextInputAction.done,
                                    decoration: const InputDecoration(
                                      hintText: 'Add a note (optional)',
                                      semanticCounterText: '',
                                      counterText: '',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: 16),
                      ErrorBanner(message: ErrorView.messageFor(state.error!)),
                    ],
                    const Spacer(),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: busy
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).colorScheme.onPrimary,
                                semanticsLabel: 'Saving',
                              ),
                            )
                          : Text(
                              _isEditing ? 'Save changes' : 'Add transaction',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onDelete,
    required this.showDelete,
  });

  final String title;
  final VoidCallback? onDelete;
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    return Row(
      children: [
        IconButton(
          tooltip: 'Close',
          style: IconButton.styleFrom(
            backgroundColor: colors.card,
            fixedSize: const Size.square(AppSpacing.minTouchTarget),
          ),
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showDelete)
          IconButton(
            tooltip: 'Delete transaction',
            style: IconButton.styleFrom(
              backgroundColor: colors.warningBackground,
              foregroundColor: colors.warningForeground,
              fixedSize: const Size.square(AppSpacing.minTouchTarget),
            ),
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          )
        else
          const SizedBox(width: AppSpacing.minTouchTarget),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.type,
    required this.error,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String currency;
  final TransactionType type;
  final String? error;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final scheme = Theme.of(context).colorScheme;
    final color = error != null
        ? colors.expense
        : type == TransactionType.income
        ? colors.income
        : scheme.onSurface;

    return Column(
      children: [
        Text(
          'Amount',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.mutedText,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              currency,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: colors.mutedText,
              ),
            ),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120),
                child: TextField(
                  key: const Key('amount-field'),
                  controller: controller,
                  enabled: enabled,
                  autofocus: controller.text.isEmpty,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [amountInputFormatter],
                  onChanged: (_) => onChanged(),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.96,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.bricolageGrotesque(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: colors.track,
                    ),
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[const SizedBox(height: 6), _FieldError(error!)],
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.error,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final String? error;
  final ValueChanged<String>? onSelected;

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Rows of equal tiles rather than a GridView: the form sits in a
        // SliverFillRemaining, which must measure its content.
        for (var start = 0; start < categories.length; start += _columns) ...[
          if (start > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var i = start; i < start + _columns; i++) ...[
                if (i > start) const SizedBox(width: 8),
                Expanded(
                  child: i < categories.length
                      ? _tile(context, categories[i])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
        if (error != null) ...[const SizedBox(height: 8), _FieldError(error!)],
      ],
    );
  }

  Widget _tile(BuildContext context, Category c) {
    final colors = context.pwColors;
    final selected = c.id == selectedId;

    return Semantics(
      button: true,
      selected: selected,
      label: c.name,
      excludeSemantics: true,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.listGroup),
          side: BorderSide(
            width: 2,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : colors.card,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.listGroup),
          onTap: onSelected == null ? null : () => onSelected!(c.id),
          child: SizedBox(
            height: 74,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CategoryIcon(category: c, size: 32, radius: 10),
                  const SizedBox(height: 6),
                  Text(
                    c.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.pwColors.expense,
      ),
    ),
  );
}
