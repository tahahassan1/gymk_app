import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropin_form_cubit.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropins_cubit.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';

import '../../support/fake_clock.dart';
import '../../support/gym_fixture.dart';

void main() {
  late GymFixture fixture;
  late FakeClock clock;
  setUp(() {
    fixture = GymFixture();
    clock = FakeClock(DateOnly(2026, 11, 10));
  });
  tearDown(() => fixture.close());
  test(
    'settings read failure is visible without unlocking an in-flight payment',
    () async {
      final form = DropinFormCubit(
        repository: fixture.repository,
        clock: clock,
      );
      await Future<void>.delayed(Duration.zero);
      fixture.delayLocal = true;
      fixture.remote = Completer<void>();
      final submitted = form.submit();
      fixture.settingsSource.addError(
        const AppFailure(FailureKind.unavailable),
      );
      await Future<void>.delayed(Duration.zero);
      expect(form.state.defaultsFailure, isNotNull);
      expect(form.state.submission.busy, isTrue);
      await form.submit();
      expect(fixture.writes, 1);
      fixture.applyLocal();
      await submitted;
      fixture.remote!.complete();
      await form.close();
    },
  );
  test(
    'historical browsing never backdates quick entry; blank name is optional',
    () async {
      final list = DropinsCubit(repository: fixture.repository, clock: clock);
      final form = DropinFormCubit(
        repository: fixture.repository,
        clock: clock,
      );
      list.dayChanged(DateOnly(2026, 10, 31));
      form.amountChanged('٢٥');
      await form.submit();
      await Future<void>.delayed(Duration.zero);
      expect(fixture.sessions.single.date, DateOnly(2026, 11, 10));
      expect(fixture.sessions.single.name, isNull);
      expect(list.state.day, DateOnly(2026, 10, 31));
      expect(list.state.rows, isEmpty);
      list.showToday();
      expect(list.state.rows.single.amount, 25);
      await form.close();
      await list.close();
    },
  );
  test('zero payments rejected; duplicate taps guarded; stable retry after rejection', () async {
    final form = DropinFormCubit(repository: fixture.repository, clock: clock);
    form.amountChanged('0');
    await form.submit();
    expect(form.state.submission.failure?.kind, FailureKind.validation);
    form.amountChanged('35');
    fixture.delayLocal = true;
    fixture.remote = Completer<void>();
    final id = form.id;
    final op = form.operationId;
    final first = form.submit();
    await form.submit();
    expect(fixture.writes, 1);
    fixture.remote!.completeError(const AppFailure(FailureKind.permission));
    await first;
    fixture.remote = null;
    fixture.delayLocal = false;
    await form.submit();
    expect(fixture.sessions.single.id, id);
    expect(form.operationId, op);
    form.startNext();
    expect(form.id, isNot(id));
    expect(form.state.amount, '20');
    await form.close();
  });
  test('midnight refresh preserves historical day and draft; stale date needs confirmation', () async {
    final list = DropinsCubit(repository: fixture.repository, clock: clock);
    final form = DropinFormCubit(repository: fixture.repository, clock: clock);
    list.dayChanged(DateOnly(2026, 10, 31));
    form.nameChanged('مسودة');
    clock.date = DateOnly(2026, 11, 11);
    list.refreshDate();
    expect(list.state.day, DateOnly(2026, 10, 31));
    expect(list.state.today, clock.date);
    await form.submit();
    expect(form.state.staleDate, isTrue);
    expect(fixture.writes, 0);
    expect(form.state.name, 'مسودة');
    await form.submit();
    expect(fixture.sessions.single.date, clock.date);
    list.showToday();
    clock.date = DateOnly(2026, 11, 12);
    list.refreshDate();
    expect(list.state.day, clock.date);
    await form.close();
    await list.close();
  });
  test('date edit moves days retaining ID; deletion stays pending after disappearance', () async {
    final record = Dropin(
      id: 'one',
      name: 'قبل',
      amount: 20,
      date: DateOnly(2026, 10, 31),
    );
    fixture.sessions = [record];
    fixture.publish();
    final list = DropinsCubit(repository: fixture.repository, clock: clock);
    final form = DropinFormCubit(
      repository: fixture.repository,
      clock: clock,
      original: record,
    );
    form.nameChanged('');
    form.amountChanged('50');
    form.dateChanged(DateOnly(2026, 11, 1));
    await form.submit();
    await Future<void>.delayed(Duration.zero);
    expect(fixture.sessions.single.id, record.id);
    list.dayChanged(DateOnly(2026, 11, 1));
    expect(list.state.rows.single.name, isNull);
    fixture.remote = Completer<void>();
    await list.delete(fixture.sessions.single);
    expect(list.state.rows, isEmpty);
    expect(fixture.repository.mutations.any((m) => m.pending), isTrue);
    fixture.remote!.completeError(const AppFailure(FailureKind.permission));
    await Future<void>.delayed(Duration.zero);
    fixture.sessions = [record];
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    list.dayChanged(record.date);
    expect(list.state.rows.single.amount, 20);
    expect(
      fixture.repository.mutations.any(
        (m) => m.failure?.kind == FailureKind.permission,
      ),
      isTrue,
    );
    await form.close();
    await list.close();
  });
  test('read errors retain rows and revoke completeness; edited drafts resist price changes', () async {
    fixture.sessions = [Dropin(id: 'one', amount: 20, date: clock.date)];
    fixture.publish();
    final list = DropinsCubit(repository: fixture.repository, clock: clock);
    final form = DropinFormCubit(repository: fixture.repository, clock: clock);
    form.amountChanged('27');
    await Future<void>.delayed(Duration.zero);
    fixture.dropinSource.addError(const AppFailure(FailureKind.unavailable));
    await Future<void>.delayed(Duration.zero);
    expect(list.state.rows, hasLength(1));
    expect(list.state.complete, isFalse);
    expect(list.state.failure, isNotNull);
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(list.state.failure, isNull);
    expect(form.state.amount, '27');
    await form.close();
    await list.close();
  });
}
