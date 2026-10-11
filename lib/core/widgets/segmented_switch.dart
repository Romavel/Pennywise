import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Two or more equal-width segments on a track, e.g. "Log in | Sign up" or
/// "Expense | Income".
class SegmentedSwitch<T> extends StatelessWidget {
  const SegmentedSwitch({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<(T value, String label)> segments;
  final T selected;

  /// `null` disables the switch.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pwColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget segment(T value, String label) {
      final isSelected = value == selected;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          enabled: onChanged != null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.card : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x1F12201E),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  color: isSelected ? scheme.onSurface : colors.mutedText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.track,
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Row(
        children: [
          for (final (i, (value, label)) in segments.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            segment(value, label),
          ],
        ],
      ),
    );
  }
}
