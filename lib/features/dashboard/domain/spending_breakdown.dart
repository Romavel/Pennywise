import 'package:flutter/foundation.dart';

import '../../transactions/domain/transaction.dart';

/// Series of the spending chart. Each slot has a fixed color, so a
/// category always keeps its color regardless of its rank or which other
/// categories have spending this month. Categories without their own slot
/// fold into [other].
enum SpendingSlot {
  housing('Housing'),
  food('Food'),
  transport('Transport'),
  shopping('Shopping'),
  other('Other');

  const SpendingSlot(this.label);

  final String label;

  static SpendingSlot forCategory(String categoryId) => switch (categoryId) {
    'housing' => housing,
    'food' => food,
    'transport' => transport,
    'shopping' => shopping,
    _ => other,
  };
}

@immutable
class SpendingSlice {
  const SpendingSlice({
    required this.slot,
    required this.amountMinor,
    required this.share,
  });

  final SpendingSlot slot;
  final int amountMinor;

  /// Fraction of total spending, 0–1.
  final double share;

  /// Whole percent for display. Rounded so that tiny slices show as 1%,
  /// not 0%.
  int get percent =>
      amountMinor > 0 && share < 0.005 ? 1 : (share * 100).round();
}

@immutable
class SpendingBreakdown {
  const SpendingBreakdown({required this.totalMinor, required this.slices});

  /// Expenses only; income is ignored. Slices are sorted largest first,
  /// with "Other" always last, and slots without spending are left out.
  factory SpendingBreakdown.of(Iterable<Transaction> transactions) {
    final bySlot = <SpendingSlot, int>{};
    for (final t in transactions) {
      if (t.isIncome) continue;
      final slot = SpendingSlot.forCategory(t.categoryId);
      bySlot[slot] = (bySlot[slot] ?? 0) + t.amountMinor;
    }
    final total = bySlot.values.fold(0, (sum, v) => sum + v);
    final slices =
        [
          for (final MapEntry(key: slot, value: amount) in bySlot.entries)
            SpendingSlice(
              slot: slot,
              amountMinor: amount,
              share: amount / total,
            ),
        ]..sort((a, b) {
          if (a.slot == SpendingSlot.other) return 1;
          if (b.slot == SpendingSlot.other) return -1;
          return b.amountMinor.compareTo(a.amountMinor);
        });
    return SpendingBreakdown(totalMinor: total, slices: slices);
  }

  final int totalMinor;
  final List<SpendingSlice> slices;

  bool get isEmpty => totalMinor == 0;
}
