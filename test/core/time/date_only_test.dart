import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/time/date_only.dart';

void main() {
  test('rejects invalid dates rather than accepting DateTime overflow', () {
    for (final parts in [
      [0, 1, 1],
      [10000, 1, 1],
      [2026, 0, 1],
      [2026, 13, 1],
      [2026, 1, 0],
      [2026, 4, 31],
      [2026, 2, 29],
      [1900, 2, 29],
    ]) {
      expect(
        () => DateOnly(parts[0], parts[1], parts[2]),
        throwsArgumentError,
        reason: '$parts must be rejected',
      );
    }
    expect(DateOnly(2000, 2, 29).day, 29);
    expect(DateOnly(2024, 2, 29).day, 29);
  });

  test('adds a calendar month across short months and year boundaries', () {
    final cases = [
      (DateOnly(2026, 1, 31), DateOnly(2026, 2, 28)),
      (DateOnly(2024, 1, 31), DateOnly(2024, 2, 29)),
      (DateOnly(1900, 1, 31), DateOnly(1900, 2, 28)),
      (DateOnly(2000, 1, 31), DateOnly(2000, 2, 29)),
      (DateOnly(2026, 3, 31), DateOnly(2026, 4, 30)),
      (DateOnly(2026, 12, 31), DateOnly(2027, 1, 31)),
      (DateOnly(2026, 10, 26), DateOnly(2026, 11, 26)),
    ];
    for (final (start, expected) in cases) {
      expect(start.addCalendarMonth(), expected, reason: '$start');
    }
    expect(() => DateOnly(9999, 12, 1).addCalendarMonth(), throwsArgumentError);
  });

  test('repeated clamping uses the resulting date, including leap years', () {
    final february = DateOnly(2026, 1, 31).addCalendarMonth();
    expect(february.addCalendarMonth(), DateOnly(2026, 3, 28));
    expect(
      february.addCalendarMonth().addCalendarMonth(),
      DateOnly(2026, 4, 28),
    );
    expect(
      DateOnly(2024, 1, 31).addCalendarMonth().addCalendarMonth(),
      DateOnly(2024, 3, 29),
    );
  });

  test('calendar differences ignore DST transition day lengths', () {
    // Explicit offset changes demonstrate 23/25-hour elapsed days without
    // relying on the test machine's timezone or installed timezone rules.
    final springStart = DateTime.parse('2026-04-24T00:00:00+02:00');
    final springEnd = DateTime.parse('2026-04-25T00:00:00+03:00');
    expect(springEnd.difference(springStart).inHours, 23);
    expect(DateOnly(2026, 4, 24).daysUntil(DateOnly(2026, 4, 25)), 1);
    final autumnStart = DateTime.parse('2026-10-29T00:00:00+03:00');
    final autumnEnd = DateTime.parse('2026-10-30T00:00:00+02:00');
    expect(autumnEnd.difference(autumnStart).inHours, 25);
    expect(DateOnly(2026, 10, 29).daysUntil(DateOnly(2026, 10, 30)), 1);
    expect(DateOnly(2026, 4, 23).daysUntil(DateOnly(2026, 4, 25)), 2);
    expect(DateOnly(2026, 10, 29).daysUntil(DateOnly(2026, 10, 31)), 2);
    expect(DateOnly(2026, 10, 31).daysUntil(DateOnly(2026, 10, 29)), -2);
    expect(DateOnly(2024, 2, 28).daysUntil(DateOnly(2024, 3, 1)), 2);
    expect(DateOnly(2026, 12, 31).daysUntil(DateOnly(2027, 1, 1)), 1);
    expect(DateOnly(2026, 10, 27).daysUntil(DateOnly(2026, 10, 27)), 0);
  });

  test('reads date components without converting between local and UTC', () {
    expect(
      DateOnly.fromDateTime(DateTime.utc(2026, 10, 27, 23, 59)),
      DateOnly(2026, 10, 27),
    );
    expect(
      DateOnly.fromDateTime(DateTime(2026, 10, 27, 0, 1)),
      DateOnly(2026, 10, 27),
    );
  });

  test('orders calendar dates and provides value equality for projections', () {
    final dates = [
      DateOnly(2027, 1, 1),
      DateOnly(2026, 12, 31),
      DateOnly(2026, 1, 1),
    ]..sort();
    expect(dates, [
      DateOnly(2026, 1, 1),
      DateOnly(2026, 12, 31),
      DateOnly(2027, 1, 1),
    ]);
    expect(DateOnly(2026, 12, 31).isBefore(DateOnly(2027, 1, 1)), isTrue);
    expect(DateOnly(2027, 1, 1).isAfter(DateOnly(2026, 12, 31)), isTrue);
    expect({DateOnly(2026, 10, 27), DateOnly(2026, 10, 27)}, hasLength(1));
  });
}
