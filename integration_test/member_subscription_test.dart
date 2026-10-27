import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/core/data/mutation_registry.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/members/business_logic/cubit/member_form_cubit.dart';
import 'package:gymk_app/features/members/business_logic/policies/member_deletion_coordinator.dart';
import 'package:gymk_app/features/subscriptions/business_logic/cubit/subscription_form_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';

import '../test/support/fake_clock.dart';
import 'support/emulator_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native offline member renewal corrections and atomic cascade', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('جيمك — اختبار الأعضاء والاشتراكات')),
      ),
    );
    await tester.runAsync(() async {
      final fixture = EmulatorFixture();
      await fixture.start('gymk-members-integration');
      addTearDown(fixture.close);
      final repo = fixture.repository;
      final clock = FakeClock(DateOnly(2026, 11, 10));
      final policy = SubscriptionPolicy(clock: clock);
      final create = MemberFormCubit(repo);
      create.nameChanged('أحمد تجربة');
      create.phoneChanged('01001234567');
      await create.submit().timeout(const Duration(seconds: 20));
      final member = create.result!;
      await create.close();
      await fixture.confirmed();
      final original = SubscriptionRecord(
        id: repo.newId(),
        memberId: member.id,
        startDate: DateOnly(2026, 10, 26),
        endDate: DateOnly(2026, 11, 26),
        amount: 100,
        paidAt: DateOnly(2026, 10, 26),
      );
      expect(
        await repo
            .saveSubscription(original, operationId: repo.newId())
            .remoteResult
            .timeout(const Duration(seconds: 20)),
        isNull,
      );
      final dropin = Dropin(id: repo.newId(), amount: 20, date: clock.today());
      expect(
        await repo
            .saveDropin(dropin, operationId: repo.newId())
            .remoteResult
            .timeout(const Duration(seconds: 20)),
        isNull,
      );
      await fixture.confirmed();
      await fixture.firestore.disableNetwork();
      final edit = MemberFormCubit(repo, original: member);
      edit.nameChanged('أحمد بعد التعديل');
      await edit.submit().timeout(const Duration(seconds: 15));
      expect(edit.state.submission.applied, isTrue);
      await edit.close();
      final renewal = SubscriptionFormCubit(
        repository: repo,
        policy: policy,
        memberId: member.id,
      );
      renewal.amountChanged('١٥٠');
      expect(renewal.state.preview.period.end, DateOnly(2026, 12, 26));
      await renewal.submit().timeout(const Duration(seconds: 15));
      expect(renewal.state.submission.applied, isTrue);
      final renewalId = renewal.id;
      await renewal.close();
      expect(
        repo.mutations.where((m) => m.pending).length,
        greaterThanOrEqualTo(2),
      );
      await fixture.firestore.enableNetwork();
      await fixture.confirmed();
      final server = await fixture.firestore
          .collection('users')
          .doc(repo.uid)
          .collection('subscriptions')
          .get();
      expect(server.docs.where((d) => d.id == renewalId), hasLength(1));
      expect(
        server.docs.firstWhere((d) => d.id == renewalId).data()['paidAt'],
        '2026-11-10',
      );
      await fixture.firestore.disableNetwork();
      final saved = repo.currentSubscriptions!.data.firstWhere(
        (s) => s.id == renewalId,
      );
      final correction = SubscriptionFormCubit(
        repository: repo,
        policy: policy,
        memberId: member.id,
        original: saved,
      );
      correction.amountChanged('175');
      await correction.submit().timeout(const Duration(seconds: 15));
      await correction.close();
      final deletion = repo.deleteSubscription(
        original,
        operationId: repo.newId(),
      );
      expect(
        await deletion.localResult.timeout(const Duration(seconds: 15)),
        isNull,
      );
      await fixture.firestore.enableNetwork();
      await fixture.confirmed();
      // An invalid immutable payment-date correction is locally visible, then
      // rejected and rolled back after its initiating form has gone away.
      final valid = repo.currentSubscriptions!.data.single;
      await fixture.firestore.disableNetwork();
      final invalid = SubscriptionRecord(
        id: valid.id,
        memberId: valid.memberId,
        startDate: valid.startDate,
        endDate: valid.endDate,
        amount: 199,
        paidAt: DateOnly(2026, 12, 1),
      );
      final rejected = repo.saveSubscription(
        invalid,
        operationId: repo.newId(),
      );
      expect(
        await rejected.localResult.timeout(const Duration(seconds: 15)),
        isNull,
      );
      await fixture.firestore.enableNetwork();
      expect(
        (await rejected.remoteResult.timeout(const Duration(seconds: 20)))
            ?.kind,
        FailureKind.permission,
      );
      await fixture.confirmed();
      expect(repo.currentSubscriptions!.data.single.amount, 175);
      expect(
        repo.mutations.any((m) => m.stage == MutationStage.rejected),
        isTrue,
      );
      // Exercise the implemented 200-subscription boundary with real native SDK.
      final batch = fixture.firestore.batch();
      for (var i = 0; i < 199; i++) {
        batch.set(
          fixture.firestore
              .collection('users')
              .doc(repo.uid)
              .collection('subscriptions')
              .doc('boundary-$i'),
          {
            'memberId': member.id,
            'startDate': '2026-10-26',
            'endDate': '2026-11-26',
            'amount': 1,
            'paidAt': '2026-10-26',
          },
        );
      }
      await batch.commit();
      await fixture.confirmed();
      expect(repo.currentSubscriptions!.data.length, 200);
      await fixture.firestore.disableNetwork();
      final cascade = MemberDeletionCoordinator(repo)
          .delete(member.id, operationId: repo.newId());
      expect(
        await cascade.localResult.timeout(const Duration(seconds: 20)),
        isNull,
      );
      expect(repo.currentMembers!.data, isEmpty);
      expect(repo.currentSubscriptions!.data, isEmpty);
      expect(repo.currentDropins!.data.single.id, dropin.id);
      await fixture.firestore.enableNetwork();
      expect(
        await cascade.remoteResult.timeout(const Duration(seconds: 30)),
        isNull,
      );
      await fixture.confirmed();
      expect(
        (await fixture.firestore
                .collection('users')
                .doc(repo.uid)
                .collection('subscriptions')
                .get())
            .docs,
        isEmpty,
      );
      debugPrint(
        'Phase 5 native: local forms, one renewal, edit/delete rollback, 201-delete batch and independent drop-in passed.',
      );
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
