import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/core/ui/app_formatters.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';
import 'package:gymk_app/features/statistics/business_logic/policies/monthly_cash_calculator.dart';
import 'package:gymk_app/features/statistics/business_logic/cubit/statistics_cubit.dart';

import '../../support/fake_clock.dart';
import '../../support/gym_fixture.dart';

SubscriptionRecord record(String id, DateOnly paidAt, int amount) =>
    SubscriptionRecord(
      id: id,
      memberId: 'same-member',
      startDate: DateOnly(2026, 12, 26),
      endDate: DateOnly(2027, 1, 26),
      amount: amount,
      paidAt: paidAt,
    );
void main() {
  test(
    'payment month independent of coverage; counts records and year boundaries',
    () {
      final subscriptions = [
        record('a', DateOnly(2026, 11, 30), 100),
        record('b', DateOnly(2026, 12, 1), 200),
        record('c', DateOnly(2026, 12, 31), 300),
        record('d', DateOnly(2027, 1, 1), 400),
      ];
      final dropins = [
        Dropin(id: 'a', amount: 25, date: DateOnly(2026, 12, 31)),
        Dropin(id: 'b', amount: 50, date: DateOnly(2027, 1, 1)),
      ];
      final cash = MonthlyCashCalculator.calculate(
        DateOnly(2026, 12, 15),
        subscriptions,
        dropins,
      );
      expect(cash.subscriptionIncome, BigInt.from(500));
      expect(cash.subscriptionCount, 2);
      expect(cash.dropinCount, 1);
      expect(cash.total, BigInt.from(525));
      expect(
        MonthlyCashCalculator.calculate(
          DateOnly(2026, 11, 1),
          subscriptions,
          dropins,
        ).total,
        BigInt.from(100),
      );
      expect(
        MonthlyCashCalculator.calculate(
          DateOnly(2027, 1, 1),
          subscriptions,
          dropins,
        ).total,
        BigInt.from(450),
      );
    },
  );
  test('integer sums and display remain exact beyond signed64 and floating point ranges', () {
    const large = 9223372036854775807;
    final cash = MonthlyCashCalculator.calculate(DateOnly(2026, 11, 1), [
      record('one', DateOnly(2026, 11, 10), large),
      record('two', DateOnly(2026, 11, 10), large),
    ], []);
    expect(cash.total, BigInt.parse('18446744073709551614'));
    expect(
      AppFormatters.totalMoney(cash.total),
      contains('18٬446٬744٬073٬709٬551٬614'),
    );
  });
  test('maximum supported month and empty inputs stay well-defined', () {
    final cash = MonthlyCashCalculator.calculate(DateOnly(9999, 12, 1), [], [
      Dropin(id: 'last', amount: 1, date: DateOnly(9999, 12, 31)),
    ]);
    expect(cash.total, BigInt.one);
    expect(cash.subscriptionCount, 0);
  });
  test('shared projection CRUD updates totals; selected month survives errors and pending deletes', () async {
    final fixture = GymFixture();
    final clock = FakeClock(DateOnly(2026, 11, 10));
    final cubit = StatisticsCubit(repository: fixture.repository, clock: clock);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.complete, isTrue);
    expect(cubit.state.cash.total, BigInt.zero);
    fixture.complete = false;
    fixture.history = [
      record('one', clock.date, 100),
      record('two', clock.date, 150),
    ];
    fixture.sessions = [Dropin(id: 'd', amount: 25, date: clock.date)];
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.complete, isFalse);
    expect(cubit.state.cash.total, BigInt.from(275));
    fixture.historySource.addError(const AppFailure(FailureKind.unavailable));
    await Future<void>.delayed(Duration.zero);
    cubit.monthChanged(DateOnly(2026, 11, 20));
    expect(cubit.state.failure, isNotNull);
    expect(cubit.state.cash.total, BigInt.from(275));
    fixture.complete = true;
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.failure, isNull);
    fixture.remote = Completer<void>();
    final handle = fixture.repository.deleteDropin(
      fixture.sessions.single,
      operationId: 'delete',
    );
    await handle.localResult;
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.cash.total, BigInt.from(250));
    expect(cubit.state.pending, isTrue);
    fixture.remote!.complete();
    await handle.remoteResult;
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.pending, isFalse);
    fixture.history = [
      fixture.history.first.edit(
        amount: 200,
        startDate: fixture.history.first.startDate,
      ),
    ];
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.cash.subscriptionCount, 1);
    expect(cubit.state.cash.total, BigInt.from(200));
    cubit.previousMonth();
    expect(cubit.state.month, DateOnly(2026, 10, 1));
    cubit.nextMonth();
    expect(cubit.state.month, DateOnly(2026, 11, 1));
    await cubit.close();
    await fixture.close();
  });
}
