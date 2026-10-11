import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../categories/domain/default_categories.dart';
import '../../categories/presentation/category_icon.dart';
import '../domain/transaction.dart';

/// One row of a transaction list: category icon, note, category, amount.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.onTap,
    this.showDivider = false,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;
    final category = DefaultCategories.byId(
      transaction.categoryId,
      type: transaction.type,
    );
    final title = transaction.note.isNotEmpty
        ? transaction.note
        : category.name;
    final amount = Money.formatSigned(
      transaction.amountMinor,
      positive: transaction.isIncome,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: colors.divider))
              : null,
        ),
        child: Row(
          children: [
            CategoryIcon(category: category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(category.name, style: textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              semanticsLabel:
                  '${transaction.isIncome ? 'Income' : 'Expense'} '
                  '${Money.format(transaction.amountMinor)} '
                  '${transaction.currency}',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: transaction.isIncome ? colors.income : colors.expense,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
