import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../categories/domain/default_categories.dart';
import '../../categories/presentation/category_icon.dart';
import '../domain/budget_progress.dart';

extension BudgetStatusColors on BudgetStatus {
  Color color(PennywiseColors colors) => switch (this) {
    BudgetStatus.ok => colors.budgetOk,
    BudgetStatus.near => colors.budgetNear,
    BudgetStatus.over => colors.budgetOver,
  };
}

/// Rounded progress bar. Values above 1 are drawn full.
class BudgetBar extends StatelessWidget {
  const BudgetBar({
    required this.ratio,
    required this.color,
    this.trackColor,
    this.height = 8,
    super.key,
  });

  final double ratio;
  final Color color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor ?? context.pwColors.track),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A budget in the list: category, usage, percent, bar and status.
class BudgetRow extends StatelessWidget {
  const BudgetRow({
    required this.progress,
    required this.currency,
    required this.onTap,
    super.key,
  });

  final BudgetProgress progress;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;
    final category = DefaultCategories.byId(progress.budget.categoryId);
    final status = progress.status;
    final statusColor = status.color(colors);
    final over = status == BudgetStatus.over;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryIcon(category: category, size: 36, radius: 11),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: textTheme.titleSmall),
                        const SizedBox(height: 1),
                        Text(
                          '$currency ${Money.format(progress.spentMinor)} '
                          'of ${Money.format(progress.limitMinor)}',
                          style: textTheme.bodySmall?.copyWith(
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${progress.percent}%',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: status == BudgetStatus.ok
                          ? Theme.of(context).colorScheme.onSurface
                          : statusColor,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BudgetBar(ratio: progress.ratio, color: statusColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (over) ...[
                    Icon(Icons.error_outline, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    over
                        ? '$currency ${Money.format(progress.overMinor)} over limit'
                        : '$currency ${Money.format(progress.remainingMinor)} left',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: over ? statusColor : colors.mutedText,
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

/// Warning strip for budgets over their limit.
class OverLimitBanner extends StatelessWidget {
  const OverLimitBanner({
    required this.overLimit,
    required this.currency,
    super.key,
  });

  final List<BudgetProgress> overLimit;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final text = overLimit.length == 1
        ? '${DefaultCategories.byId(overLimit.single.budget.categoryId).name} '
              'is over its limit by $currency '
              '${Money.format(overLimit.single.overMinor)}'
        : '${overLimit.length} budgets are over their limits';

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.warningBackground,
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: colors.warningForeground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.warningForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
