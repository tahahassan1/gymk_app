import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/members/business_logic/cubit/member_form_cubit.dart';
import 'package:gymk_app/features/members/business_logic/cubit/member_details_cubit.dart';
import 'package:gymk_app/features/members/business_logic/policies/member_deletion_coordinator.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/subscriptions/business_logic/cubit/subscription_form_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';

import '../../support/gym_fixture.dart';
import '../../support/fake_clock.dart';

void main() {
  late GymFixture fixture;
  late FakeClock clock;
  late SubscriptionPolicy policy;
  final member = Member(
    id: 'one',
    name: 'أحمد',
    createdAt: DateTime(2026, 10, 26),
  );
  SubscriptionRecord paid(String id, DateOnly start) => SubscriptionRecord(
    id: id,
    memberId: 'one',
    startDate: start,
    endDate: start.addCalendarMonth(),
    amount: 100,
    paidAt: DateOnly(2026, 10, 26),
  );
  setUp(() {
    fixture = GymFixture();
    fixture.memberRecords = [member];
    fixture.publish();
    clock = FakeClock(DateOnly(2026, 11, 10));
    policy = SubscriptionPolicy(clock: clock);
  });
  tearDown(() => fixture.close());
  test('uncertain payment retry after acknowledgement preserves the original recording date and ID', () async {
    final form = SubscriptionFormCubit(
      repository: fixture.repository,
      policy: policy,
      memberId: 'one',
    );
    fixture.delayLocal = true;
    fixture.remote = Completer<void>();
    final submitted = form.submit();
    fixture.historySource.addError(const AppFailure(FailureKind.unavailable));
    await submitted;
    expect(form.state.submission.failure?.code, 'local-confirmation');
    clock.date = DateOnly(2026, 11, 11);
    fixture.remote!.complete();
    fixture.applyLocal();
    await Future<void>.delayed(Duration.zero);
    await form.submit();
    expect(form.state.submission.applied, isTrue);
    expect(fixture.writes, 1);
    expect(fixture.history.single.id, form.id);
    expect(fixture.history.single.paidAt, DateOnly(2026, 11, 10));
    await form.close();
  });
  test('required trimmed name, optional string phone, duplicate submission and local completion', () async {
    final form = MemberFormCubit(fixture.repository);
    await form.submit();
    expect(form.state.submission.failure?.kind, FailureKind.validation);
    form.nameChanged('  محمد  ');
    form.phoneChanged('  01001234567  ');
    fixture.remote = Completer<void>();
    fixture.delayLocal = true;
    final first = form.submit();
    final second = form.submit();
    expect(form.state.submission.busy, isTrue);
    expect(fixture.writes, 1);
    fixture.applyLocal();
    await first;
    await second;
    expect(form.result!.name, 'محمد');
    expect(form.result!.phone, '01001234567');
    expect(form.state.submission.applied, isTrue);
    expect(fixture.repository.mutations.single.pending, isTrue);
    await form.close();
    fixture.remote!.complete();
  });
  test('retry keeps document ID and createdAt after rejected create', () async {
    final form = MemberFormCubit(
      fixture.repository,
      now: () => DateTime(2026, 10, 28),
    );
    form.nameChanged('علي');
    fixture.delayLocal = true;
    fixture.remote = Completer<void>();
    final first = form.submit();
    fixture.remote!.completeError(const AppFailure(FailureKind.permission));
    await first;
    final id = form.id;
    fixture.remote = null;
    fixture.delayLocal = false;
    await form.submit();
    expect(form.state.submission.failure, isNull);
    expect(form.result!.id, id);
    expect(form.result!.createdAt, DateTime(2026, 10, 28));
    expect(fixture.memberRecords.where((m) => m.id == id).length, 1);
    await form.close();
  });
  test('early renewal retains days and payment month; stale preview requires second save', () async {
    fixture.history = [paid('first', DateOnly(2026, 10, 26))];
    fixture.publish();
    final form = SubscriptionFormCubit(
      repository: fixture.repository,
      policy: policy,
      memberId: 'one',
    );
    expect(form.state.preview.period.start, DateOnly(2026, 11, 26));
    expect(form.state.preview.period.end, DateOnly(2026, 12, 26));
    fixture.history.add(paid('other', DateOnly(2026, 11, 26)));
    fixture.publish();
    await form.submit();
    expect(form.state.stale, isTrue);
    expect(fixture.writes, 0);
    await form.submit();
    expect(fixture.history.last.startDate, DateOnly(2026, 12, 26));
    expect(fixture.history.last.paidAt, DateOnly(2026, 11, 10));
    await form.close();
  });
  test('localized amount and future automatic amount-only edit preserve immutable references', () async {
    final old = paid('future', DateOnly(2026, 12, 26));
    fixture.history = [old];
    fixture.publish();
    final form = SubscriptionFormCubit(
      repository: fixture.repository,
      policy: policy,
      memberId: 'one',
      original: old,
    );
    form.amountChanged('١٥٠');
    await form.submit();
    final saved = fixture.history.single;
    expect(saved.amount, 150);
    expect(saved.startDate, old.startDate);
    expect(saved.paidAt, old.paidAt);
    expect(saved.memberId, old.memberId);
    await form.close();
  });
  test('manual future rejected, date rollover refreshes preview, stale edit is blocked', () async {
    final form = SubscriptionFormCubit(
      repository: fixture.repository,
      policy: policy,
      memberId: 'one',
    );
    form.startChanged(DateOnly(2026, 11, 11));
    expect(form.state.submission.failure?.kind, FailureKind.validation);
    clock.date = DateOnly(2026, 11, 11);
    await form.submit();
    expect(form.state.stale, isTrue);
    expect(fixture.writes, 0);
    await form.close();
    final old = paid('old', DateOnly(2026, 10, 26));
    fixture.history = [old];
    fixture.publish();
    final edit = SubscriptionFormCubit(
      repository: fixture.repository,
      policy: policy,
      memberId: 'one',
      original: old,
    );
    fixture.history = [old.edit(amount: 200, startDate: old.startDate)];
    fixture.publish();
    await edit.submit();
    expect(edit.state.submission.failure?.kind, FailureKind.conflict);
    await edit.close();
  });
  test('details respond to deleting middle and only periods, missing member and disposal', () async {
    fixture.history = [
      paid('first', DateOnly(2026, 10, 26)),
      paid('middle', DateOnly(2026, 11, 26)),
      paid('last', DateOnly(2026, 12, 26)),
    ];
    fixture.publish();
    final details = MemberDetailsCubit(
      repository: fixture.repository,
      policy: policy,
      memberId: 'one',
    );
    expect(details.state.coverage!.currentExpiry, DateOnly(2027, 1, 26));
    await details.deleteSubscription(fixture.history[1]);
    await Future<void>.delayed(Duration.zero);
    expect(details.state.coverage!.currentExpiry, DateOnly(2026, 11, 26));
    expect(fixture.history.last.startDate, DateOnly(2026, 12, 26));
    await details.deleteSubscription(fixture.history.first);
    await Future<void>.delayed(Duration.zero);
    expect(details.state.coverage!.status, MembershipStatus.expired);
    await details.deleteSubscription(fixture.history.single);
    await Future<void>.delayed(Duration.zero);
    expect(details.state.coverage!.status, MembershipStatus.noSubscription);
    await details.deleteMember();
    await Future<void>.delayed(Duration.zero);
    expect(details.state.member, isNull);
    await details.close();
  });
  test(
    'cascade blocks incomplete/oversized/stale history and serializes renewal',
    () async {
      final coordinator = MemberDeletionCoordinator(fixture.repository);
      fixture.complete = false;
      fixture.publish();
      expect(
        () => coordinator.delete('one', operationId: 'delete'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.kind,
            'kind',
            FailureKind.incompleteData,
          ),
        ),
      );
      fixture.complete = true;
      fixture.history = List.generate(
        201,
        (i) => paid('s$i', DateOnly(2026, 10, 26)),
      );
      fixture.publish();
      expect(
        () => coordinator.delete('one', operationId: 'delete'),
        throwsA(
          isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.tooLarge),
        ),
      );
      fixture.history = [paid('single', DateOnly(2026, 10, 26))];
      fixture.publish();
      expect(
        () => fixture.repository.deleteMemberCascade(
          'one',
          [],
          operationId: 'bad',
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.conflict),
        ),
      );
      fixture.delayLocal = true;
      fixture.remote = Completer<void>();
      final handle = fixture.repository.saveSubscription(
        paid('new', DateOnly(2026, 11, 26)),
        operationId: 'renew',
      );
      expect(
        () => coordinator.delete('one', operationId: 'delete'),
        throwsA(
          isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.conflict),
        ),
      );
      fixture.applyLocal();
      await handle.localResult;
      fixture.remote!.complete();
      await handle.remoteResult;
      fixture.delayLocal = false;
      fixture.remote = null;
      final deletion = coordinator.delete('one', operationId: 'delete');
      await deletion.localResult;
      expect(fixture.history, isEmpty);
      expect(fixture.memberRecords, isEmpty);
    },
  );
}
