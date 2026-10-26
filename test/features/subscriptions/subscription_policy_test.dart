import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/coverage_period.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';

import '../../support/fake_clock.dart';

CoveragePeriod monthFrom(DateOnly start) =>
    CoveragePeriod(start: start, end: start.addCalendarMonth());

void main() {
  late FakeClock clock;
  late SubscriptionPolicy policy;

  setUp(() {
    clock = FakeClock(DateOnly(2026, 11, 10));
    policy = SubscriptionPolicy(clock: clock);
  });

  test(
    'October subscription and November early payment extend to December',
    () {
      final original = monthFrom(DateOnly(2026, 10, 26));
      final preview = policy.previewRenewal([original]);
      expect(preview.asOf, DateOnly(2026, 11, 10));
      expect(preview.currentExpiry, DateOnly(2026, 11, 26));
      expect(preview.period.start, DateOnly(2026, 11, 26));
      expect(preview.period.end, DateOnly(2026, 12, 26));
      expect(preview.resultingCurrentExpiry, DateOnly(2026, 12, 26));
      expect(
        clock.reads,
        1,
        reason: 'A preview uses one date even at midnight',
      );
      final assessment = policy.assess([preview.period, original]);
      expect(assessment.status, MembershipStatus.active);
      expect(assessment.currentExpiry, DateOnly(2026, 12, 26));
      expect(assessment.remainingDays, 46);
      expect(original.end, DateOnly(2026, 11, 26));
    },
  );

  test('repeated early renewals use the complete continuous expiry', () {
    final periods = [monthFrom(DateOnly(2026, 10, 26))];
    periods.add(policy.previewRenewal(periods).period);
    final second = policy.previewRenewal(periods);
    expect(second.period.start, DateOnly(2026, 12, 26));
    expect(second.period.end, DateOnly(2027, 1, 26));
    periods.add(second.period);
    expect(policy.assess(periods).currentExpiry, DateOnly(2027, 1, 26));
  });

  for (final leapYear in [false, true]) {
    test('renewal preserves repeated clamping, leap year: $leapYear', () {
      final year = leapYear ? 2024 : 2026;
      clock.date = DateOnly(year, 2, 1);
      final first = monthFrom(DateOnly(year, 1, 31));
      final renewal = policy.previewRenewal([first]);
      expect(renewal.period.start, DateOnly(year, 2, leapYear ? 29 : 28));
      expect(renewal.period.end, DateOnly(year, 3, leapYear ? 29 : 28));
    });
  }

  for (final (day, expected, remaining) in [
    (22, MembershipStatus.active, 4),
    (23, MembershipStatus.expiringSoon, 3),
    (25, MembershipStatus.expiringSoon, 1),
    (26, MembershipStatus.expired, 0),
    (27, MembershipStatus.expired, 0),
  ]) {
    test('status on November $day respects the exclusive expiry threshold', () {
      clock.date = DateOnly(2026, 11, day);
      final assessment = policy.assess([monthFrom(DateOnly(2026, 10, 26))]);
      expect(assessment.status, expected);
      expect(assessment.remainingDays, remaining);
      expect(
        assessment.currentExpiry,
        day < 26 ? DateOnly(2026, 11, 26) : isNull,
      );
    });
  }

  test('first or expired subscription defaults to today', () {
    expect(policy.assess([]).status, MembershipStatus.noSubscription);
    for (final periods in <List<CoveragePeriod>>[
      [],
      [monthFrom(DateOnly(2026, 9, 10))],
    ]) {
      final preview = policy.previewRenewal(periods);
      expect(preview.currentExpiry, isNull);
      expect(preview.period.start, clock.date);
      expect(preview.period.end, DateOnly(2026, 12, 10));
    }
    clock.date = DateOnly(2026, 11, 26);
    expect(
      policy.previewRenewal([monthFrom(DateOnly(2026, 10, 26))]).period.start,
      clock.date,
    );
  });

  test(
    'manual future selection is rejected while automatic renewal is allowed',
    () {
      final periods = [monthFrom(DateOnly(2026, 10, 26))];
      expect(policy.isManualStartAllowed(clock.date), isTrue);
      expect(policy.isManualStartAllowed(DateOnly(2026, 11, 9)), isTrue);
      expect(policy.isManualStartAllowed(DateOnly(2026, 11, 11)), isFalse);
      expect(
        () =>
            policy.previewRenewal(periods, manualStart: DateOnly(2026, 11, 26)),
        throwsArgumentError,
      );
      expect(
        policy.previewRenewal(periods).period.start,
        DateOnly(2026, 11, 26),
      );
      final edited = policy.previewRenewal(
        periods,
        manualStart: DateOnly(2026, 11, 1),
      );
      expect(edited.period.end, DateOnly(2026, 12, 1));
      expect(periods.single.start, DateOnly(2026, 10, 26));
      expect(periods.single.end, DateOnly(2026, 11, 26));
    },
  );

  test('a middle deletion leaves expired gap and preserves future periods', () {
    final first = monthFrom(DateOnly(2026, 9, 26));
    final middle = monthFrom(DateOnly(2026, 10, 26));
    final future = monthFrom(DateOnly(2026, 11, 26));
    expect(
      policy.assess([first, middle, future]).currentExpiry,
      DateOnly(2026, 12, 26),
    );
    final gap = policy.assess([first, future]);
    expect(gap.status, MembershipStatus.expired);
    expect(gap.currentExpiry, isNull);
    expect(gap.lastExpiredOn, DateOnly(2026, 10, 26));
    final renewal = policy.previewRenewal([first, future]);
    expect(renewal.period.start, clock.date);
    expect(renewal.period.end, DateOnly(2026, 12, 10));
    expect(renewal.resultingCurrentExpiry, DateOnly(2026, 12, 26));
    expect(future.start, DateOnly(2026, 11, 26));
    expect(future.end, DateOnly(2026, 12, 26));
  });

  test(
    'future-only remaining history is expired with renewal starting today',
    () {
      final future = monthFrom(DateOnly(2026, 11, 26));
      final assessment = policy.assess([future]);
      expect(assessment.status, MembershipStatus.expired);
      expect(assessment.currentExpiry, isNull);
      expect(assessment.lastExpiredOn, isNull);
      expect(assessment.periods.single, same(future));
      expect(policy.previewRenewal([future]).period.start, clock.date);
    },
  );

  test(
    'deleting newest or only period and editing a start recompute coverage',
    () {
      final first = monthFrom(DateOnly(2026, 10, 26));
      final newest = monthFrom(DateOnly(2026, 11, 26));
      expect(
        policy.assess([first, newest]).currentExpiry,
        DateOnly(2026, 12, 26),
      );
      expect(policy.assess([first]).currentExpiry, DateOnly(2026, 11, 26));
      expect(policy.assess([]).status, MembershipStatus.noSubscription);
      final correctedFirst = monthFrom(DateOnly(2026, 9, 26));
      expect(
        policy.assess([correctedFirst, newest]).status,
        MembershipStatus.expired,
      );
      expect(newest.start, DateOnly(2026, 11, 26));
      expect(newest.end, DateOnly(2026, 12, 26));
    },
  );

  test('disconnected future coverage never extends the current expiry', () {
    final first = monthFrom(DateOnly(2026, 10, 26));
    final future = monthFrom(DateOnly(2027, 1, 26));
    expect(
      policy.assess([first, future]).currentExpiry,
      DateOnly(2026, 11, 26),
    );
    expect(
      policy.previewRenewal([first, future]).resultingCurrentExpiry,
      DateOnly(2026, 12, 26),
    );
  });

  test(
    'date rollover and resume can reassess unchanged records via the clock',
    () {
      final records = [monthFrom(DateOnly(2026, 10, 26))];
      clock.date = DateOnly(2026, 11, 22);
      expect(policy.assess(records).status, MembershipStatus.active);
      clock.date = DateOnly(2026, 11, 23);
      expect(policy.assess(records).status, MembershipStatus.expiringSoon);
      clock.date = DateOnly(2026, 11, 26);
      expect(policy.assess(records).status, MembershipStatus.expired);
      expect(policy.previewRenewal(records).period.start, clock.date);
    },
  );

  test(
    'a backdated correction can remain expired without moving other dates',
    () {
      final original = monthFrom(DateOnly(2026, 7, 26));
      final preview = policy.previewRenewal([
        original,
      ], manualStart: DateOnly(2026, 9, 1));
      expect(preview.period.end, DateOnly(2026, 10, 1));
      expect(preview.resultingCurrentExpiry, isNull);
      expect(original.end, DateOnly(2026, 8, 26));
    },
  );
}
