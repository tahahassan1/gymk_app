/// A validated Gregorian calendar date, without a time or timezone.
///
/// This is an in-memory value. Persisted date encoding is a separate contract.
final class DateOnly implements Comparable<DateOnly> {
  factory DateOnly(int year, int month, int day) {
    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year', 'Must be between 1 and 9999');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be between 1 and 12');
    }
    if (day < 1 || day > _daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day', 'Invalid day for this month');
    }
    return DateOnly._(year, month, day);
  }

  const DateOnly._(this.year, this.month, this.day);

  /// Reads the supplied calendar components without a timezone conversion.
  factory DateOnly.fromDateTime(DateTime date) =>
      DateOnly(date.year, date.month, date.day);

  final int year;
  final int month;
  final int day;

  static int _daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  /// Applies one calendar month to this date, clamping in the target month.
  /// Repeating this operation uses the previously clamped day, not an anchor.
  DateOnly addCalendarMonth() {
    final nextYear = month == 12 ? year + 1 : year;
    final nextMonth = month == 12 ? 1 : month + 1;
    final lastDay = _daysInMonth(nextYear, nextMonth);
    return DateOnly(nextYear, nextMonth, day > lastDay ? lastDay : day);
  }

  /// Signed calendar days from this date to [other]. UTC is used solely for
  /// arithmetic, so 23/25-hour local days cannot affect the result.
  int daysUntil(DateOnly other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;

  @override
  int compareTo(DateOnly other) {
    final byYear = year.compareTo(other.year);
    if (byYear != 0) return byYear;
    final byMonth = month.compareTo(other.month);
    return byMonth != 0 ? byMonth : day.compareTo(other.day);
  }

  bool isBefore(DateOnly other) => compareTo(other) < 0;
  bool isAfter(DateOnly other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is DateOnly &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'DateOnly($year, $month, $day)';
}
