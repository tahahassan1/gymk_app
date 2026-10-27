import '../../../../core/time/clock.dart';
import '../../../../core/time/date_only.dart';
import 'coverage_period.dart';
import 'coverage_policy.dart';

enum MembershipStatus { noSubscription, active, expiringSoon, expired }

/// Derived facts only; no status or authoritative expiry is persisted.
final class MembershipAssessment {
  const MembershipAssessment._({
    required this.asOf,
    required this.periods,
    required this.currentPeriod,
    required this.lastExpiredOn,
    required this.status,
  });

  final DateOnly asOf;
  final List<CoveragePeriod> periods;
  final CoveragePeriod? currentPeriod;

  /// A past expiry, when present. Future-only history has no past expiry and
  /// must not be presented as though its future end were a current expiry.
  final DateOnly? lastExpiredOn;
  final MembershipStatus status;

  DateOnly? get currentExpiry => currentPeriod?.end;
  int get remainingDays =>
      currentExpiry == null ? 0 : asOf.daysUntil(currentExpiry!);
}

final class RenewalPreview {
  const RenewalPreview._({
    required this.asOf,
    required this.currentExpiry,
    required this.period,
    required this.resultingCurrentExpiry,
  });

  final DateOnly asOf;
  final DateOnly? currentExpiry;
  final CoveragePeriod period;

  /// Includes unchanged existing coverage connected by the proposed period.
  /// May be null for a manually backdated period that has already expired.
  final DateOnly? resultingCurrentExpiry;
}

/// Uses one injected local date per operation. Callers re-evaluate on resume,
/// date rollover and before submission; scheduling belongs to the later Cubits.
final class SubscriptionPolicy {
  const SubscriptionPolicy({required this.clock});

  static const nearExpiryDays = 3;
  final Clock clock;

  MembershipAssessment assess(
    Iterable<CoveragePeriod> periods, {
    DateOnly? asOf,
  }) => _assess(periods, asOf ?? clock.today());

  bool isManualStartAllowed(DateOnly start) => !start.isAfter(clock.today());

  RenewalPreview previewRenewal(
    Iterable<CoveragePeriod> periods, {
    DateOnly? manualStart,
  }) {
    final today = clock.today();
    if (manualStart != null && manualStart.isAfter(today)) {
      throw ArgumentError.value(
        manualStart,
        'manualStart',
        'Cannot be in the future',
      );
    }
    final existing = _assess(periods, today);
    // Automatic extension can start in the future. The manual-start restriction
    // applies only when the owner explicitly selects a replacement start.
    final start = manualStart ?? existing.currentExpiry ?? today;
    final period = CoveragePeriod(start: start, end: start.addCalendarMonth());
    final resulting = _assess([...existing.periods, period], today);
    return RenewalPreview._(
      asOf: today,
      currentExpiry: existing.currentExpiry,
      period: period,
      resultingCurrentExpiry: resulting.currentExpiry,
    );
  }

  MembershipAssessment _assess(
    Iterable<CoveragePeriod> periods,
    DateOnly today,
  ) {
    final merged = CoveragePolicy.merge(periods);
    CoveragePeriod? current;
    DateOnly? lastExpiredOn;
    for (final period in merged) {
      if (period.contains(today)) current = period;
      if (!period.end.isAfter(today)) lastExpiredOn = period.end;
    }
    final MembershipStatus status;
    if (merged.isEmpty) {
      status = MembershipStatus.noSubscription;
    } else if (current == null) {
      status = MembershipStatus.expired;
    } else if (today.daysUntil(current.end) <= nearExpiryDays) {
      status = MembershipStatus.expiringSoon;
    } else {
      status = MembershipStatus.active;
    }
    return MembershipAssessment._(
      asOf: today,
      periods: merged,
      currentPeriod: current,
      lastExpiredOn: lastExpiredOn,
      status: status,
    );
  }
}
