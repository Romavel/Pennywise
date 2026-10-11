import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/write_result.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../transactions/domain/transaction.dart';
import '../data/category_providers.dart';
import '../domain/category.dart';
import '../domain/category_catalog.dart';
import '../domain/category_styles.dart';
import '../domain/default_categories.dart';
import 'category_icon.dart';
import 'categories_controller.dart';

/// Opens the sheet to create a custom category of [type], or to edit
/// [existing] (rename a built-in one; rename, restyle or delete a custom one).
Future<void> showCategoryFormSheet(
  BuildContext context, {
  required TransactionType type,
  Category? existing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => CategoryFormSheet(type: type, existing: existing),
);

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({required this.type, this.existing, super.key});

  final TransactionType type;
  final Category? existing;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _iconKey = widget.existing?.iconKey ?? CategoryStyles.defaultIcon;
  late String _toneKey = widget.existing?.toneKey ?? 'orange';
  var _showErrors = false;

  Category? get _existing => widget.existing;
  bool get _isBuiltIn => _existing != null && !_existing!.isCustom;
  bool get _hasStyle => !_isBuiltIn;

  String? get _nameError {
    final name = _name.text.trim();
    if (name.isEmpty) return 'Enter a name.';
    if (name.length > CustomCategory.maxNameLength) {
      return 'Use at most ${CustomCategory.maxNameLength} characters.';
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameError != null) {
      setState(() => _showErrors = true);
      return;
    }
    final name = _name.text.trim();
    final actions = ref.read(categoryActionsProvider.notifier);
    final existing = _existing;

    if (existing == null) {
      await actions.createCustom(
        name: name,
        type: widget.type,
        iconKey: _iconKey,
        toneKey: _toneKey,
      );
    } else if (existing.isCustom) {
      await actions.updateCustom(
        CustomCategory(
          id: existing.id,
          name: name,
          type: existing.type,
          iconKey: _iconKey,
          toneKey: _toneKey,
        ),
      );
    } else if (name == DefaultCategories.byId(existing.id).name) {
      await actions.resetName(existing.id);
    } else {
      await actions.rename(existing.id, name);
    }
    _finish(existing == null ? 'Category created' : 'Category saved');
  }

  Future<void> _resetName() async {
    await ref.read(categoryActionsProvider.notifier).resetName(_existing!.id);
    _finish('Original name restored');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “${_existing!.name}”?'),
        content: const Text(
          'Its budgets are deleted too. Transactions in this category are '
          'kept and shown under “Other”.',
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
    await ref
        .read(categoryActionsProvider.notifier)
        .deleteCustom(_existing!.id);
    _finish('Category deleted');
  }

  void _finish(String message) {
    if (!mounted) return;
    final result = ref.read(categoryActionsProvider);
    if (result.hasError) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.value == WriteResult.pendingSync
                ? '$message offline. It will sync when you’re back online.'
                : message,
          ),
        ),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryActionsProvider);
    final busy = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.pwColors;
    final renamed =
        _isBuiltIn &&
        ref.watch(categoryCatalogProvider).renamedIds.contains(_existing!.id);
    final preview = Category(
      id: 'preview',
      name: _name.text,
      shortName: _name.text,
      type: widget.type,
      icon: _hasStyle ? CategoryStyles.icon(_iconKey) : _existing!.icon,
      tone: _hasStyle ? CategoryStyles.tone(_toneKey) : _existing!.tone,
    );

    final title = switch (_existing) {
      null =>
        widget.type == TransactionType.income
            ? 'New income category'
            : 'New expense category',
      final c when c.isCustom => 'Edit category',
      _ => 'Rename category',
    };

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
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: 18),
            Row(
              children: [
                CategoryIcon(category: preview, size: 48, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('category-name-field'),
                    controller: _name,
                    enabled: !busy,
                    autofocus: _existing == null,
                    maxLength: CustomCategory.maxNameLength,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      counterText: '',
                      errorText: _showErrors ? _nameError : null,
                    ),
                  ),
                ),
              ],
            ),
            if (_isBuiltIn) ...[
              const SizedBox(height: 8),
              Text(
                'Built-in categories keep their icon and colour and can’t be '
                'deleted.',
                style: textTheme.bodySmall,
              ),
            ],
            if (_hasStyle) ...[
              const SizedBox(height: 18),
              const _Label('Icon'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final MapEntry(key: key, value: icon)
                      in CategoryStyles.icons.entries)
                    _Choice(
                      selected: key == _iconKey,
                      semanticLabel: 'Icon $key',
                      onTap: busy ? null : () => setState(() => _iconKey = key),
                      child: Icon(icon, size: 22),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const _Label('Colour'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final MapEntry(key: key, value: tone)
                      in CategoryStyles.tones.entries)
                    _Choice(
                      selected: key == _toneKey,
                      semanticLabel: 'Colour $key',
                      onTap: busy ? null : () => setState(() => _toneKey = key),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: tone.foreground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (state.hasError) ...[
              const SizedBox(height: 14),
              ErrorBanner(message: ErrorView.messageFor(state.error!)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(
                busy
                    ? 'Saving…'
                    : _existing == null
                    ? 'Create category'
                    : 'Save',
              ),
            ),
            if (renamed) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : _resetName,
                child: Text(
                  'Restore “${DefaultCategories.byId(_existing!.id).name}”',
                ),
              ),
            ],
            if (_existing?.isCustom ?? false) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: colors.expense),
                onPressed: busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete category'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.iconTile),
          side: BorderSide(
            width: 2,
            color: selected ? scheme.primary : colors.track,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.iconTile),
          onTap: onTap,
          child: SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
