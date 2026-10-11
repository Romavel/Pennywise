import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/segmented_switch.dart';
import '../../transactions/domain/transaction.dart';
import '../data/category_providers.dart';
import '../domain/category.dart';
import 'category_form_sheet.dart';
import 'category_icon.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  var _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryCatalogProvider).forType(_type);
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  8,
                  AppSpacing.screenHorizontal,
                  16,
                ),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back to settings',
                        style: IconButton.styleFrom(
                          backgroundColor: colors.card,
                          fixedSize: const Size.square(
                            AppSpacing.minTouchTarget,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Categories',
                        style: textTheme.headlineMedium?.copyWith(fontSize: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SegmentedSwitch(
                    segments: const [
                      (TransactionType.expense, 'Expenses'),
                      (TransactionType.income, 'Income'),
                    ],
                    selected: _type,
                    onChanged: (type) => setState(() => _type = type),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, c) in categories.indexed)
                          _CategoryRow(
                            category: c,
                            showDivider: i > 0,
                            onTap: () => showCategoryFormSheet(
                              context,
                              type: _type,
                              existing: c,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Default categories can be renamed but not deleted. '
                      'Custom ones get their own icon and colour.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                20,
              ),
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New category'),
                onPressed: () => showCategoryFormSheet(context, type: _type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.showDivider,
    required this.onTap,
  });

  final Category category;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final custom = category.isCustom;
    final tagBackground = custom ? category.tone.background : colors.divider;
    final tagForeground = custom ? category.tone.foreground : colors.mutedText;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: colors.divider))
              : null,
        ),
        child: Row(
          children: [
            CategoryIcon(category: category, size: 36, radius: 11),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: ShapeDecoration(
                color: tagBackground,
                shape: const StadiumBorder(),
              ),
              child: Text(
                custom ? 'CUSTOM' : 'DEFAULT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.44,
                  color: tagForeground,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: colors.mutedText),
          ],
        ),
      ),
    );
  }
}
