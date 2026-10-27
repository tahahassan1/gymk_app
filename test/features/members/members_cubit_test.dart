import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_state.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';

import '../../support/fake_clock.dart';
import '../../support/fake_gym_repository.dart';

void main() {
  late FakeGymRepository repository;
  late FakeClock clock;
  late MembersCubit cubit;

  setUp(() {
    repository = FakeGymRepository();
    clock = FakeClock(DateOnly(2026, 11, 22));
    cubit = MembersCubit(
      repository: repository,
      policy: SubscriptionPolicy(clock: clock),
    );
  });
  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  Member member(String id, String name) =>
      Member(id: id, name: name, createdAt: DateTime.utc(2026, 10, 26));
  SubscriptionRecord paid(String id, String memberId) => SubscriptionRecord(
    id: id,
    memberId: memberId,
    startDate: DateOnly(2026, 10, 26),
    endDate: DateOnly(2026, 11, 26),
    amount: 125,
    paidAt: DateOnly(2026, 10, 26),
  );

  test('cache-only empty input is not authoritative; data remains visible on read error', () {
    repository.members.add(snapshot([member('one', 'أحمد')], complete: false));
    repository.subscriptions.add(
      snapshot(<SubscriptionRecord>[], complete: false),
    );
    expect(cubit.state.initialLoading, isFalse);
    expect(cubit.state.complete, isFalse);
    repository.members.addError(const AppFailure(FailureKind.unavailable));
    expect(cubit.state.rows.single.member.name, 'أحمد');
    expect(cubit.state.membersFailure?.kind, FailureKind.unavailable);
    cubit.searchChanged('أحم');
    expect(
      cubit.state.membersFailure,
      isNotNull,
      reason: 'Unrelated query emissions do not erase errors',
    );
    repository.members.add(snapshot([member('one', 'أحمد')]));
    expect(cubit.state.membersFailure, isNull);
    expect(cubit.state.query, 'أحم');
    expect(cubit.state.coverageComplete, isFalse);
  });

  test(
    'search/status filters and date rollover use unchanged repository records',
    () {
      repository.members.add(
        snapshot([member('one', 'أحمد محمد'), member('two', 'محمود')]),
      );
      repository.subscriptions.add(snapshot([paid('one', 'one')]));
      cubit.searchChanged('محمد');
      cubit.filterChanged(MemberFilter.active);
      expect(cubit.state.rows.single.member.id, 'one');
      clock.date = DateOnly(2026, 11, 23);
      cubit.refreshDate();
      expect(cubit.state.rows, isEmpty);
      cubit.filterChanged(MemberFilter.expiringSoon);
      expect(cubit.state.rows.single.member.id, 'one');
      clock.date = DateOnly(2026, 11, 26);
      cubit.refreshDate();
      cubit.filterChanged(MemberFilter.expired);
      expect(cubit.state.rows.single.member.id, 'one');
      expect(cubit.state.query, 'محمد');
      expect(repository.memberConsumers, 1);
      expect(repository.coverageConsumers, 1);
    },
  );

  test(
    'hundreds of members share one read of today per projection calculation',
    () {
      repository.members.add(
        snapshot(List.generate(500, (index) => member('$index', 'عضو $index'))),
      );
      clock.reads = 0;
      cubit.refreshDate();
      expect(cubit.state.rows, hasLength(500));
      expect(clock.reads, 1);
      expect(() => cubit.state.rows.clear(), throwsUnsupportedError);
    },
  );

  test('nullable failures explicitly clear and closing cancels both owned subscriptions', () async {
    repository.members.add(snapshot([member('one', 'أحمد')]));
    repository.members.addError(const AppFailure(FailureKind.permission));
    expect(cubit.state.copyWith(membersFailure: null).membersFailure, isNull);
    await cubit.retry();
    expect(repository.retries, 1);
    await cubit.close();
    expect(repository.members.hasListener, isFalse);
    expect(repository.subscriptions.hasListener, isFalse);
    repository.members.add(snapshot([member('two', 'محمود')]));
    expect(cubit.state.rows.single.member.id, 'one');
  });
}
