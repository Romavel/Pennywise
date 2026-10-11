import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/dates.dart';
import 'package:pennywise/core/utils/month.dart';

void main() {
  group('Month', () {
    test('has an inclusive start and exclusive end', () {
      const october = Month(2026, 10);
      expect(october.contains(DateTime(2026, 10)), isTrue);
      expect(october.contains(DateTime(2026, 10, 31, 23, 59, 59)), isTrue);
      expect(october.contains(DateTime(2026, 11)), isFalse);
      expect(october.contains(DateTime(2026, 9, 30, 23, 59)), isFalse);
    });

    test('moves across year boundaries', () {
      expect(const Month(2026, 12).next, const Month(2027, 1));
      expect(const Month(2026, 1).previous, const Month(2025, 12));
    });

    test('formats keys and labels', () {
      expect(const Month(2026, 3).key, '2026-03');
      expect(Month.parse('2026-03'), const Month(2026, 3));
      expect(const Month(2026, 10).label, 'October 2026');
    });
  });

  group('Dates', () {
    final now = DateTime(2026, 10, 11, 15);

    test('dayHeader marks today and yesterday', () {
      expect(
        Dates.dayHeader(DateTime(2026, 10, 11, 8), now: now),
        'Today · Sun, 11 Oct',
      );
      expect(
        Dates.dayHeader(DateTime(2026, 10, 10), now: now),
        'Yesterday · Sat, 10 Oct',
      );
      expect(Dates.dayHeader(DateTime(2026, 10, 9), now: now), 'Fri, 9 Oct');
    });

    test('longDate', () {
      expect(
        Dates.longDate(DateTime(2026, 10, 11), now: now),
        'Today, 11 Oct 2026',
      );
      expect(
        Dates.longDate(DateTime(2026, 10, 9), now: now),
        'Fri, 9 Oct 2026',
      );
    });
  });
}
