import '../../../../core/time/date_only.dart';

/// A half-open coverage interval, not a persisted subscription/payment record.
final class CoveragePeriod {
  CoveragePeriod({required this.start, required this.end}) {
    if (!start.isBefore(end)) {
      throw ArgumentError('Coverage end must be after its start');
    }
  }

  final DateOnly start;
  final DateOnly end;

  bool contains(DateOnly date) => !date.isBefore(start) && date.isBefore(end);
}
