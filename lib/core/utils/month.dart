import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// A calendar month in local time.
@immutable
class Month implements Comparable<Month> {
  const Month(this.year, this.month) : assert(month >= 1 && month <= 12);

  factory Month.of(DateTime date) => Month(date.year, date.month);

  factory Month.current() => Month.of(DateTime.now());

  /// Parses a `yyyy-MM` key as stored with budgets.
  factory Month.parse(String key) {
    final parts = key.split('-');
    if (parts.length != 2) throw FormatException('Invalid month key', key);
    return Month(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int year;
  final int month;

  /// First moment of the month (inclusive).
  DateTime get start => DateTime(year, month);

  /// First moment of the next month (exclusive).
  DateTime get end => DateTime(year, month + 1);

  Month get next => Month.of(DateTime(year, month + 1));
  Month get previous => Month.of(DateTime(year, month - 1));

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  /// `2026-10`.
  String get key => '$year-${month.toString().padLeft(2, '0')}';

  /// `October 2026`.
  String get label => DateFormat('MMMM y', 'en_US').format(start);

  /// `October`.
  String get monthName => DateFormat('MMMM', 'en_US').format(start);

  @override
  int compareTo(Month other) =>
      year != other.year ? year - other.year : month - other.month;

  @override
  bool operator ==(Object other) =>
      other is Month && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}
