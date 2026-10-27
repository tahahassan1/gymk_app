import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/features/settings/business_logic/cubit/settings_cubit.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';
import 'package:gymk_app/features/subscriptions/business_logic/cubit/subscription_form_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropin_form_cubit.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/core/time/date_only.dart';

import '../../support/fake_clock.dart';
import '../../support/gym_fixture.dart';

void main() {
  late GymFixture fixture;
  late SettingsCubit cubit;
  setUp(() async {
    fixture = GymFixture();
    cubit = SettingsCubit(fixture.repository);
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() async {
    await cubit.close();
    await fixture.close();
  });
  test('required gym name, zero defaults and localized prices; no historical change', () async {
    cubit.nameChanged(' ');
    await cubit.submit();
    expect(cubit.state.submission.failure?.kind, FailureKind.validation);
    cubit.nameChanged('  جيم أحمد  ');
    cubit.subscriptionPriceChanged('٠');
    cubit.dropinPriceChanged('٢٥');
    await cubit.submit();
    expect(fixture.defaults.gymName, 'جيم أحمد');
    expect(fixture.defaults.subscriptionPrice, 0);
    expect(fixture.defaults.dropinPrice, 25);
    expect(fixture.history, isEmpty);
    expect(cubit.state.dirty, isFalse);
    cubit.subscriptionPriceChanged('-1');
    await cubit.submit();
    expect(cubit.state.submission.failure?.code, 'default-price');
  });
  test('remote updates preserve dirty draft and require reloading before stale save', () async {
    cubit.nameChanged('مسودة');
    fixture.defaults = GymSettings(
      gymName: 'اسم مختلف',
      subscriptionPrice: 300,
      dropinPrice: 40,
    );
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.name, 'مسودة');
    await cubit.submit();
    expect(cubit.state.submission.failure?.code, 'stale-settings');
    expect(fixture.writes, 0);
    cubit.reloadDraft();
    expect(cubit.state.name, 'اسم مختلف');
    expect(cubit.state.dirty, isFalse);
    fixture.defaults = GymSettings(
      gymName: 'تحديث بدون مسودة',
      subscriptionPrice: 500,
      dropinPrice: 60,
    );
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.name, 'تحديث بدون مسودة');
  });
  test(
    'double submit guarded; local pending save permits next offline edit',
    () async {
      cubit.nameChanged('أول');
      fixture.delayLocal = true;
      fixture.remote = Completer<void>();
      final submit = cubit.submit();
      await cubit.submit();
      expect(fixture.writes, 1);
      expect(cubit.hasKnownPendingChanges, isTrue);
      fixture.applyLocal();
      await submit;
      expect(cubit.state.submission.applied, isTrue);
      cubit.nameChanged('تعديل تاني أوفلاين');
      expect(cubit.state.name, 'تعديل تاني أوفلاين');
      expect(cubit.state.dirty, isTrue);
      fixture.remote!.complete();
    },
  );
  test('eventual rejection restores retryable desired draft with the same operation ID', () async {
    final previous = fixture.defaults;
    cubit.nameChanged('تغيير هيترفض');
    fixture.remote = Completer<void>();
    await cubit.submit();
    final id = cubit.operationId;
    expect(cubit.state.submission.applied, isTrue);
    fixture.remote!.completeError(const AppFailure(FailureKind.permission));
    await Future<void>.delayed(Duration.zero);
    fixture.defaults = previous;
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.name, 'تغيير هيترفض');
    expect(cubit.state.dirty, isTrue);
    expect(cubit.state.submission.failure?.kind, FailureKind.permission);
    fixture.remote = null;
    await cubit.submit();
    expect(cubit.operationId, id);
    expect(cubit.state.submission.applied, isTrue);
  });
  test(
    'settings affect new prefills and preserve already edited payment drafts',
    () async {
      fixture.memberRecords = [
        Member(id: 'one', name: 'أحمد', createdAt: DateTime(2026, 10, 26)),
      ];
      fixture.publish();
      final clock = FakeClock(DateOnly(2026, 11, 10));
      final policy = SubscriptionPolicy(clock: clock);
      final subscription = SubscriptionFormCubit(
        repository: fixture.repository,
        policy: policy,
        memberId: 'one',
      );
      subscription.amountChanged('123');
      final dropin = DropinFormCubit(
        repository: fixture.repository,
        clock: clock,
      );
      dropin.amountChanged('27');
      cubit.subscriptionPriceChanged('400');
      cubit.dropinPriceChanged('50');
      await cubit.submit();
      await Future<void>.delayed(Duration.zero);
      expect(subscription.state.amount, '123');
      expect(dropin.state.amount, '27');
      final nextSubscription = SubscriptionFormCubit(
        repository: fixture.repository,
        policy: policy,
        memberId: 'one',
      );
      final nextDropin = DropinFormCubit(
        repository: fixture.repository,
        clock: clock,
      );
      expect(nextSubscription.state.amount, '400');
      expect(nextDropin.state.amount, '50');
      await subscription.close();
      await dropin.close();
      await nextSubscription.close();
      await nextDropin.close();
    },
  );
  test('read failure keeps draft and revokes completeness; recovery clears failure', () async {
    cubit.nameChanged('مسودة محفوظة');
    fixture.settingsSource.addError(const AppFailure(FailureKind.unavailable));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.name, 'مسودة محفوظة');
    expect(cubit.state.complete, isFalse);
    expect(cubit.state.readFailure, isNotNull);
    cubit.dropinPriceChanged('0');
    expect(cubit.state.readFailure, isNotNull);
    fixture.publish();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.readFailure, isNull);
  });
}
