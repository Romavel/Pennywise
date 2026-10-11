import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/category_palette.dart';
import '../../../core/utils/money.dart';
import '../domain/spending_breakdown.dart';

/// Fixed color of a chart series, stepped separately for light and dark.
Color spendingSlotColor(SpendingSlot slot, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (slot) {
    SpendingSlot.housing =>
      dark ? CategoryPalette.chartHousingDark : CategoryPalette.chartHousing,
    SpendingSlot.food =>
      dark ? CategoryPalette.chartFoodDark : CategoryPalette.chartFood,
    SpendingSlot.transport =>
      dark
          ? CategoryPalette.chartTransportDark
          : CategoryPalette.chartTransport,
    SpendingSlot.shopping =>
      dark ? CategoryPalette.chartShoppingDark : CategoryPalette.chartShopping,
    SpendingSlot.other =>
      dark ? CategoryPalette.chartOtherDark : CategoryPalette.chartOther,
  };
}

/// Donut of spending by category with a legend. Tapping a segment or a
/// legend row shows that category's amount in the middle.
class SpendingChart extends StatefulWidget {
  const SpendingChart({
    required this.breakdown,
    required this.currency,
    super.key,
  });

  final SpendingBreakdown breakdown;
  final String currency;

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int? _selected;

  @override
  void didUpdateWidget(SpendingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null && _selected! >= widget.breakdown.slices.length) {
      _selected = null;
    }
  }

  void _toggle(int? index) =>
      setState(() => _selected = index == _selected ? null : index);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final slices = widget.breakdown.slices;
    final selected = _selected == null ? null : slices[_selected!];
    final colors = context.pwColors;
    final textTheme = Theme.of(context).textTheme;

    final summary = slices
        .map((s) => '${s.slot.label} ${s.percent}%')
        .join(', ');

    return Row(
      children: [
        Semantics(
          label:
              'Spending by category, ${Money.format(widget.breakdown.totalMinor)} '
              '${widget.currency} in total: $summary',
          excludeSemantics: true,
          child: SizedBox.square(
            dimension: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    centerSpaceRadius: 46,
                    // Surface-colored gap between segments.
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        _toggle(response?.touchedSection?.touchedSectionIndex);
                      },
                    ),
                    sections: [
                      for (final (i, s) in slices.indexed)
                        PieChartSectionData(
                          value: s.amountMinor.toDouble(),
                          color: spendingSlotColor(s.slot, brightness),
                          radius: _selected == i ? 22 : 18,
                          showTitle: false,
                        ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 200),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Money.formatWhole(
                        selected?.amountMinor ?? widget.breakdown.totalMinor,
                      ),
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      selected?.slot.label ?? '${widget.currency} spent',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (final (i, s) in slices.indexed)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _toggle(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: spendingSlotColor(s.slot, brightness),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.slot.label,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: _selected == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          '${s.percent}%',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
