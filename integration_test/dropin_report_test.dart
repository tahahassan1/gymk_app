import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gymk_app/app/app_runtime.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/auth/data/providers/firebase_auth_provider.dart';
import 'package:gymk_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/business_logic/policies/member_deletion_coordinator.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropin_form_cubit.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/statistics/business_logic/cubit/statistics_cubit.dart';

import '../test/support/fake_clock.dart';
import 'support/emulator_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native drop-in CRUD live cash reports pending rollback and resize',
    (tester) async {
      final fixture = EmulatorFixture();
      final clock = FakeClock(DateOnly(2026, 11, 10));
      late AuthCubit auth;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('جيمك — اختبار الحصص والتقارير')),
        ),
      );
      await tester.runAsync(() async {
        await fixture.start('gymk-dropin-report');
        final repo = fixture.repository;
        final member = Member(
          id: 'report-member',
          name: 'عضو التقرير',
          createdAt: DateTime(2026, 10, 26),
        );
        expect(
          await repo
              .saveMember(member, operationId: repo.newId())
              .remoteResult
              .timeout(const Duration(seconds: 20)),
          isNull,
        );
        final subscription = SubscriptionRecord(
          id: 'report-subscription',
          memberId: member.id,
          startDate: DateOnly(2026, 11, 26),
          endDate: DateOnly(2026, 12, 26),
          amount: 100,
          paidAt: clock.date,
        );
        expect(
          await repo
              .saveSubscription(subscription, operationId: repo.newId())
              .remoteResult
              .timeout(const Duration(seconds: 20)),
          isNull,
        );
        final report = StatisticsCubit(repository: repo, clock: clock);
        Future<void> total(int value) async {
          if (report.state.cash.total == BigInt.from(value)) return;
          await report.stream
              .firstWhere((s) => s.cash.total == BigInt.from(value))
              .timeout(const Duration(seconds: 20));
        }

        await fixture.confirmed();
        await total(100);
        final old = Dropin(
          id: 'old-day',
          amount: 20,
          date: DateOnly(2026, 10, 31),
        );
        expect(
          await repo
              .saveDropin(old, operationId: repo.newId())
              .remoteResult
              .timeout(const Duration(seconds: 20)),
          isNull,
        );
        await fixture.confirmed();
        report.monthChanged(DateOnly(2026, 10, 1));
        await total(20);
        report.monthChanged(DateOnly(2026, 11, 1));
        await total(100);
        await fixture.firestore.disableNetwork();
        final quick = DropinFormCubit(repository: repo, clock: clock);
        quick.amountChanged('25');
        await quick.submit().timeout(const Duration(seconds: 15));
        expect(quick.state.submission.applied, isTrue);
        await quick.close();
        await total(125);
        expect(report.state.pending, isTrue);
        final edit = DropinFormCubit(
          repository: repo,
          clock: clock,
          original: old,
        );
        edit.amountChanged('50');
        edit.dateChanged(clock.date);
        await edit.submit().timeout(const Duration(seconds: 15));
        await edit.close();
        await total(175);
        report.monthChanged(DateOnly(2026, 10, 1));
        await total(0);
        report.monthChanged(DateOnly(2026, 11, 1));
        await total(175);
        final added = repo.currentDropins!.data.firstWhere(
          (d) => d.id != old.id,
        );
        final deletion = repo.deleteDropin(added, operationId: repo.newId());
        expect(
          await deletion.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        await total(150);
        await fixture.firestore.enableNetwork();
        await fixture.confirmed();
        // Move an immutable payment date offline: local totals move, then rollback
        // restores the same selected month after server rules reject the change.
        await fixture.firestore.disableNetwork();
        final invalid = SubscriptionRecord(
          id: subscription.id,
          memberId: member.id,
          startDate: subscription.startDate,
          endDate: subscription.endDate,
          amount: 999,
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
        await total(50);
        await fixture.firestore.enableNetwork();
        expect(
          (await rejected.remoteResult.timeout(const Duration(seconds: 20)))
              ?.kind,
          FailureKind.permission,
        );
        await total(150);
        expect(report.state.month, DateOnly(2026, 11, 1));
        final corrected = subscription.edit(
          amount: 150,
          startDate: subscription.startDate,
        );
        expect(
          await repo
              .saveSubscription(corrected, operationId: repo.newId())
              .remoteResult
              .timeout(const Duration(seconds: 20)),
          isNull,
        );
        await total(200);
        await fixture.confirmed();
        await fixture.firestore.disableNetwork();
        final cascade = MemberDeletionCoordinator(repo)
            .delete(member.id, operationId: repo.newId());
        expect(
          await cascade.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        await total(50);
        await fixture.firestore.enableNetwork();
        expect(
          await cascade.remoteResult.timeout(const Duration(seconds: 20)),
          isNull,
        );
        await fixture.confirmed();
        expect(repo.currentDropins!.data.single.amount, 50);
        await report.close();
        auth = AuthCubit(
          authRepository: FirebaseAuthRepository(
            FirebaseAuthProvider(
              firebase: fixture.auth,
              google: GoogleSignIn.instance,
            ),
          ),
          createGymRepository: (_) => repo,
          initialSettings: repo.currentSettings!.data!,
        );
        await auth.stream
            .firstWhere((s) => s.ready)
            .timeout(const Duration(seconds: 20));
      });
      await tester.pumpWidget(
        AppRuntime(
          auth: auth,
          clock: clock,
          createMembers: (repo) => MembersCubit(
            repository: repo,
            policy: SubscriptionPolicy(clock: clock),
          ),
          createFeedback: (repo) => MutationFeedbackCubit(repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('الحصص'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextFormField, 'الاسم (اختياري)'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
        'حصة الواجهة',
      );
      final controller = tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
          )
          .controller;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 840);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
            )
            .controller,
        same(controller),
      );
      await tester.runAsync(fixture.firestore.disableNetwork);
      await tester.ensureVisible(find.text('سجّل حصة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سجّل حصة'));
      await tester.runAsync(
        () => fixture.repository
            .watchDropins()
            .firstWhere((s) => s.data.any((d) => d.name == 'حصة الواجهة'))
            .timeout(const Duration(seconds: 15)),
      );
      await tester.pumpAndSettle();
      expect(
        fixture.repository.currentDropins!.data.where(
          (d) => d.name == 'حصة الواجهة',
        ),
        hasLength(1),
      );
      await tester.tap(find.text('الإحصائيات'));
      await tester.pumpAndSettle();
      expect(find.text('إجمالي المتحصلات'), findsOneWidget);
      tester.view.physicalSize = const Size(390, 840);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        await fixture.firestore.enableNetwork();
        await fixture.confirmed();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      await tester.runAsync(fixture.close);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
