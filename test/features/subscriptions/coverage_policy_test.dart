import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/coverage_period.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/coverage_policy.dart';

void main() {
  CoveragePeriod period(int startDay, int endDay) => CoveragePeriod(
    start: DateOnly(2026, 10, startDay),
    end: DateOnly(2026, 10, endDay),
  );

  test('coverage is start inclusive and end exclusive', () {
    final coverage = period(10, 20);
    expect(coverage.contains(DateOnly(2026, 10, 9)), isFalse);
    expect(coverage.contains(DateOnly(2026, 10, 10)), isTrue);
    expect(coverage.contains(DateOnly(2026, 10, 19)), isTrue);
    expect(coverage.contains(DateOnly(2026, 10, 20)), isFalse);
    expect(coverage.contains(DateOnly(2026, 10, 21)), isFalse);
    expect(() => period(20, 20), throwsArgumentError);
    expect(() => period(21, 20), throwsArgumentError);
  });

  test(
    'merges unordered adjacent, nested, duplicate and overlapping periods',
    () {
      final original = [
        period(20, 25),
        period(10, 15),
        period(14, 20),
        period(11, 12),
        period(10, 15),
      ];
      final merged = CoveragePolicy.merge(original);
      expect(merged, hasLength(1));
      expect(merged.single.start, DateOnly(2026, 10, 10));
      expect(merged.single.end, DateOnly(2026, 10, 25));
      expect(original.first.start, DateOnly(2026, 10, 20));
      expect(original[1].end, DateOnly(2026, 10, 15));
      expect(() => merged.clear(), throwsUnsupportedError);
    },
  );

  test('keeps gaps and remaining historical dates after a middle deletion', () {
    final first = period(1, 10);
    final middle = period(10, 20);
    final last = period(20, 30);
    expect(CoveragePolicy.merge([first, middle, last]), hasLength(1));
    final remaining = CoveragePolicy.merge([first, last]);
    expect(remaining, [first, last]);
    expect(
      remaining.any((range) => range.contains(DateOnly(2026, 10, 15))),
      isFalse,
    );
    expect(last.start, DateOnly(2026, 10, 20));
    expect(last.end, DateOnly(2026, 10, 30));
    expect(CoveragePolicy.merge([]), isEmpty);
  });
}
