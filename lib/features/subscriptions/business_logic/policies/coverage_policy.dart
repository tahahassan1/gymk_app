import 'coverage_period.dart';

/// Calendar coverage only. Input records and their historical dates are never
/// mutated; a gap remains a gap. Output contains disjoint, sorted periods.
abstract final class CoveragePolicy {
  static List<CoveragePeriod> merge(Iterable<CoveragePeriod> periods) {
    final sorted = periods.toList()
      ..sort((left, right) => left.start.compareTo(right.start));
    final merged = <CoveragePeriod>[];
    for (final period in sorted) {
      if (merged.isEmpty || period.start.isAfter(merged.last.end)) {
        merged.add(period);
        continue;
      }
      final previous = merged.last;
      if (period.end.isAfter(previous.end)) {
        merged[merged.length - 1] = CoveragePeriod(
          start: previous.start,
          end: period.end,
        );
      }
    }
    return List.unmodifiable(merged);
  }
}
