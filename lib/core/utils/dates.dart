import 'package:intl/intl.dart';

/// Date labels used in lists and forms. All dates are local.
abstract final class Dates {
  static DateTime dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// `Today · Sun, 11 Oct`, `Yesterday · Sat, 10 Oct`, `Fri, 9 Oct`.
  static String dayHeader(DateTime date, {DateTime? now}) {
    final label = DateFormat('EEE, d MMM', 'en_US').format(date);
    final relative = _relative(date, now ?? DateTime.now());
    return relative == null ? label : '$relative · $label';
  }

  /// `Today, 11 Oct 2026`, `Fri, 9 Oct 2026`.
  static String longDate(DateTime date, {DateTime? now}) {
    final relative = _relative(date, now ?? DateTime.now());
    return relative == null
        ? DateFormat('EEE, d MMM y', 'en_US').format(date)
        : '$relative, ${DateFormat('d MMM y', 'en_US').format(date)}';
  }

  /// `Today`, `Yesterday` or `9 Oct`.
  static String shortDay(DateTime date, {DateTime? now}) =>
      _relative(date, now ?? DateTime.now()) ??
      DateFormat('d MMM', 'en_US').format(date);

  static String? _relative(DateTime date, DateTime now) {
    final today = dayOf(now);
    final day = dayOf(date);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return null;
  }
}
