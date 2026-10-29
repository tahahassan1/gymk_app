import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/members/business_logic/cubit/member_form_cubit.dart';
import 'package:gymk_app/features/members/business_logic/policies/member_deletion_coordinator.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';
import 'package:gymk_app/features/subscriptions/business_logic/cubit/subscription_form_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropin_form_cubit.dart';
import 'package:gymk_app/features/statistics/business_logic/policies/monthly_cash_calculator.dart';

import '../test/support/fake_clock.dart';
import 'support/restart_session.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'seed downloaded data and offline mutations for real process restart',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('جيمك — حفظ أوفلاين قبل إعادة تشغيل العملية'),
          ),
        ),
      );
      await tester.runAsync(() async {
        final session = RestartSession();
        await session.open(seed: true);
        final repo = session.repository;
        await repo.ensureInitialSettings(
          GymSettings(
            gymName: 'جيم إعادة التشغيل',
            subscriptionPrice: 150,
            dropinPrice: 40,
          ),
        );
        final member = Member(
          id: 'restart-member',
          name: 'قبل التعديل',
          createdAt: DateTime.utc(2026, 10, 26),
        );
        final cascade = Member(
          id: 'cascade-member',
          name: 'عضو للحذف الكامل',
          createdAt: DateTime.utc(2026, 10, 26),
        );
        for (final m in [member, cascade]) {
          expect(
            await repo
                .saveMember(m, operationId: repo.newId())
                .remoteResult
                .timeout(const Duration(seconds: 20)),
            isNull,
          );
        }
        for (final id in ['base', 'cascade-one', 'cascade-two']) {
          final record = SubscriptionRecord(
            id: id,
            memberId: id == 'base' ? member.id : cascade.id,
            startDate: DateOnly(2026, 10, 26),
            endDate: DateOnly(2026, 11, 26),
            amount: 100,
            paidAt: DateOnly(2026, 10, 26),
          );
          expect(
            await repo
                .saveSubscription(record, operationId: repo.newId())
                .remoteResult
                .timeout(const Duration(seconds: 20)),
            isNull,
          );
        }
        final old = Dropin(
          id: 'move-day',
          amount: 20,
          date: DateOnly(2026, 10, 31),
        );
        final deleted = Dropin(
          id: 'delete-day',
          amount: 30,
          date: DateOnly(2026, 11, 10),
        );
        for (final d in [old, deleted]) {
          expect(
            await repo
                .saveDropin(d, operationId: repo.newId())
                .remoteResult
                .timeout(const Duration(seconds: 20)),
            isNull,
          );
        }
        await session.confirmed();
        if (const bool.fromEnvironment('GYMK_AIRPLANE_GATE')) {
          // ADB-forwarded host acknowledgement arrives only after Android's
          // airplane mode is enabled and Wi-Fi/mobile data are disabled.
          final gate = await HttpServer.bind(
            InternetAddress.loopbackIPv4,
            9877,
          );
          debugPrint('GYMK_RESTART_READY_FOR_AIRPLANE');
          try {
            final request = await gate.first.timeout(
              const Duration(seconds: 60),
            );
            request.response.write('ready');
            await request.response.close();
          } finally {
            await gate.close(force: true);
          }
        }
        await session.firestore.disableNetwork();
        final edit = MemberFormCubit(repo, original: member);
        edit.nameChanged('بعد التعديل أوفلاين');
        await edit.submit().timeout(const Duration(seconds: 15));
        await edit.close();
        final newMember = Member(
          id: 'created-offline',
          name: 'عضو جديد أوفلاين',
          createdAt: DateTime.utc(2026, 11, 10),
        );
        final handle = repo.saveMember(
          newMember,
          operationId: 'stable-offline-member',
        );
        expect(
          await handle.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(
          repo.saveMember(newMember, operationId: 'stable-offline-member'),
          same(handle),
        );
        final clock = FakeClock(DateOnly(2026, 11, 10));
        final renewal = SubscriptionFormCubit(
          repository: repo,
          policy: SubscriptionPolicy(clock: clock),
          memberId: member.id,
        );
        await renewal.submit().timeout(const Duration(seconds: 15));
        await renewal.close();
        final correction = DropinFormCubit(
          repository: repo,
          clock: clock,
          original: old,
        );
        correction.amountChanged('25');
        correction.dateChanged(clock.date);
        await correction.submit().timeout(const Duration(seconds: 15));
        await correction.close();
        expect(
          await repo
              .saveDropin(
                Dropin(id: 'created-dropin', amount: 40, date: clock.date),
                operationId: 'stable-offline-dropin',
              )
              .localResult
              .timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(
          await repo
              .deleteDropin(deleted, operationId: 'stable-offline-delete')
              .localResult
              .timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(
          await MemberDeletionCoordinator(repo)
              .delete(cascade.id, operationId: 'stable-offline-cascade')
              .localResult
              .timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(repo.currentMembers!.data.length, 2);
        expect(repo.currentSubscriptions!.data.length, 2);
        expect(repo.currentDropins!.data.length, 2);
        expect(
          MonthlyCashCalculator.calculate(
            clock.date,
            repo.currentSubscriptions!.data,
            repo.currentDropins!.data,
          ).total,
          BigInt.from(215),
        );
        expect(repo.mutations.any((m) => m.pending), isTrue);
        debugPrint('GYMK_RESTART_SEEDED uid=${repo.uid}');
        // The host force-stops this process. Deliberately leave the SDK offline;
        // only Firestore's own persistence carries these writes into the next app.
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
